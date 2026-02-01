{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/yt-dlp.nix
  ];

  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "~/Downloads";
  };
}
