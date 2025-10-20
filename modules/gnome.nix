{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.gnome-custom;

  # Import gvariant helpers for dconf types
  mkTuple = lib.hm.gvariant.mkTuple;
  mkUint32 = lib.hm.gvariant.mkUint32;
in

{
  options.programs.gnome-custom = {
    enable = mkEnableOption "GNOME desktop environment configuration";
  };

  config = mkIf cfg.enable {
    # GNOME configuration via dconf
    dconf.settings = {
      # Interface settings
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
        cursor-theme = "Adwaita";
      };

      # Input sources - US English
      "org/gnome/desktop/input-sources" = {
        sources = [ (mkTuple [ "xkb" "us" ]) ];
        xkb-options = [ "" ];
      };

      # Favorite applications in dash
      "org/gnome/shell" = {
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "firefox.desktop"
          "obsidian.desktop"
          "org.gnome.Console.desktop"
          "org.keepassxc.KeePassXC.desktop"
        ];
      };

      # GNOME Terminal configuration with Gruvbox Dark theme (matching ghostty)
      "org/gnome/terminal/legacy" = {
        schema-version = mkUint32 3;
        default-show-menubar = false;
        theme-variant = "dark";
      };

      # Default terminal profile
      "org/gnome/terminal/legacy/profiles:" = {
        default = "b1dcc9dd-5262-4d8d-a863-c897e6d979b9";
        list = [ "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" ];
      };

      # Terminal profile with Gruvbox Dark colors (matching ghostty config)
      "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        visible-name = "Default";

        # Font settings - matching ghostty
        use-system-font = false;
        font = "JetBrainsMono Nerd Font Mono 14";

        # Colors - Gruvbox Dark theme
        use-theme-colors = false;
        background-color = "rgb(20,25,31)";  # #14191f
        foreground-color = "rgb(235,219,178)";  # Gruvbox fg

        # Palette colors (Gruvbox Dark)
        palette = [
          "rgb(40,40,40)"      # black
          "rgb(204,36,29)"     # red
          "rgb(152,151,26)"    # green
          "rgb(215,153,33)"    # yellow
          "rgb(69,133,136)"    # blue
          "rgb(177,98,134)"    # magenta
          "rgb(104,157,106)"   # cyan
          "rgb(168,153,132)"   # white
          "rgb(146,131,116)"   # bright black
          "rgb(251,73,52)"     # bright red
          "rgb(184,187,38)"    # bright green
          "rgb(250,189,47)"    # bright yellow
          "rgb(131,165,152)"   # bright blue
          "rgb(211,134,155)"   # bright magenta
          "rgb(142,192,124)"   # bright cyan
          "rgb(235,219,178)"   # bright white
        ];

        # Cursor settings - matching ghostty
        cursor-blink-mode = "off";
        cursor-shape = "block";

        # Scrollback
        scrollback-lines = 10000;

        # Bell
        audible-bell = false;

        # Other preferences
        use-transparent-background = false;
        default-size-columns = 160;
        default-size-rows = 40;
      };

      # GNOME Console configuration
      "org/gnome/Console" = {
        audible-bell = false;
      };

      # Disable GNOME Software auto-updates
      "org/gnome/software" = {
        download-updates = false;
        download-updates-notify = false;
      };
    };

    # Configure cursor theme system-wide
    home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
