# macOS host himawari.
# It sets its own hostname and otherwise relies entirely on the macOS platform default, without opting into any feature modules.

{ config, pkgs, ... }:

{
  networking.computerName = "himawari";
  networking.hostName = "himawari";

  imports = [
    ../system-default.nix
  ];
}
