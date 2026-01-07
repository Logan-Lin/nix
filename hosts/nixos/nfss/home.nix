{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/tex.nix
    ../../../modules/schedule.nix
  ];

  home.packages = with pkgs; [
  ];

}
