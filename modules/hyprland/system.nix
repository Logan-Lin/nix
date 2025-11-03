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

  # GNOME Keyring with PAM integration for WiFi password storage
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

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
  ];
}
