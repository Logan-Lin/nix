{ config, pkgs, ... }: 

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ../system-default.nix
    ../../../modules/vpn/tailscale.nix
    ../../../modules/podman.nix
    ../../../modules/borg/client.nix
    ../../../modules/media/server.nix
  ];

  # GRUB bootloader with ZFS support
  boot.loader.grub = {
    enable = true;
    devices = [
      "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R"
      "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG"
    ]; # Install GRUB on both ZFS mirror drives
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

  # Disable systemd stage-1 (use traditional initrd for ZFS compatibility)
  boot.initrd.systemd.enable = false;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # ZFS ARC memory configuration for 32GB system
  boot.kernelParams = [
    "zfs.zfs_arc_max=17179869184"  # 16GB max ARC size
    "zfs.zfs_arc_min=2147483648"   # 2GB min ARC size
  ];

  # Network configuration
  networking = {
    hostName = "nfss";
    hostId = "8425e349"; # Required for ZFS
    networkmanager.enable = true;
    firewall = { enable = false; };
  };

  # Host-specific SSH configuration
  services.openssh = {
    settings = {
      PermitRootLogin = "yes";
    };
    openFirewall = true;
  };

  # Define a user account
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

  # Host-specific user configuration
  users.users.yanlin = {
    extraGroups = [ "networkmanager" "wheel" ];
    hashedPassword = "$6$8NUV0JK33hs3XBYe$osnYKzENDLYHQEpj8Z5F6ECpLdc8Y3RZcVGxQ0bc/6DepTwugAkfX8h6ItI01dJyk8RstiGsWVVCKGwXaL.sN.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG35m0DgTrEOAM+1wAlYZ8mvLelNTcx65cFccGPQcxmo yanlin@imac"
    ];
  };

  # Intel graphics for hardware acceleration (QSV/VA-API)
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

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    smartmontools
    zfs
    intel-gpu-tools
    exfatprogs
  ];

  # ZFS services configuration
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
      monthly = 12;
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  services.tailscale-custom = {
    exitNode = true;
    subnetRoutes = [ "10.1.1.0/24" ];
  };

  # Media server services
  services.media-server = {
    user = "yanlin";
    deluge.enable = true;
  };

  # Borg backup configuration
  services.borg-client-custom = {
    enable = false;
    repositoryUrl = "ssh://borg-box/./nfss";
    backupPaths = [
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
