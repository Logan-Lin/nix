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
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = cfg.package;

      settings = {
        font-family = [
          "JetBrainsMono Nerd Font Mono"
          "Noto Sans CJK SC"
          "Noto Sans CJK TC"
          "Noto Sans CJK JP"
        ];
        font-family-bold = "JetBrainsMono NFM Bold";
        font-family-italic = "JetBrainsMono NFM Italic";
        font-family-bold-italic = "JetBrainsMono NFM Bold Italic";
        font-size = cfg.fontSize;

        theme = "Gruvbox Dark Hard";
        cursor-style-blink = false;
        window-theme = "dark";
        window-padding-balance = true;
        window-width = 160;
        window-height = 40;
        shell-integration = "detect";
        shell-integration-features = "no-cursor";
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
        mouse-reporting = false;
      };
    };
  };
}
