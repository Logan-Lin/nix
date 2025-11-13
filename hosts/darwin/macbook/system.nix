{ config, pkgs, ... }:

{
  # MacBook-specific configuration
  networking.computerName = "macbook";
  networking.hostName = "macbook";

  # Import common Darwin configuration
  imports = [
    ../system-default.nix
  ];
}
