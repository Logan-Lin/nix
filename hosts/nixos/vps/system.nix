{ config, pkgs, ... }: 

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ../system-default.nix
    ../../../modules/vpn/server.nix
    ../../../modules/podman.nix
    ../../../modules/nginx.nix
    ../../../modules/borg/client.nix
    ../../../modules/git/server.nix
    ../../../modules/git/runner.nix
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

  services.reverse-proxy = {
    enable = true;
    defaultDomain = "yanlincs.com";
    acmeEmail = "cloudflare@yanlincs.com";

    proxies = {
      photo = {
        backend = "http://10.2.2.10:8080";
        extraConfig = ''
          client_max_body_size 0;
          proxy_read_timeout 1200s;
          proxy_send_timeout 1200s;
          proxy_connect_timeout 30s;
        '';
      };
      music.backend = "http://10.2.2.10:4533";
      deluge.backend = "http://10.2.2.10:8112";
      git = {
        backend = "http://127.0.0.1:3000";
        extraConfig = ''
          client_max_body_size 0;
        '';
        rateLimit = {
          rate = "10r/s";
          burst = 40;
        };
      };
    };
  };

  services.git-server-custom = {
    enable = true;
    domain = "git.yanlincs.com";
  };

  services.git-runner-custom = {
    enable = true;
    url = "https://git.yanlincs.com";
    instances.default.labels = [
      "node-20:docker://node:20-bookworm"
    ];
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
