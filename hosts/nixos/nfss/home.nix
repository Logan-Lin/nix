{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media/tool.nix
    ../../../modules/media/yt-dlp.nix
    ../../../modules/terminal/claude.nix
  ];

  syncthing-custom.folders = {
    Credentials = { enable = true; maxAgeDays = 30; };
    Documents = { enable = true; maxAgeDays = 30; };
    Media = { enable = true; maxAgeDays = 7; };
    Archive = { enable = true; maxAgeDays = 30; };
  };

  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "~/Media";
  };

}
