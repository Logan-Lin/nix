{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../system-default.nix  # Common NixOS system configuration
  ];

  # Bootloader - standard UEFI setup
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Use latest kernel for better hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Network configuration
  networking = {
    hostName = "deck";
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
    firewall.enable = false;
  };

  # Hardware support for Steam Deck (AMD APU)
  hardware = {
    enableRedistributableFirmware = true;

    # Graphics configuration for AMD
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Bluetooth support
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };

  # Sound configuration with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Jovian Steam Deck configuration
  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      desktopSession = "gnome";
    };
    decky-loader.enable = true;
    devices.steamdeck = {
      enable = true;
      autoUpdate = true;
    };
  };

  # GNOME Desktop Environment
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Keyboard layout
  services.xserver.xkb = {
    layout = "us";
    options = "";
  };

  # XDG portal for proper desktop integration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };

  # Touchscreen configuration
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
    };
  };

  # Host-specific SSH configuration
  services.openssh = {
    settings = {
      PermitRootLogin = "no";
    };
  };

  # Host-specific user configuration
  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    hashedPassword = "$6$kSyaRzAtj8VPcNeX$NsEP6zQAfp6O8YWcolfPRKnhIcJlKu5luZgWqozJAHtbE/gv90KoOOKU7Dt.FnbPB0Ej26jXoBH4X.7y/OLGB1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzmzq6xXp7KkUfPsFo/4O7AYVCJ1U+GrbD0fB10izMF yanlin@thinkpad"
    ];
  };

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # System utilities
    pciutils
    usbutils
    unzip

    # Icon themes for GNOME applications
    adwaita-icon-theme
    hicolor-icon-theme
  ];

}
