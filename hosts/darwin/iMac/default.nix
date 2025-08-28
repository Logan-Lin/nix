{ config, pkgs, ... }:

{
  # iMac-specific configuration
  networking.computerName = "iMac";
  networking.hostName = "iMac";
  
  # Import common Darwin configuration
  imports = [
    ../../../system
  ];
}