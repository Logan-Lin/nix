# macOS host sakurako.
# It sets its own hostname and otherwise relies entirely on the macOS platform default, without opting into any feature modules.
# Named after 大室櫻子, the energetic and free spirited middle 大室 sister.
# Like her, this host is the lively and restless one, a MacBook Air that is always on the move and never seems to run out of energy.

{ config, pkgs, ... }:

{
  networking.computerName = "sakurako";
  networking.hostName = "sakurako";

  imports = [
    ../system-default.nix
  ];
}
