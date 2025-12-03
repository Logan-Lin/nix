{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ./proxy.nix
    ../system-default.nix
    ../../../modules/tailscale.nix
    ../../../modules/podman.nix
    ../../../modules/traefik.nix
    ../../../modules/borg/client.nix
    ../../../modules/login-display.nix
    ../../../modules/samba.nix
    ../../../modules/media-server.nix
    ../../../modules/miniflux.nix
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
  };

  # Enable systemd stage-1 and ZFS support
  boot.initrd.systemd.enable = true;
  boot.supportedFilesystems = [ "zfs" "xfs" ];
  boot.zfs.forceImportRoot = false;

  # ZFS ARC memory configuration for 32GB system
  boot.kernelParams = [
    "zfs.zfs_arc_max=17179869184"  # 16GB max ARC size
    "zfs.zfs_arc_min=2147483648"   # 2GB min ARC size
  ];

  # XFS drive mounts
  fileSystems."/mnt/wd-12t-1" = {
    device = "/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PK2N4GB-part1";
    fsType = "xfs";
    options = [ "defaults" "noatime" ];
  };

  fileSystems."/mnt/wd-12t-2" = {
    device = "/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PJ7Z3LE-part1";
    fsType = "xfs";
    options = [ "defaults" "noatime" ];
  };

  # Parity drive for SnapRAID
  fileSystems."/mnt/parity" = {
    device = "/dev/disk/by-id/ata-ST16000NM000J-2TW103_WRS0F8BE-part1";
    fsType = "xfs";
    options = [ "defaults" "noatime" ];
  };

  # MergerFS union mount (needs to be after XFS mounts)
  fileSystems."/mnt/storage" = {
    device = "/mnt/wd-12t-1:/mnt/wd-12t-2";
    fsType = "mergerfs";
    options = [
      "defaults"
      "allow_other"
      "use_ino"
      "cache.files=partial"
      "dropcacheonclose=true"
      "category.create=mfs"
    ];
  };

  # Network configuration
  networking = {
    hostName = "hs";
    hostId = "8425e349"; # Required for ZFS, good practice for any system
    networkmanager.enable = true;
    firewall = { enable = false; };
  };


  # Host-specific SSH configuration
  services.openssh = {
    settings = {
      PermitRootLogin = "yes";  # Allow root login for this server
    };
    openFirewall = true;
  };

  # Define a user account
  users.users.root = {
    # Clear any inherited password settings
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
    smartmontools # For monitoring disk health
    zfs # ZFS utilities
    mergerfs # Union filesystem for combining multiple drives
    snapraid # Parity-based backup tool
    intel-gpu-tools # GPU monitoring (intel_gpu_top, etc.)
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
      frequent = 4;  # Keep 4 15-minute snapshots
      hourly = 24;   # Keep 24 hourly snapshots
      daily = 7;     # Keep 7 daily snapshots
      weekly = 4;    # Keep 4 weekly snapshots
      monthly = 12;  # Keep 12 monthly snapshots
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  # SnapRAID configuration for parity protection
  services.snapraid = {
    enable = true;
    
    # Parity file location on 16TB drive
    parityFiles = [
      "/mnt/parity/snapraid.parity"
    ];
    
    # Content files for metadata (stored on multiple drives for redundancy)
    contentFiles = [
      "/var/snapraid.content"
      "/mnt/parity/.snapraid.content"
      "/mnt/wd-12t-1/.snapraid.content"
      "/mnt/wd-12t-2/.snapraid.content"
    ];

    # Data disks to protect
    dataDisks = {
      d1 = "/mnt/wd-12t-1/";
      d2 = "/mnt/wd-12t-2/";
    };
    
    # Sync and scrub schedule
    sync.interval = "02:00";
    scrub.interval = "Mon *-*-* 06:00:00";
    
    # Files and directories to exclude from parity
    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "*.!sync"
      ".DS_Store"
      "._.DS_Store"
      ".Spotlight-V100/"
      ".TemporaryItems/"
      ".Trashes/"
      ".fseventsd/"
      "Thumbs.db"
      "*.tmp"
      "*.tmp.*"
      "*.temp"
      "*.temp.*"
      "*.!qB"
      "*.part"
    ];
  };

  # Login display with SMART disk health status
  services.login-display = {
    enable = true;
    showSystemInfo = true;
    showSmartStatus = true;
    smartDrives = {
      "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R" = "ZFS_Mirror_1";
      "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG" = "ZFS_Mirror_2";
      "/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PK2N4GB" = "Data_1_12TB";
      "/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PJ7Z3LE" = "Data_2_12TB";
      "/dev/disk/by-id/ata-ST16000NM000J-2TW103_WRS0F8BE" = "Parity_16TB";
    };
    showDiskUsage = true;
    diskUsagePaths = [ "/" "/home/" "/mnt/storage" "/mnt/parity" ];
    showSnapraidStatus = true;
    showBorgStatus = true;
  };

  # Borg backup configuration
  services.borg-client-custom = {
    enable = true;
    # Use SSH alias from SSH config for remote backup to thinkpad borg server
    repositoryUrl = "ssh://hs@borg-thinkpad/./hs";
    backupPaths = [
      "/mnt/storage/appbulk/immich/library/"
      "/mnt/storage/Media/DCIM"
      "/mnt/storage/Media/nsfw"
    ];
    backupFrequency = "*-*-* 00:00:00";
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
    passphraseFile = "/etc/borg-passphrase";

    preHook = ''
      echo "$(date): Starting Borg backup of ${config.networking.hostName}"
    '';
    postHook = ''
      echo "$(date): Borg backup of ${config.networking.hostName} completed successfully"
    '';
  };

  services.tailscale-custom = {
    exitNode = true;
    subnetRoutes = [ "10.1.1.0/24" ];
  };

  # Samba file sharing
  services.samba-custom = {
    sharedPath = "/mnt/storage/Media";
    shareName = "Media";
    user = "yanlin";
  };

  # Media server services
  services.media-server = {
    user = "yanlin";
    sonarr.enable = true;
    radarr.enable = true;
    jellyfin.enable = true;
    deluge.enable = true;
  };

}
