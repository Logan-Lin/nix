{ config, pkgs, ... }:

{
  # MacBook Air-specific configuration
  networking.computerName = "imac";
  networking.hostName = "imac";
  
  # Import common Darwin configuration
  imports = [
    ../system-default.nix
  ];
}
