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
    ../../../modules/ntfy.nix
  ];

  # GRUB bootloader with UEFI support
  boot.loader.grub = {
    enable = true;
    device = "nodev"; # Required for EFI systems
    efiSupport = true;
    efiInstallAsRemovable = true; # Better compatibility with VPS
    configurationLimit = 5; # Keep only 5 boot entries to save storage
  };

  # Automatic garbage collection to save storage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Automatic store optimization to deduplicate files
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # Network configuration
  networking = {
    hostName = "vps";
    hostId = "a8c06f42"; # Required for some services, generated randomly
    networkmanager.enable = false; # Use systemd-networkd for VPS
    useDHCP = true; # VPS typically use DHCP
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 22000 ];
      allowedUDPPorts = [ 22000 ];
      trustedInterfaces = [ "tailscale0" ];
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

  # Borg backup configuration
  services.borg-client-custom = {
    enable = true;
    # Use SSH alias from SSH config for remote backup to thinkpad borg server
    repositoryUrl = "ssh://hs@borg-thinkpad/./vps";
    backupPaths = [
      "/home"
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

    preHook = ''
      echo "$(date): Starting Borg backup of ${config.networking.hostName}"
    '';
    postHook = ''
      echo "$(date): Borg backup of ${config.networking.hostName} completed successfully"
    '';
  };

  services.login-display = {
    enable = true;
    showSystemInfo = true;
    showSmartStatus = false;
    showDiskUsage = true;
    showBorgStatus = true;
  };

  services.tailscale-custom.exitNode = true;

}
