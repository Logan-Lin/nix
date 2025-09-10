{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./containers.nix  # Host-specific container definitions
    ./proxy.nix       # Host-specific Traefik dynamic configuration
    ../../../modules/wireguard.nix
    ../../../modules/podman.nix
    ../../../modules/traefik.nix
    ../../../modules/borg.nix
  ];

  # GRUB bootloader with UEFI support
  boot.loader.grub = {
    enable = true;
    device = "nodev"; # Required for EFI systems
    efiSupport = true;
    efiInstallAsRemovable = true; # Better compatibility with VPS
  };

  # Network configuration
  networking = {
    hostName = "vps";
    hostId = "a8c06f42"; # Required for some services, generated randomly
    networkmanager.enable = false; # Use systemd-networkd for VPS
    useDHCP = true; # VPS typically use DHCP
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
      trustedInterfaces = [ "wg0" ]; # Allow all traffic through WireGuard interface
    };
  };

  # Set your time zone
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password"; # Allow key-based root login for nixos-anywhere
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Root user configuration (for nixos-anywhere initial access)
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVvviqbwBEGDIbAUnmgHQJi+N5Qfvo5u49biWl6R7oC yanlin@MacBook-Air"
    ];
  };

  # Regular user account
  users.users.yanlin = {
    isNormalUser = true;
    description = "yanlin";
    extraGroups = [ "wheel" ]; # Enable sudo
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVvviqbwBEGDIbAUnmgHQJi+N5Qfvo5u49biWl6R7oC yanlin@MacBook-Air"
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
    zsh
    home-manager
  ];

  # Enable zsh system-wide (required when set as user shell)
  programs.zsh.enable = true;

  # Enable experimental nix features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;

  # Borg backup configuration
  services.borgbackup-custom = {
    enable = true;
    # Use SSH alias from SSH config for remote backup
    repositoryUrl = "ssh://storage-box/./vps";
    backupPaths = [
      "/home"
      "/var/lib/containers"
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
    gotifyToken = "AaiBamxPAhatNrO";

    # Integrity check configuration
    enableIntegrityCheck = true;
    integrityCheckFrequency = "Sun *-*-* 04:00:00";  # Weekly on Sunday at 4 AM
    integrityCheckDepth = "archives";  # Check repository and archive metadata
    integrityCheckLastArchives = 3;  # Check last 3 archives if using data verification

    preHook = ''
      echo "$(date): Starting Borg backup of ${config.networking.hostName}"
    '';
    postHook = ''
      echo "$(date): Borg backup of ${config.networking.hostName} completed successfully"
    '';
  };

  # WireGuard VPN configuration (VPS as hub/server)
  services.wireguard-custom = {
    enable = true;
    mode = "server";
    serverConfig = {
      address = "10.2.2.1/24";
      peers = [
        {
          name = "hs";
          publicKey = "HZY7V8QlnFvY6ZWNiI0WgUgWUISnEqUdzXi7Oq9M1Es=";
          allowedIPs = [ "10.2.2.20/32" ];
        }
        {
          name = "iphone";
          publicKey = "mK4zGcytZP0Jane7kE36milpcWERWzYZKZyrbUlNFFg=";
          allowedIPs = [ "10.2.2.30/32" ];
        }
        {
          name = "ipad";
          publicKey = "f/+Jyz4CpD5uyaZox77IuD9mI/KU9QOiK6tLMcbVGTE=";
          allowedIPs = [ "10.2.2.31/32" ];
        }
        {
          name = "imac";
          publicKey = "MVpIxA7HOjTCAsyI/IXK4lo0B2OM9BCHzUelUyAqT20=";
          allowedIPs = [ "10.2.2.40/32" ];
        }
        {
          name = "mba";
          publicKey = "NeaCT4v6eUzHkRhm5YcKnB4W8KXBCZNedoBlLM5zMQQ=";
          allowedIPs = [ "10.2.2.41/32" ];
        }
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05"; # Did you read the comment?
}
