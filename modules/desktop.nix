{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.desktop-custom;
  # Import gvariant for dconf types
  mkTuple = lib.gvariant.mkTuple;
  mkUint32 = lib.gvariant.mkUint32;
  mkEmptyArray = lib.gvariant.mkEmptyArray;
in

{
  options.desktop-custom = {
    enableDisplayManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GDM display manager (conflicts with jovian.steam.autoStart)";
    };
  };

  config = {
    # GNOME Desktop Environment
    services.xserver.enable = true;
    services.displayManager.gdm.enable = mkIf cfg.enableDisplayManager true;
    services.desktopManager.gnome.enable = true;

    # Keyboard layout
    services.xserver.xkb = {
      layout = "us";
      options = "";
    };

    # Exclude unwanted GNOME default packages
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-console  # terminal (using Ghostty instead)
      gnome-text-editor  # text editor (using Neovim instead)
      gnome-connections  # remote desktop client
      gnome-font-viewer  # font viewer
      seahorse  # passwords and keys
      baobab  # disk usage analyzer
      gnome-disk-utility  # disks
      gnome-logs  # logs viewer
      gnome-system-monitor  # system monitor
      decibels  # audio player
      epiphany  # GNOME web browser
      file-roller  # archive manager
      geary     # GNOME email client
      gnome-music
      gnome-photos
      gnome-maps
      gnome-weather
      gnome-contacts
      gnome-clocks
      gnome-calculator
      gnome-calendar
      gnome-characters
      simple-scan
      snapshot  # camera
      totem     # video player
      yelp      # help viewer
    ];

    # XDG portal for proper desktop integration
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
    };

    # Touchpad configuration
    services.libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = false;
      };
    };

    # System packages for GNOME
    environment.systemPackages = with pkgs; [
      hicolor-icon-theme  # Fallback icon theme
    ];

    # System-level dconf configuration with lockAll to prevent overrides
    # This ensures keybindings persist after suspend/resume
    programs.dconf = {
      enable = true;
      profiles.user.databases = [{
        lockAll = true;  # Prevents GNOME and extensions from changing these settings
        settings = {
          # Mutter keybindings - window tiling (vim-style hjkl)
          "org/gnome/mutter/keybindings" = {
            toggle-tiled-left = [ "<Super>h" ];   # Tile left: Super+h
            toggle-tiled-right = [ "<Super>l" ];  # Tile right: Super+l
          };

          # Window manager keybindings (vim-style hjkl)
          "org/gnome/desktop/wm/keybindings" = {
            # Window maximize/restore
            maximize = [ "<Super>k" ];            # Maximize: Super+k
            unmaximize = [ "<Super>j" ];          # Restore: Super+j

            # Move window between monitors
            move-to-monitor-left = [ "<Super><Shift>h" ];   # Move left: Super+Shift+h
            move-to-monitor-right = [ "<Super><Shift>l" ];  # Move right: Super+Shift+l
            move-to-monitor-up = [ "<Super><Shift>k" ];     # Move up: Super+Shift+k
            move-to-monitor-down = [ "<Super><Shift>j" ];   # Move down: Super+Shift+j

            # Disable conflicting keybindings
            minimize = mkEmptyArray "s";  # Disable Super+h conflict (was minimize window)
          };

          # Disable screen lock on Super+L to free it for tiling right
          "org/gnome/settings-daemon/plugins/media-keys" = {
            screensaver = mkEmptyArray "s";  # Remove Super+L screen lock binding
          };
        };
      }];
    };
  };
}
