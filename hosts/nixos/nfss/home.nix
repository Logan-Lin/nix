{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/tex.nix
    ../../../modules/syncthing.nix
    ../../../modules/schedule.nix
    ../../../modules/yt-dlp.nix
  ];

  home.packages = with pkgs; [
  ];

  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "/home/yanlin/Downloads";
  };

}
