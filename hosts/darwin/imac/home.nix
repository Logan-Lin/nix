{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
  ];

  tunnel.services = [ "Wi-Fi" "Ethernet" ];
}
