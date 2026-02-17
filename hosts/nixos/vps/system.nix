{ config, pkgs, ... }: 

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ./proxy.nix
    ../system-default.nix
    ../../../modules/vpn/tailscale.nix
    ../../../modules/podman.nix
    ../../../modules/traefik.nix
    ../../../modules/borg/client.nix
    ../../../modules/git/server.nix
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
      allowedTCPPorts = [ 22 80 443 27017 ];
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

  services.tailscale-custom.exitNode = true;

  services.git-server-custom = {
    enable = true;
    domain = "git.yanlincs.com";
  };

  # Borg backup configuration
  services.borg-client-custom = {
    enable = true;
    repositoryUrl = "ssh://helsinki-box/./vps";
    backupPaths = [
      "/var/lib/mongodb"
      "/var/lib/forgejo"
    ];
    backupFrequency = "*-*-* 03:00:00";
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
  };

}
