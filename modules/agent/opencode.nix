# Home Manager module that configures the OpenCode CLI.
# It sets program options and permissions, defines the global context and custom commands, and sends ntfy notifications when a root session finishes or reports an error.
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

  # The plugin maps opencode session events to the shared notification scripts.
  # It notifies when a root session goes idle or reports an error, and reuses "Notification" for an error so the shared script labels it as needing attention.
  # It ignores permission and question events on purpose, because opencode's auto mode auto-approves a permission but still emits the event, so notifying on it would fire for a prompt that never blocks the user.
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
      const proc = Bun.spawn([command], {
        stdin: "pipe",
        stdout: "ignore",
        stderr: "ignore",
      })
      proc.stdin.write(JSON.stringify({
        session_id: sessionID,
        cwd: directory,
        hook_event_name: hookEventName,
      }))
      proc.stdin.end()
    }

    export const NotificationPlugin = async ({ directory, client }) => {
      // A sub-agent runs in a child session, so only a root session with no parent marks a turn the user is waiting on.
      const isRootSession = async (sessionID) => {
        try {
          const { data } = await client.session.get({ path: { id: sessionID } })
          return !data?.parentID
        } catch {
          return true
        }
      }

      return {
        "chat.message": async ({ sessionID }, { parts }) => {
          // Skip a fully synthetic message, which opencode injects to continue a turn rather than to start a new one, so the start time still measures the whole turn.
          if (parts?.length && parts.every((part) => part.synthetic === true)) return
          if (!(await isRootSession(sessionID))) return
          runHook("${notifyStart}", sessionID, "UserPromptSubmit", directory)
        },
        // Only a root session records a start time, so a child session's idle or error finds no timer and stays silent.
        event: async ({ event }) => {
          if (event.type === "session.idle") {
            runHook("${notifyStop}", event.properties.sessionID, "Stop", directory)
          }
          if (event.type === "session.error" && event.properties.sessionID) {
            runHook("${notifyStop}", event.properties.sessionID, "Notification", directory)
          }
        },
      }
    }
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
