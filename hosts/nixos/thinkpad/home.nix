{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    texlive.combined.scheme-full
    httpie
  ];

  imports = [
    ../home-default.nix
    ../../../modules/media-tool.nix
    ../../../modules/terminal/claude.nix
  ];
}
