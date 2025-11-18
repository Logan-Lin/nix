{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.hyprland-system-custom;
in

{
  options.hyprland-system-custom = {
    enableDisplayManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable greetd display manager";
    };
  };

  config = {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Display manager: greetd + tuigreet
    services.greetd = mkIf cfg.enableDisplayManager {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    # XDG portals for screen sharing, file picker, etc.
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = "hyprland;gtk";
        };
        hyprland = {
          default = "hyprland;gtk";
        };
      };
    };

    # Configure touchpad settings
    services.libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = false;
        disableWhileTyping = true;
      };
    };

    # GNOME Keyring with PAM integration for WiFi password storage
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = mkIf cfg.enableDisplayManager true;

    # Input method configuration for Hyprland
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-rime        # Chinese Simplified/Traditional (more powerful than libpinyin)
        fcitx5-mozc        # Japanese (Romaji)
        fcitx5-gtk         # GTK integration
      ];
    };

    # System packages for Hyprland
    environment.systemPackages = with pkgs; [
      hyprland
      hypridle
      hyprlock
      hyprpaper
      tuigreet
      waybar
      wofi
      networkmanagerapplet
      pavucontrol
      nwg-displays
      swaynotificationcenter
      qt5.qtwayland
      qt6.qtwayland
      iptables
    ];

    # Printing with Windows Samba printer support
    services.printing = {
      enable = true;
      browsing = true;
      drivers = with pkgs; [
        cups-filters
        gutenprint
        samba  # SMB backend for Windows printers
      ];
    };

    # Samba for SMB printer protocol
    services.samba.enable = true;

    # Avahi for network printer discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Printer management GUI
    programs.system-config-printer.enable = true;
  };
}
