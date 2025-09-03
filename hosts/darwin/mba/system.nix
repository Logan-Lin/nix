{ config, pkgs, ... }:

{
  # MacBook Air-specific configuration
  networking.computerName = "mba";
  networking.hostName = "mba";
  
  # Import common Darwin configuration
  imports = [
    ../system-default.nix
  ];
}
