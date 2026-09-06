# Home-manager configuration for misaki, a personal NixOS workstation running the Hyprland Wayland desktop.

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    httpie

    obsidian
    keepassxc
    drawio
    inkscape
    localsend
    clash-verge-rev
    pdfpc
  ];

  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media-tool.nix
    ../../../modules/agent/claude.nix
    ../../../modules/ghostty.nix
    ../../../modules/firefox.nix
    ../../../modules/hyprland/home.nix
    ../../../modules/texlive.nix
  ];

  programs.firefox-custom = {
    enable = true;
    package = pkgs.firefox;
  };

  programs.ghostty-custom = {
    enable = true;
    package = pkgs.ghostty;
    fontSize = 11;
  };

  syncthing-custom.folders = {
    Documents = { enable = true; maxAgeDays = 30; };
  };
}
