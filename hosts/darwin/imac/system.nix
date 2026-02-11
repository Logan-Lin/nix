{ config, pkgs, ... }:

{
  networking.computerName = "imac";
  networking.hostName = "imac";

  imports = [
    ../system-default.nix
  ];
}
