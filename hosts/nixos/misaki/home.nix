{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    texlive.combined.scheme-full
    httpie
  ];

  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media-tool.nix
    ../../../modules/claude.nix
  ];

  syncthing-custom.folders = {
    Documents = { enable = true; maxAgeDays = 30; };
  };
}
