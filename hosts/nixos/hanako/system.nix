# NixOS configuration for hanako, a headless home server.
# It runs podman containers including a MongoDB database and backs its data up to a remote Borg repository.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./containers.nix
    ../system-default.nix
    ../../../modules/podman.nix
    ../../../modules/borg.nix
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
    hostName = "hanako";
    hostId = "a8c06f42";
    networkmanager.enable = false;
    useDHCP = true;
    firewall = {
      enable = true;
      # Port 27017 exposes the MongoDB container to remote clients.
      allowedTCPPorts = [ 22 27017 ];
    };
  };

  services.openssh = {
    settings = {
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVvviqbwBEGDIbAUnmgHQJi+N5Qfvo5u49biWl6R7oC yanlin@MacBook-Air"
    ];
  };

  users.users.yanlin = {
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVvviqbwBEGDIbAUnmgHQJi+N5Qfvo5u49biWl6R7oC yanlin@MacBook-Air"
    ];
  };

  services.journald.extraConfig = "SystemMaxUse=1G";

  services.borg-custom = {
    enable = true;
    repositoryUrl = "ssh://oomuroke/./hanako";
    backupPaths = [
      "/var/lib/mongodb"
      "/home/yanlin/.ssh/"
    ];
    backupFrequency = "*-*-* 03:00:00";
    checkFrequency = "Sun *-*-* 11:00:00";
  };

}
