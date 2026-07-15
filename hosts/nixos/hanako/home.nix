# Home-manager configuration for hanako, a NixOS host.
# It carries no settings of its own and relies entirely on the NixOS platform default.

{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
  ];
}
