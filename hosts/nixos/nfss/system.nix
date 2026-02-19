{ config, pkgs, ... }: 

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ../system-default.nix
    ../../../modules/vpn/client.nix
    ../../../modules/podman.nix
    ../../../modules/git/runner.nix
    ../../../modules/borg/client.nix
    ../../../modules/media/server.nix
    ../../../modules/file-server/samba.nix
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

  boot.initrd.systemd.enable = false;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  boot.kernelParams = [
    "zfs.zfs_arc_max=17179869184"
    "zfs.zfs_arc_min=2147483648"
  ];

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/20251dfb-f99a-4393-8c9e-0bb26d04b718";
    fsType = "ext4";
  };

  systemd.tmpfiles.rules = [
    "d /mnt/storage 0755 yanlin users -"
  ];

  networking = {
    hostName = "nfss";
    hostId = "8425e349";
    networkmanager.enable = true;
    firewall = { enable = false; };
  };

  services.openssh = {
    settings = {
      PermitRootLogin = "yes";
    };
    openFirewall = true;
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

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

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
      pools = [ "rpool" ];
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

  services.media-server = {
    user = "yanlin";
    navidrome.enable = true;
    deluge.enable = true;
  };

  services.samba-custom.shares = {
    Downloads = "/home/yanlin/Downloads";
    Media = "/home/yanlin/Media";
  };

  services.git-runner-custom = {
    enable = true;
    url = "https://git.yanlincs.com";
    instances.tex.labels = [
      "tex:docker://texlive/texlive:latest-full"
    ];
  };

  services.borg-client-custom = {
    enable = true;
    repositoryUrl = "ssh://helsinki-box/./nfss";
    backupPaths = [
      "/mnt/storage/photos/library"
    ];
    backupFrequency = "*-*-* 01:00:00";
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
  };

}
