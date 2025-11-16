# PLACEHOLDER hardware configuration for Jetson Orin Nano
# This file should be regenerated on the actual device by running:
#   nixos-generate-config --root /mnt
# Then copy the generated hardware-configuration.nix to this location.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # These are placeholder kernel modules - will be auto-detected by nixos-generate-config
  boot.initrd.availableKernelModules = [ "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Filesystems are managed by disko configuration
  # No filesystem declarations needed here

  # Enable DHCP on network interfaces
  networking.useDHCP = lib.mkDefault true;

  # ARM64 platform for Jetson Orin Nano
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
