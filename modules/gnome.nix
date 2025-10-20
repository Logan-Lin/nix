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

      # Desktop background
      "org/gnome/desktop/background" = {
        picture-uri = "file:///home/yanlin/Documents/Library/nixos-nineish-dark@4k.png";
        picture-uri-dark = "file:///home/yanlin/Documents/Library/nixos-nineish-dark@4k.png";
        picture-options = "scaled";
      };

      # Input sources - US English, Chinese Pinyin, Japanese
      "org/gnome/desktop/input-sources" = {
        sources = [
          (mkTuple [ "xkb" "us" ])
          (mkTuple [ "ibus" "libpinyin" ])
          (mkTuple [ "ibus" "mozc-jp" ])
        ];
        xkb-options = [ "" ];
      };

      # GNOME Shell configuration
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "hidetopbar@mathieu.bidon.ca"
          "pano@elhan.io"
        ];
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "firefox.desktop"
          "obsidian.desktop"
          "org.gnome.Console.desktop"
          "org.keepassxc.KeePassXC.desktop"
        ];
      };

      # Hide Top Bar extension configuration
      "org/gnome/shell/extensions/hidetopbar" = {
        enable-intellihide = true;
        enable-active-window = true;
        mouse-sensitive = false;
        mouse-sensitive-fullscreen-window = false;
      };


      # GNOME Console configuration
      "org/gnome/Console" = {
        audible-bell = false;
        custom-font = "JetBrainsMono Nerd Font Mono 13";
        use-system-font = false;
      };

      # Nautilus (GNOME Files) configuration
      "org/gnome/nautilus/preferences" = {
        show-hidden-files = true;
        default-folder-viewer = "list-view";
      };

      # Disable GNOME Software auto-updates
      "org/gnome/software" = {
        download-updates = false;
        download-updates-notify = false;
      };

      # Notification settings
      "org/gnome/desktop/notifications" = {
        show-banners = false;  # Disable notification popups (still logged in notification center)
      };

      # Sound settings
      "org/gnome/desktop/sound" = {
        event-sounds = false;  # Disable notification sounds
      };

      # IBus libpinyin (Chinese Pinyin) configuration
      "com/github/libpinyin/ibus-libpinyin/libpinyin" = {
        lookup-table-page-size = 7;  # Number of candidates displayed (default: 5)
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

    # GNOME Shell extensions
    home.packages = with pkgs; [
      gnomeExtensions.hide-top-bar
      gnomeExtensions.pano
    ];

    # GNOME Terminal configuration with Gruvbox Dark theme (matching ghostty)
    programs.gnome-terminal = {
      enable = true;
      showMenubar = false;
      themeVariant = "dark";

      profile."b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        default = true;
        visibleName = "Default";

        # Font settings - matching ghostty
        font = "JetBrainsMono Nerd Font Mono 12";

        # Colors - Gruvbox Dark theme
        colors = {
          backgroundColor = "#14191f";
          foregroundColor = "#ebdbb2";
          palette = [
            "#282828"  # black
            "#cc241d"  # red
            "#98971a"  # green
            "#d79921"  # yellow
            "#458588"  # blue
            "#b16286"  # magenta
            "#689d6a"  # cyan
            "#a89984"  # white
            "#928374"  # bright black
            "#fb4934"  # bright red
            "#b8bb26"  # bright green
            "#fabd2f"  # bright yellow
            "#83a598"  # bright blue
            "#d3869b"  # bright magenta
            "#8ec07c"  # bright cyan
            "#ebdbb2"  # bright white
          ];
        };

        # Cursor settings - matching ghostty
        cursorBlinkMode = "off";
        cursorShape = "block";

        # Scrollback
        scrollbackLines = 10000;

        # Bell
        audibleBell = false;
      };
    };
  };
}
