{ config, pkgs, ... }:

{
  networking.computerName = "himawari";
  networking.hostName = "himawari";

  imports = [
    ../system-default.nix
  ];
}
