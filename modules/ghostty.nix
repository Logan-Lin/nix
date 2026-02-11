{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.ghostty-custom;
in

{
  options.programs.ghostty-custom = {
    enable = mkEnableOption "Ghostty terminal emulator";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = "pkgs.ghostty";
      description = "Ghostty package to use. Set to null on Darwin to use Homebrew-installed Ghostty, or pkgs.ghostty on NixOS.";
    };

    fontSize = mkOption {
      type = types.int;
      default = 14;
      description = "Font size for the terminal";
    };

    windowMode = mkOption {
      type = types.enum [ "windowed" "maximized" "fullscreen" ];
      default = "windowed";
      description = "Window mode: 'windowed' for fixed size, 'maximized' for maximized window, or 'fullscreen' for full screen";
    };

    windowWidth = mkOption {
      type = types.int;
      default = 160;
      description = "Window width in columns (only used in windowed mode)";
    };

    windowHeight = mkOption {
      type = types.int;
      default = 40;
      description = "Window height in rows (only used in windowed mode)";
    };
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = cfg.package;

      settings = mkMerge [
        {
          font-family = [
            "JetBrainsMono Nerd Font Mono"
            "Noto Sans CJK SC"
            "Noto Sans CJK TC"
            "Noto Sans CJK JP"
            "Source Han Sans"
          ];
          font-family-bold = "JetBrainsMono NFM Bold";
          font-family-italic = "JetBrainsMono NFM Italic";
          font-family-bold-italic = "JetBrainsMono NFM Bold Italic";
          font-size = cfg.fontSize;

          background = "#14191f";
          cursor-style-blink = false;
          window-theme = "dark";
          window-padding-balance = true;
          shell-integration = "detect";
          shell-integration-features = "cursor,sudo,title";
          term = "xterm-256color";
          mouse-hide-while-typing = true;
          mouse-shift-capture = false;
          adjust-cell-height = "10%";
          minimum-contrast = 1.0;
          copy-on-select = false;
          clipboard-read = "allow";
          clipboard-write = "allow";
          scrollback-limit = 10000;
          desktop-notifications = false;
          confirm-close-surface = false;
          macos-titlebar-style = "hidden";
          macos-option-as-alt = "left";
        }

        (mkIf (cfg.windowMode == "windowed") {
          window-width = cfg.windowWidth;
          window-height = cfg.windowHeight;
        })

        (mkIf (cfg.windowMode == "maximized") {
          maximize = true;
        })

        (mkIf (cfg.windowMode == "fullscreen") {
          fullscreen = true;
        })
      ];
    };
  };
}
