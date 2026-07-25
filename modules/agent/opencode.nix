# Home Manager module that configures the OpenCode CLI.
# It sets program options and permissions, defines the global context and custom commands, and sends ntfy notifications when a session finishes or needs attention.
# A host opts in by importing this module.

{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Pull the OpenCode package from a separate newer nixpkgs input to get releases ahead of the pinned channel.
  bleed = import inputs.nixpkgs-bleed {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # OpenCode reports waiting states through events, so the plugin adapts those events to the shared notification scripts.
  inherit
    (import ./hook.nix {
      inherit pkgs;
      agent = "opencode";
      attentionEvent = "Notification";
    })
    notifyStart
    notifyStop
    ;

  notifyPlugin = pkgs.writeText "opencode-notify.js" ''
    const runHook = (command, sessionID, hookEventName, directory) => {
      const process = Bun.spawn([command], {
        stdin: "pipe",
        stdout: "ignore",
        stderr: "ignore",
      })
      process.stdin.write(JSON.stringify({
        session_id: sessionID,
        cwd: directory,
        hook_event_name: hookEventName,
      }))
      process.stdin.end()
    }

    export const NotificationPlugin = async ({ directory }) => ({
      "chat.message": async ({ sessionID }) => {
        runHook("${notifyStart}", sessionID, "UserPromptSubmit", directory)
      },
      event: async ({ event }) => {
        if (event.type === "session.idle") {
          runHook("${notifyStop}", event.properties.sessionID, "Stop", directory)
        }
        if (
          event.type === "permission.asked" ||
          event.type === "question.asked" ||
          (event.type === "session.error" && event.properties.sessionID)
        ) {
          runHook("${notifyStop}", event.properties.sessionID, "Notification", directory)
        }
      },
    })
  '';
in
{
  config = {
    programs.opencode = {
      enable = true;
      package = bleed.opencode;

      settings = {
        autoupdate = false;
        share = "disabled";
        compaction = {
          auto = true;
          prune = true;
        };
        plugin = [ notifyPlugin ];
      };

      tui = {
        theme = "system";
        scroll_acceleration.enabled = false;
        keybinds = {
          editor_open = "ctrl+g";
          messages_first = "home";
        };
      };

      context = import ./context.nix { memoryFile = "AGENTS.md"; };

      commands = import ./commands.nix;
    };
  };
}
