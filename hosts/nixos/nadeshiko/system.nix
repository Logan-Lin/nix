{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../system-default.nix
    "${inputs.nixos-hardware}/common/cpu/intel/alder-lake"
    ../../../modules/vpn/nixos-client.nix
    ../../../modules/borg.nix
    ../../../modules/disk-health.nix
    ../../../modules/deluge.nix
  ];

  boot.loader.grub = {
    enable = true;
    devices = [
      "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R"
      "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG"
    ];
    efiSupport = true;
    efiInstallAsRemovable = true;
    zfsSupport = true;
    configurationLimit = 10;
  };

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };

  boot.initrd.systemd.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

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

  services.wireguard-client = {
    enable = true;
    address = "10.2.2.10/24";
    serverPublicKey = "46QHjSzAas5g9Hll1SCEu9tbR5owCxXAy6wGOUoPwUM=";
    serverEndpoint = "91.98.84.215:51820";
  };

  services.deluge-custom = {
    enable = true;
    downloadDir = "/mnt/storage/downloads";
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
