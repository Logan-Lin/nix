# NixOS configuration for nadeshiko, a home file server built on ZFS storage.
# It shares the storage pool over Samba, runs the Deluge torrent client, and backs up documents to another host with Borg.
# Named after 大室撫子, the eldest and most mature of the 大室 sisters.
# Like her, this host is the calm and reliable one, running on a ZFS mirror of enterprise SSDs and quietly keeping the family's files and backups safe.

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../system-default.nix
    "${inputs.nixos-hardware}/common/cpu/intel/alder-lake"
    ../../../modules/borg.nix
    ../../../modules/disk-health.nix
    ../../../modules/deluge.nix
    ../../../modules/media-stream.nix
    ../../../modules/samba.nix
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    zfsSupport = true;
    configurationLimit = 10;
    mirroredBoots = [
      {
        path = "/boot";
        efiSysMountPoint = "/boot";
        devices = [ "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R" ];
      }
      {
        path = "/boot-alt";
        efiSysMountPoint = "/boot-alt";
        devices = [ "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG" ];
      }
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };

  boot.initrd.systemd.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Bound the ZFS ARC cache to between 2 GiB and 16 GiB.
  boot.kernelParams = [
    "zfs.zfs_arc_max=17179869184"
    "zfs.zfs_arc_min=2147483648"
  ];

  networking = {
    hostName = "nadeshiko";
    hostId = "8425e349";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 22000 25000 ];
      allowedUDPPorts = [ 22000 25000 ];
    };
  };

  services.openssh = {
    settings = {
      PermitRootLogin = "yes";
    };
  };

  # Clear every root password field so no layer can set one, leaving the SSH key as the only way to log in as root.
  users.users.root = {
    hashedPassword = null;
    hashedPasswordFile = null;
    password = null;
    initialHashedPassword = null;
    initialPassword = null;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG35m0DgTrEOAM+1wAlYZ8mvLelNTcx65cFccGPQcxmo yanlin@imac"
    ];
  };

  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" ];
    hashedPassword = "$6$8NUV0JK33hs3XBYe$osnYKzENDLYHQEpj8Z5F6ECpLdc8Y3RZcVGxQ0bc/6DepTwugAkfX8h6ItI01dJyk8RstiGsWVVCKGwXaL.sN.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG35m0DgTrEOAM+1wAlYZ8mvLelNTcx65cFccGPQcxmo yanlin@imac"
    ];
  };

  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    smartmontools
    zfs
    intel-gpu-tools
    exfatprogs
  ];

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
      pools = [ "rpool" "storage" ];
    };
    autoSnapshot = {
      enable = true;
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 0;
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  services.deluge-custom = {
    enable = true;
    downloadDir = "/mnt/storage/downloads";
  };

  services.media-stream = {
    enable = true;
    mediaDir = "/mnt/storage/media";
  };

  services.samba-share = {
    enable = true;
    hostsAllow = [ "100.64.0.0/10" "10.1.1." ];
    shares.storage.path = "/mnt/storage";
  };

  services.disk-health = {
    enable = true;
    frequency = "Sun *-*-* 06:00:00";
    devices = [
      "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R"
      "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG"
      "/dev/disk/by-id/nvme-WD_Blue_SN580_2TB_2444EL405513"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/storage 0755 yanlin users -"
  ];

  services.journald.extraConfig = "SystemMaxUse=5G";

  services.borg-custom = {
    enable = true;
    repositoryUrl = "ssh://oomuroke/./nadeshiko";
    backupPaths = [
      "/home/yanlin/Documents"
      "/home/yanlin/.ssh/"
    ];
    backupFrequency = "*-*-* 01:00:00";
    checkFrequency = "Sun *-*-* 13:00:00";
  };

}
