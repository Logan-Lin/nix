{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.desktop-custom;
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
  };
}
