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
