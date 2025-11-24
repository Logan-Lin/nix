{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../system-default.nix
  ];

  # Bootloader - UEFI setup for Jetson
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 50;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Hardware support for Jetson Orin Nano
  hardware = {
    enableRedistributableFirmware = true;

    # Graphics and CUDA configuration via jetpack-nixos
    graphics.enable = true;

    nvidia-jetpack = {
      enable = true;
      som = "orin-nano";
      carrierBoard = "devkit";
    };
  };

  # Network configuration
  networking = {
    hostName = "jetson";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  # Host-specific SSH configuration
  services.openssh = {
    settings = {
      PermitRootLogin = "no";
    };
  };

  # Host-specific user configuration
  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" "video" ];
    hashedPassword = "$6$kSyaRzAtj8VPcNeX$NsEP6zQAfp6O8YWcolfPRKnhIcJlKu5luZgWqozJAHtbE/gv90KoOOKU7Dt.FnbPB0Ej26jXoBH4X.7y/OLGB1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICp2goZiuSfwMA02GsHhYzUZHrQPPBgP5sWSNP9kQR3e yanlin@imac"
    ];
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
  ];

}
