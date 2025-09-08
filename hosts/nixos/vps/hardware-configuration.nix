# Hardware configuration for VPS
# This is a generic configuration suitable for most VPS providers

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # Boot configuration - common kernel modules for VPS environments
  boot.initrd.availableKernelModules = [ 
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
    "virtio_blk"
    "virtio_net"
    "xen_blkfront"
    "xen_netfront"
  ];
  boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Filesystems are managed by disko configuration
  # No filesystem declarations needed here

  # No swap devices configured here - handled by disko

  # Networking hardware
  networking.useDHCP = lib.mkDefault true;

  # Hardware-specific settings
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
  # Enable firmware updates
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}