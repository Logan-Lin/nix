{ config, pkgs, home-manager, nixvim, claude-code, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    home-manager.nixosModules.home-manager
    ../../../modules/tailscale.nix
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
  boot.zfs.extraPools = [ "cache" ]; # Auto-import additional pools

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
    firewall.enable = false;
    # firewall.allowedTCPPorts = [ 22 ]; # SSH
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
      pools = [ "rpool" "cache" ];
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

  # Container virtualization with Podman
  virtualisation = {
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other
      defaultNetwork.settings.dns_enabled = true;
      # Create macvlan network for Home Assistant
      extraPackages = [ pkgs.netavark pkgs.aardvark-dns ];
    };
    # Enable OCI container support
    oci-containers = {
      backend = "podman";
      
      containers.homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        
        volumes = [
          "/home/yanlin/deploy/data/home/config:/config"
          "/etc/localtime:/etc/localtime:ro"
          "/run/dbus:/run/dbus:ro"
        ];
        
        environment = {
          TZ = "Europe/Copenhagen";
        };
        
        extraOptions = [
          "--privileged"  # Required for USB device access
          "--network=host"  # Use host networking
          "--device=/dev/ttyUSB0:/dev/ttyUSB0"  # Sky Connect Zigbee dongle
          "--device=/dev/dri:/dev/dri"  # Hardware acceleration
        ];
        
        autoStart = true;
      };
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


  # Enable smartd for disk health monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;

  # Enable zsh system-wide (required when set as user shell)
  programs.zsh.enable = true;

  # Enable experimental nix features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.yanlin = import ./home.nix;
    extraSpecialArgs = { inherit claude-code nixvim; };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05"; # Did you read the comment?
}
