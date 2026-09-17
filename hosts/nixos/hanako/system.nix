# NixOS configuration for hanako, a headless cloud server.

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
    ../../../modules/deluge.nix
    ../../../modules/samba.nix
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

  # NOTE: credentials file at: `/etc/falkenstein-box-password` with mode 600
  # content: `password=your-password`
  fileSystems."/mnt/storage" = {
    device = "//u664260.your-storagebox.de/backup";
    fsType = "cifs";
    options = [
      "username=u664260"
      "credentials=/etc/falkenstein-box-password"
      "uid=yanlin"
      "gid=users"
      "seal"
      "_netdev"
      "noauto"
      "x-systemd.automount"
    ];
  };

  services.deluge-custom = {
    enable = true;
    downloadDir = "/mnt/storage/downloads";
  };

  services.reverse-proxy = {
    enable = true;
    defaultDomain = "yanlincs.com";
    acmeEmail = "cloudflare@yanlincs.com";
    proxies = {
      deluge.backend = "http://127.0.0.1:${toString config.services.deluge-custom.webPort}";
    };
  };

  services.samba-share = {
    enable = true;
    hostsAllow = [ "100.64.0.0/10" "127." ];
    shares.storage.path = "/mnt/storage";
  };

  services.borg-custom = {
    enable = true;
    repositoryUrl = "ssh://oomuroke/./hanako";
    backupPaths = [
      "/var/lib/mongodb"
      "/home/yanlin/.ssh"
    ];
    backupFrequency = "*-*-* 03:00:00";
    checkFrequency = "Sun *-*-* 11:00:00";
  };

}
