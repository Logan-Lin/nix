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
          "com.mitchellh.ghostty.desktop"
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

      # Pano clipboard manager configuration
      "org/gnome/shell/extensions/pano" = {
        send-notification-on-copy = false;  # Disable notification toasts
        play-audio-on-copy = false;  # Disable audio feedback on copy
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

    # Configure GTK icon theme
    gtk = {
      enable = true;
      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };
    };

    # Configure XDG user directories
    xdg.userDirs = {
      enable = true;
      createDirectories = true;

      # Keep these directories
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";

      # Disable unwanted directories
      music = null;
      pictures = null;
      videos = null;
      publicShare = null;
      templates = null;
    };

    # GNOME Shell extensions
    home.packages = with pkgs; [
      gnomeExtensions.hide-top-bar
      gnomeExtensions.pano
    ];
  };
}
