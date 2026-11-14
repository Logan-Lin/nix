# hanako is a headless cloud server.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./containers.nix
    ../system-default.nix
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
    hostName = "hanako";
    hostId = "a8c06f42";
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVvviqbwBEGDIbAUnmgHQJi+N5Qfvo5u49biWl6R7oC yanlin@MacBook-Air"
    ];
  };

  users.users.yanlin = {
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVvviqbwBEGDIbAUnmgHQJi+N5Qfvo5u49biWl6R7oC yanlin@MacBook-Air"
    ];
  };

  services.journald.settings.Journal.SystemMaxUse = "1G";

  # NOTE: Create the first user after deploy with `sudo linkding-manage createsuperuser`.
  services.linkding = {
    enable = true;
    settings.LD_CSRF_TRUSTED_ORIGINS = "https://link.yanlincs.com";
  };

  services.reverse-proxy = {
    enable = true;
    defaultDomain = "yanlincs.com";
    acmeEmail = "cloudflare@yanlincs.com";
    proxies = {
      # Deluge runs on misaki and is reached through its Tailscale address.
      deluge.backend = "http://100.107.246.21:8112";
      link.backend = "http://127.0.0.1:${toString config.services.linkding.port}";
    };
  };

  services.borg-custom = {
    enable = true;
    repositoryUrl = "ssh://oomuroke/./hanako";
    backupPaths = [
      "/var/lib/mongodb"
      "/var/lib/linkding"
      "/home/yanlin/.ssh"
    ];
    backupFrequency = "*-*-* 03:00:00";
    checkFrequency = "Sun *-*-* 11:00:00";
  };

}
