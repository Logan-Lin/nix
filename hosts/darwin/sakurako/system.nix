# macOS host sakurako.
# It sets its own hostname and otherwise relies entirely on the macOS platform default, without opting into any feature modules.

{ config, pkgs, ... }:

{
  networking.computerName = "sakurako";
  networking.hostName = "sakurako";

  imports = [
    ../system-default.nix
  ];
}
