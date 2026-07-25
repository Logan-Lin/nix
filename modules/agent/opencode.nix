# Home Manager module that configures the OpenCode CLI.
# It sets program options and permissions, defines the global context and custom commands, and sends an ntfy notification when the main session finishes.
# A host opts in by importing this module.

{
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

  # The plugin notifies when the main opencode session goes idle.
  # It ignores child sessions and other events because they do not mean the main session has finished.
  inherit
    (import ./hook.nix {
      inherit pkgs;
      agent = "opencode";
    })
    notifyStop
    ;

  notifyPlugin = pkgs.writeText "opencode-notify.js" ''
    export const StopPlugin = async ({ directory, client }) => {
      return {
        event: async ({ event }) => {
          if (event.type !== "session.idle") return
          const { data: session } = await client.session.get({ path: { id: event.properties.sessionID } })
          if (!session || session.parentID) return

          const proc = Bun.spawn(["${notifyStop}"], {
            stdin: "pipe",
            stdout: "ignore",
            stderr: "ignore",
          })
          proc.stdin.write(JSON.stringify({ cwd: directory }))
          proc.stdin.end()
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
