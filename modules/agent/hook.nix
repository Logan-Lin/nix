# Shared ntfy notification scripts for the agent CLIs.
# notifyStart records a start time for each session when a prompt is submitted.
# notifyStop pushes to the ntfy topic when a run finishes or waits for input, and only when the run lasted at least notifyThresholdSeconds, so quick turns stay silent.
{
  pkgs,
  # agent names the notifier for the ntfy title and the state directory.
  agent,
  # attentionEvent is the hook event that means the agent waits for input, reported as "Notified" instead of "Stopped".
  attentionEvent,
}:

let
  ntfyUrl = "ntfy.sh/yanlincs-homelab";
  notifyThresholdSeconds = 15;
  notifyDir = ''"''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/${agent}-notify"'';
in
{
  notifyStart = pkgs.writeShellScript "${agent}-notify-start" ''
    input=$(cat)
    sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // "default"')
    dir=${notifyDir}
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    ${pkgs.coreutils}/bin/date +%s > "$dir/$sid.start"
    exit 0
  '';

  notifyStop = pkgs.writeShellScript "${agent}-notify-stop" ''
    input=$(cat)
    dir=${notifyDir}
    sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // "default"')
    startfile="$dir/$sid.start"
    [ -f "$startfile" ] || exit 0
    start=$(${pkgs.coreutils}/bin/cat "$startfile" 2>/dev/null || echo 0)
    now=$(${pkgs.coreutils}/bin/date +%s)
    elapsed=$(( now - start ))
    # Keep the start marker when the run was too quick to notify, so a later event in the same turn can still reach the threshold instead of being silenced by an early event that consumed the marker.
    [ "$elapsed" -ge ${toString notifyThresholdSeconds} ] || exit 0
    ${pkgs.coreutils}/bin/rm -f "$startfile"

    cwd=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.cwd // ""')
    event=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.hook_event_name // ""')
    host=$(${pkgs.coreutils}/bin/uname -n | ${pkgs.coreutils}/bin/cut -d. -f1)

    # Name the action after the hook that fired, "Notified" for a ${attentionEvent} and "Stopped" otherwise.
    if [ "$event" = "${attentionEvent}" ]; then
      verb="Notified"
    else
      verb="Stopped"
    fi

    # Report the tmux session and window when the run is inside tmux, and fall back to the working directory otherwise.
    # A screen emoji marks a tmux session and a folder emoji marks a working directory.
    if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] && where=$(${pkgs.tmux}/bin/tmux display-message -p -t "$TMUX_PANE" '#S/#W' 2>/dev/null) && [ -n "$where" ]; then
      body="$verb 🖥️ $where"
    else
      body="$verb 📁 $cwd"
    fi

    ${pkgs.curl}/bin/curl -s \
      -H "Title: ${agent}@$host" \
      -d "$body" \
      "https://${ntfyUrl}" >/dev/null 2>&1 || true
    exit 0
  '';
}
