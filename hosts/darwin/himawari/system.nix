# macOS host himawari.
# It sets its own hostname and otherwise relies entirely on the macOS platform default, without opting into any feature modules.
# Named after 古谷向日葵, 大室櫻子's childhood friend and constant rival.
# This host pairs with sakurako the way the two characters are inseparable, and like Himawari it is the calmer and more capable of the pair, a stationary iMac that quietly gets things done.

{ config, pkgs, ... }:

{
  networking.computerName = "himawari";
  networking.hostName = "himawari";

  imports = [
    ../system-default.nix
  ];
}
