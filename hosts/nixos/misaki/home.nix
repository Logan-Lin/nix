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
  ];

  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/agent/claude.nix
  ];

  syncthing-custom.folders = {
    Documents = { enable = true; maxAgeDays = 30; };
  };
}
