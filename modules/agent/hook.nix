# Shared ntfy notification script for the agent CLIs.
{
  pkgs,
  # agent names the notifier in the ntfy title.
  agent,
  # attentionEvent is an optional hook event that means the agent waits for input, reported as "Notified" instead of "Stopped".
  attentionEvent ? null,
}:

let
  ntfyUrl = "ntfy.sh/yanlincs-homelab";
in
{
  notifyStop = pkgs.writeShellScript "${agent}-notify-stop" ''
    input=$(cat)
    cwd=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.cwd // ""')
    host=$(${pkgs.coreutils}/bin/uname -n | ${pkgs.coreutils}/bin/cut -d. -f1)

    verb="Stopped"
    ${pkgs.lib.optionalString (attentionEvent != null) ''
      event=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.hook_event_name // ""')
      # Report the ${attentionEvent} event as "Notified" because the agent waits for input.
      if [ "$event" = "${attentionEvent}" ]; then
        verb="Notified"
      fi
    ''}

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
