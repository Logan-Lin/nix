{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./containers.nix  # Host-specific container definitions
    ./proxy.nix       # Host-specific Traefik dynamic configuration
    ../system-default.nix  # Common NixOS system configuration
    ../../../modules/wireguard.nix
    ../../../modules/podman.nix
    ../../../modules/traefik.nix
    ../../../modules/borg-client.nix
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


  # Host-specific SSH configuration
  services.openssh = {
    settings = {
      PermitRootLogin = "prohibit-password"; # Allow key-based root login for nixos-anywhere
    };
  };

  # Root user configuration (for nixos-anywhere initial access)
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVvviqbwBEGDIbAUnmgHQJi+N5Qfvo5u49biWl6R7oC yanlin@MacBook-Air"
    ];
  };

  # Host-specific user configuration
  users.users.yanlin = {
    extraGroups = [ "wheel" ]; # Enable sudo
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVvviqbwBEGDIbAUnmgHQJi+N5Qfvo5u49biWl6R7oC yanlin@MacBook-Air"
    ];
  };


  # No additional host-specific packages needed


  # Borg backup configuration
  services.borgbackup-custom = {
    enable = true;
    # Use SSH alias from SSH config for remote backup to thinkpad borg server
    repositoryUrl = "ssh://borg-backup/./vps";
    backupPaths = [
      "/home"
      "/var/lib/containers"
      "/etc"
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
          name = "thinkpad";
          publicKey = "p3442J2HBGY5Pksu+0F4SFkBGjG99KIgwyk8eAt4YmA=";
          allowedIPs = [ "10.2.2.30/32" ];
        }
      ];
    };
  };

}
