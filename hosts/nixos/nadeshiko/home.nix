{ config, pkgs, inputs, ... }:

let
  stable = import inputs.nixpkgs-stable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  home.packages = with pkgs; [
    httpie
    stable.texliveFull
    ffmpeg
    imagemagick

    keepassxc
    ungoogled-chromium
    thunderbird
    clash-verge-rev
    obsidian
    pdfpc
    drawio
    inkscape
  ];

  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/agent/claude.nix
    ../../../modules/ghostty.nix
    ../../../modules/librewolf.nix
    ../../../modules/vscodium.nix
    ../../../modules/hyprland/home.nix
  ];

  programs.ghostty-custom = {
    enable = true;
    package = pkgs.ghostty;
    fontSize = 11;
  };

  programs.librewolf-custom = {
    enable = true;
    package = pkgs.librewolf;
  };

  programs.vscodium-custom = {
    enable = true;
    package = pkgs.vscodium;
  };

  programs.hyprlock.settings.auth.fingerprint.enabled = true;

  syncthing-custom.folders = {
    Documents = { enable = true; };
    Downloads = { enable = true; };
  };
}
