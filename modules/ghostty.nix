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
          # Font settings with CJK fallback
          font-family = [
            "JetBrainsMono Nerd Font Mono"  # Primary font for Latin + symbols
            "Noto Sans CJK SC"              # Simplified Chinese fallback
            "Noto Sans CJK TC"              # Traditional Chinese fallback
            "Source Han Sans"               # Alternative CJK fallback
          ];
          font-family-bold = "JetBrainsMono NFM Bold";
          font-family-italic = "JetBrainsMono NFM Italic";
          font-family-bold-italic = "JetBrainsMono NFM Bold Italic";
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

          # Terminal type - use widely-supported xterm-256color for SSH compatibility
          term = "xterm-256color";

          # Mouse settings
          mouse-hide-while-typing = true;
          mouse-shift-capture = false;
          
          # Performance and appearance
          adjust-cell-height = "10%";
          minimum-contrast = 1.0;
          
          # Copy/paste
          copy-on-select = false;

          # OSC-52 clipboard integration (works with Neovim and tmux)
          clipboard-read = "allow";   # Allow programs to read clipboard without prompting
          clipboard-write = "allow";  # Allow programs to write to clipboard without prompting
          
          # Scrollback
          scrollback-limit = 10000;
          
          # Bell
          desktop-notifications = false;
          
          # Quit behavior
          confirm-close-surface = false;

          # Platform-specific: Hide title bar to save space
          macos-titlebar-style = "hidden";  # macOS
          gtk-titlebar = false;              # GNOME/Linux
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
