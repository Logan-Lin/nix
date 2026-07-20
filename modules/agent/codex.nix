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

  # Codex fires a PermissionRequest when it pauses to ask for approval, so treat that event as needing attention.
  inherit (import ./hook.nix { inherit pkgs; agent = "codex"; attentionEvent = "PermissionRequest"; }) notifyStart notifyStop;

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

      context = import ./context.nix { memoryFile = "AGENTS.md"; };

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
