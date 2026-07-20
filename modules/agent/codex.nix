# Home-manager module that configures the OpenAI Codex CLI.
# It sets program options and permission rules, defines the global context, and wires notification hooks that push to an ntfy topic when a session finishes or needs attention.
# A host opts in by importing this module.

{ config, lib, pkgs, inputs, ... }:

let
  # Pull the codex package from a separate newer nixpkgs input to get releases ahead of the pinned channel.
  bleed = import inputs.nixpkgs-bleed {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  ntfyUrl = "ntfy.sh/yanlincs-homelab";
  notifyThresholdSeconds = 15;
  notifyDir = ''"''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/codex-notify"'';

  # notifyStart records a start time for each session when a prompt is submitted.
  # notifyStop pushes to the ntfy topic when a run finishes or waits for approval, and only when the run lasted at least notifyThresholdSeconds, so quick turns stay silent.
  notifyStart = pkgs.writeShellScript "codex-notify-start" ''
    input=$(cat)
    sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // "default"')
    dir=${notifyDir}
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    ${pkgs.coreutils}/bin/date +%s > "$dir/$sid.start"
    exit 0
  '';

  notifyStop = pkgs.writeShellScript "codex-notify-stop" ''
    input=$(cat)
    dir=${notifyDir}
    sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // "default"')
    startfile="$dir/$sid.start"
    [ -f "$startfile" ] || exit 0
    start=$(${pkgs.coreutils}/bin/cat "$startfile" 2>/dev/null || echo 0)
    ${pkgs.coreutils}/bin/rm -f "$startfile"
    now=$(${pkgs.coreutils}/bin/date +%s)
    elapsed=$(( now - start ))
    [ "$elapsed" -ge ${toString notifyThresholdSeconds} ] || exit 0

    cwd=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.cwd // ""')
    event=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.hook_event_name // ""')
    host=$(${pkgs.coreutils}/bin/uname -n | ${pkgs.coreutils}/bin/cut -d. -f1)

    # Name the action after the hook that fired, "Notified" for a PermissionRequest and "Stopped" otherwise.
    if [ "$event" = "PermissionRequest" ]; then
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
      -H "Title: codex@$host" \
      -d "$body" \
      "https://${ntfyUrl}" >/dev/null 2>&1 || true
    exit 0
  '';

  # Codex settings for ~/.codex/config.toml. features.hooks must be true or Codex ignores hooks.json.
  codexSettings = {
    model_reasoning_effort = "high";
    approval_policy = "on-request";
    sandbox_mode = "workspace-write";
    sandbox_workspace_write = {
      network_access = true;
      writable_roots = [ "${config.home.homeDirectory}/Documents" ];
    };
    web_search = "live";
    tools.view_image = true;
    features.hooks = true;
    tui = {
      animations = false;
      show_tooltips = false;
      theme = "ansi";
    };
  };
  codexConfig = (pkgs.formats.toml { }).generate "codex-config.toml" codexSettings;
in
{
  config = {
    programs.codex = {
      enable = true;
      package = bleed.codex;

      context = import ./context.nix;

      # UserPromptSubmit marks the turn start, Stop marks the turn end, and PermissionRequest fires when Codex pauses to ask for approval.
      hooks = {
        UserPromptSubmit = [
          { hooks = [ { type = "command"; command = "${notifyStart}"; timeout = 5; } ]; }
        ];
        Stop = [
          { hooks = [ { type = "command"; command = "${notifyStop}"; timeout = 15; } ]; }
        ];
        PermissionRequest = [
          { matcher = ""; hooks = [ { type = "command"; command = "${notifyStop}"; timeout = 15; } ]; }
        ];
      };

      # Command permissions as execpolicy rules in ~/.codex/rules/baseline.rules, paired with approval_policy.
      rules = {
        baseline = ''
          prefix_rule(
            pattern = ["git", ["status", "log", "diff", "show"]],
            decision = "allow",
            justification = "Inspecting git state is safe",
          )
          prefix_rule(
            pattern = [["ls", "cat", "head", "tail", "find", "grep", "wc", "file", "which", "pwd"]],
            decision = "allow",
            justification = "These commands only inspect the system and are safe",
          )
          prefix_rule(
            pattern = [["su", "dd", "mkfs", "fdisk"]],
            decision = "forbidden",
            justification = "Privilege escalation and raw disk tools are not permitted",
          )
        '';
      };
    };

    # Codex records per-directory trust into config.toml at runtime and has no global trust setting, so it needs a writable file rather than a read-only store symlink.
    # The copy is reinstalled on each switch, keeping nix authoritative for settings while Codex owns the trust entries it writes between switches.
    home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$HOME/.codex/config.toml"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm0644 ${codexConfig} "$HOME/.codex/config.toml"
    '';

  };
}
