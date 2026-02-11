{ config, pkgs, ... }:

{
  networking.computerName = "macbook";
  networking.hostName = "macbook";

  imports = [
    ../system-default.nix
  ];
}
