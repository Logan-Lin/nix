{ config, pkgs, ... }:

{
  # MacBook Air-specific configuration
  networking.computerName = "MacBook-Air";
  networking.hostName = "MacBook-Air";
  
  # Import common Darwin configuration
  imports = [
    ../system-default.nix
  ];
}
