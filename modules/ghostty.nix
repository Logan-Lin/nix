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
    # Note: Ghostty is currently marked as broken in nixpkgs
    # To use it, you'll need to either:
    # 1. Set NIXPKGS_ALLOW_BROKEN=1 when running hms
    # 2. Add nixpkgs.config.allowBroken = true to your configuration
    # 3. Install Ghostty manually from https://ghostty.org
    
    programs.ghostty = {
      enable = true;
      package = cfg.package;
      
      settings = mkMerge [
        {
          # Font settings with CJK fallback
          font-family = [
            "JetBrainsMono Nerd Font Mono"  # Primary font for Latin + symbols
            "Noto Sans CJK SC"              # Simplified Chinese fallback
            "Noto Sans CJK TC"              # Traditional Chinese fallback
            "Source Han Sans"               # Alternative CJK fallback
          ];
          font-size = cfg.fontSize;
          
          # Gruvbox Dark Theme
          background = "#14191f";
          cursor-style-blink = false;

          # Window config
          window-theme = "dark";
          window-padding-balance = true;
          
          # Shell integration
          shell-integration = "detect";
          shell-integration-features = "cursor,sudo,title";
          
          # Mouse settings
          mouse-hide-while-typing = true;
          mouse-shift-capture = false;
          
          # Performance and appearance
          adjust-cell-height = "10%";
          minimum-contrast = 1.0;
          
          # Copy/paste
          copy-on-select = false;
          
          # Scrollback
          scrollback-limit = 10000;
          
          # Bell
          desktop-notifications = false;
          
          # Quit behavior
          confirm-close-surface = false;
        }
        
        # Conditional window settings based on mode
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
