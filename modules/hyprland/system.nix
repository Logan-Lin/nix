{ config, pkgs, ... }:

{
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Display manager: greetd + tuigreet
  services.greetd = {
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
    config.common.default = ["*"];
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
  ];
}
