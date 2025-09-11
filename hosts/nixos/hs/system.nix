{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./containers.nix  # Host-specific container definitions
    ./proxy.nix       # Host-specific Traefik dynamic configuration
    ./disk-health.nix # Host-specific disk health monitoring
    ../../../modules/wireguard.nix
    ../../../modules/podman.nix
    ../../../modules/traefik.nix
    ../../../modules/samba.nix
    ../../../modules/borg.nix
    ../../../modules/webdav.nix
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

  # Set your time zone
  time.timeZone = "Europe/Copenhagen"; # Adjust to your timezone

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AcceptEnv = "LANG LC_* TERM COLORTERM TMUX TMUX_PANE";
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

  # Optional: Create a regular user account
  users.users.yanlin = {
    isNormalUser = true;
    description = "yanlin";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$8NUV0JK33hs3XBYe$osnYKzENDLYHQEpj8Z5F6ECpLdc8Y3RZcVGxQ0bc/6DepTwugAkfX8h6ItI01dJyk8RstiGsWVVCKGwXaL.sN.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG35m0DgTrEOAM+1wAlYZ8mvLelNTcx65cFccGPQcxmo yanlin@imac"
    ];
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
    rsync
    tmux
    tree
    lsof
    tcpdump
    iotop
    smartmontools # For monitoring disk health
    zfs # ZFS utilities
    zsh # Shell
    home-manager # Enable standalone home-manager command
    mergerfs # Union filesystem for combining multiple drives
    snapraid # Parity-based backup tool
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
    
    # Sync schedule (daily at 3 AM)
    sync.interval = "03:00";
    
    # Scrub schedule (weekly verification)
    scrub.interval = "weekly";
    
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
      "*.temp"
    ];
  };


  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;

  # Enable zsh system-wide (required when set as user shell)
  programs.zsh.enable = true;

  # Enable experimental nix features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Samba file sharing configuration
  services.samba-custom = { enable = false; };

  # WebDAV file server configuration
  services.webdav-server = {
    enable = true;
    port = 5009;
    servePath = "/mnt/storage/Media/NSFW";
    auth = {
      username = "yanlin";
      passwordFile = "/etc/webdav-password";
    };
    readOnly = false;
    allowUpload = true;
    allowDelete = true;
    allowSearch = true;
    allowSymlink = false;
    hideDotFiles = true;
  };

  # Borg backup configuration
  services.borgbackup-custom = {
    enable = true;
    # Use SSH alias from SSH config for remote backup
    repositoryUrl = "ssh://storage-box/./hs";
    backupPaths = [
      "/home"
      "/var/lib/containers" 
      "/mnt/storage/appbulk/immich/library/"
      "/mnt/storage/appbulk/Paperless/media/documents"
      "/mnt/storage/Media/DCIM"
      "/mnt/storage/Media/NSFW"
    ];
    # Examples:
    # backupFrequency = "daily";           # Midnight (default)
    # backupFrequency = "*-*-* 03:00:00";  # Every day at 3:00 AM
    # backupFrequency = "*-*-* 22:30:00";  # Every day at 10:30 PM
    # backupFrequency = "Mon,Wed,Fri 02:00:00"; # Mon/Wed/Fri at 2:00 AM
    backupFrequency = "daily";
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
    passphraseFile = "/etc/borg-passphrase";
    
    # Gotify notifications
    enableNotifications = true;
    gotifyUrl = "https://notify.yanlincs.com";
    gotifyToken = "Ac9qKFH5cA.7Yly";

    # Integrity check configuration
    enableIntegrityCheck = true;
    integrityCheckFrequency = "Sun *-*-* 05:00:00";  # Weekly on Sunday at 5 AM (offset from VPS)
    integrityCheckDepth = "archives";  # Check repository and archive metadata
    integrityCheckLastArchives = 2;  # Check last 2 archives if using data verification (HS has larger data)
    
    preHook = ''
      echo "$(date): Starting Borg backup of ${config.networking.hostName}"
    '';
    postHook = ''
      echo "$(date): Borg backup of ${config.networking.hostName} completed successfully"
    '';
  };

  # WireGuard VPN configuration (HS as client/spoke)
  services.wireguard-custom = {
    enable = true;
    mode = "client";
    clientConfig = {
      address = "10.2.2.20/24";
      serverPublicKey = "46QHjSzAas5g9Hll1SCEu9tbR5owCxXAy6wGOUoPwUM=";
      serverEndpoint = "91.98.84.215:51820";
      allowedIPs = [ "10.2.2.0/24" ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05"; # Did you read the comment?
}
