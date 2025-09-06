{ config, pkgs, home-manager, nixvim, claude-code, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    home-manager.nixosModules.home-manager
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
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

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
  ];

  # ZFS services configuration
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
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
