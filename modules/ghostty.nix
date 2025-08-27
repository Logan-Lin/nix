{ pkgs, ... }:

{
  # Note: Ghostty is currently marked as broken in nixpkgs
  # To use it, you'll need to either:
  # 1. Set NIXPKGS_ALLOW_BROKEN=1 when running hms
  # 2. Add nixpkgs.config.allowBroken = true to your configuration
  # 3. Install Ghostty manually from https://ghostty.org
  
  programs.ghostty = {
    enable = true;
    package = null;  # Use system-installed Ghostty
    
    settings = {
      # Font settings with CJK fallback
      font-family = [
        "JetBrainsMono Nerd Font Mono"  # Primary font for Latin + symbols
        "Noto Sans CJK SC"              # Simplified Chinese fallback
        "Noto Sans CJK TC"              # Traditional Chinese fallback
        "Source Han Sans"               # Alternative CJK fallback
      ];
      font-size = 14;
      
      # Gruvbox Dark Theme (matching tmux theme)
      background = "#14191f";
      cursor-style-blink = false;

      # Window config
      window-theme = "dark";
      window-width = 150;
      window-height = 40;
      window-padding-x = 4;
      window-padding-y = 4;
      
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
    };

  };
}
