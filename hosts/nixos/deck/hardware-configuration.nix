# Placeholder hardware configuration for Steam Deck
#
# This file must be generated on the actual Steam Deck hardware.
#
# To generate this file:
# 1. Boot into the Jovian-NixOS installer ISO on the Steam Deck
# 2. Run: nixos-generate-config --root /mnt --show-hardware-config > hardware-configuration.nix
# 3. Copy the generated file to this location
#
# The generated file will include:
# - CPU and GPU detection
# - Storage device configuration
# - Kernel modules for Steam Deck hardware
# - File system configuration
#
# DO NOT attempt to use this placeholder for installation.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Placeholder - will be replaced by actual hardware detection
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Placeholder filesystem configuration
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
