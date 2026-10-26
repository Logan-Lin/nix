# miho is a headless virtual machine on AAU's Strato OpenStack cloud.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../system-default.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
    configurationLimit = 5;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  networking = {
    hostName = "miho";
    networkmanager.enable = false;
    useDHCP = true;
    firewall.enable = true;
  };

  services.openssh = {
    settings = {
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSKQ2wmD4WcnYN7PE27/vttWwmuMNs173JUzrd0S7X4 yanlin@h29.aau1x-2.klient.slv.site.aau.dk"
    ];
  };

  users.users.yanlin = {
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSKQ2wmD4WcnYN7PE27/vttWwmuMNs173JUzrd0S7X4 yanlin@h29.aau1x-2.klient.slv.site.aau.dk"
    ];
  };

  services.journald.settings.Journal.SystemMaxUse = "1G";

}
