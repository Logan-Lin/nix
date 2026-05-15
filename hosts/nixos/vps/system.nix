{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./containers.nix
    ../system-default.nix
    ../../../modules/vpn/server.nix
    ../../../modules/podman.nix
    ../../../modules/nginx.nix
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
        publicKey = "DTjKBUIDE0n/fUnTYAlcRwcONkS7IZw8qbxCJOqIuGQ=";
        allowedIPs = [ "10.2.2.5/32" ];
      }
      {
        publicKey = "MCuSF/aFZy7Jq3nI6VpU7jbfZOuEGuMjgpxRWazxtmY=";
        allowedIPs = [ "10.2.2.10/32" ];
      }
      {
        publicKey = "4oEuNw/eaPy8sxHMt/xzVAJYv6/op9/hl3iZZsj8ZBY=";
        allowedIPs = [ "10.2.2.20/32" ];
      }
      {
        publicKey = "00K2AHKt7lWz91U77SQaG+Vmql2BRVQG53yVFRACqEc=";
        allowedIPs = [ "10.2.2.30/32" ];
      }
      {
        publicKey = "eufamkZ/LKkIxe8tHzKbtyV7MtWJN4ujCHqgf5m4TjY=";
        allowedIPs = [ "10.2.2.40/32" ];
      }
    ];
  };

  services.reverse-proxy = {
    enable = true;
    defaultDomain = "yanlincs.com";
    acmeEmail = "cloudflare@yanlincs.com";

    proxies = {
      deluge.backend = "http://10.2.2.10:8112";
    };
  };

  services.journald.extraConfig = "SystemMaxUse=1G";

  services.borg-custom = {
    enable = true;
    repositoryUrl = "ssh://helsinki-box/./vps";
    backupPaths = [
      "/var/lib/mongodb"
      "/home/yanlin/.config/"
      "/home/yanlin/.ssh/"
    ];
    backupFrequency = "*-*-* 03:00:00";
    checkFrequency = "Sun *-*-* 11:00:00";
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
  };

}
