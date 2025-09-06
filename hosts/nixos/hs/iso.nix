{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    # Use the ISO image generator
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    
    # Include your disk configuration so disko is available
    ./disk-config.nix
  ];

  # Override ISO settings
  image.baseName = lib.mkForce "nixos-hs";
  isoImage.volumeID = lib.mkForce "NIXOS_HS";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  # Enable SSH in the installer for remote installation
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true; # Allow password for initial connection
    };
    openFirewall = true;
  };

  # Set a known root password for the installer
  # You should change this immediately after installation
  users.users.root.initialPassword = "nixos";

  # Include your SSH key for passwordless access
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG35m0DgTrEOAM+1wAlYZ8mvLelNTcx65cFccGPQcxmo yanlin@imac"
  ];

  # Networking
  networking = {
    useDHCP = lib.mkForce true;
    hostName = "nixos-installer";
    wireless.enable = false; # Disable wireless if not needed
    networkmanager.enable = lib.mkForce false; # Disable NetworkManager in installer
  };

  # Include essential tools for installation
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    rsync
    gptfdisk
    disko
    # ZFS tools
    zfs
  ];

  # Enable ZFS support in the installer
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Make sure we have network access
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

  # Add a helpful message
  services.getty.helpLine = ''

    The NixOS installer for host 'hs' has been started.
    
    SSH is enabled. Default root password is: nixos
    SSH keys for yanlin@imac are already authorized.
    
    To install:
    1. Change root password: passwd
    2. Run disko to partition: disko --mode disko /etc/nixos/disk-config.nix
    3. Install NixOS: nixos-install --flake github:YOUR_USERNAME/YOUR_REPO#hs
    
  '';

  # Ensure the installer has enough memory
  boot.kernelParams = [ "copytoram" ];

  # Include the disk configuration in the ISO
  environment.etc."nixos/disk-config.nix".source = ./disk-config.nix;
}