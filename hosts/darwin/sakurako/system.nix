{ config, pkgs, ... }:

{
  networking.computerName = "sakurako";
  networking.hostName = "sakurako";

  imports = [
    ../system-default.nix
  ];
}
