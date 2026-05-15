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
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    services.greetd = mkIf cfg.enableDisplayManager {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
          user = "greeter";
        };
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = "hyprland;gtk";
    };

    programs.dconf.enable = true;

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = mkIf cfg.enableDisplayManager true;

    environment.systemPackages = with pkgs; [
      hypridle
      hyprlock
      hyprpolkitagent
      tuigreet
      waybar
      wofi
      networkmanagerapplet
      pavucontrol
      brightnessctl
      nwg-displays
      swaynotificationcenter
      qt5.qtwayland
      qt6.qtwayland
      iptables
    ];

    services.upower.enable = true;
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    services.libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = false;
        disableWhileTyping = true;
      };
    };

    services.printing = {
      enable = true;
      browsing = true;
      drivers = with pkgs; [
        cups-filters
        gutenprint
        samba
      ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    programs.system-config-printer.enable = true;
  };
}
