{ config, pkgs, ... }: 

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ./proxy.nix
    ../system-default.nix
    ../../../modules/vpn/server.nix
    ../../../modules/podman.nix
    ../../../modules/traefik.nix
    ../../../modules/borg/client.nix
    ../../../modules/git/server.nix
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
    hostName = "vps";
    hostId = "a8c06f42";
    networkmanager.enable = false;
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 27017 ];
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

  services.wireguard-server = {
    enable = true;
    address = "10.2.2.1/24";
    peers = [
      {
        publicKey = "MCuSF/aFZy7Jq3nI6VpU7jbfZOuEGuMjgpxRWazxtmY=";
        allowedIPs = [ "10.2.2.10/32" ];
      }
      {
        publicKey = "xqsOWaCaEK1ehC+66deEQxAN92AYPyL9IrIeM4ujIRM=";
        allowedIPs = [ "10.2.2.20/32" ];
      }
    ];
  };

  services.git-server-custom = {
    enable = true;
    domain = "git.yanlincs.com";
  };

  services.borg-client-custom = {
    enable = true;
    repositoryUrl = "ssh://helsinki-box/./vps";
    backupPaths = [
      "/var/lib/mongodb"
      "/var/lib/forgejo"
    ];
    backupFrequency = "*-*-* 03:00:00";
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
  };

}
