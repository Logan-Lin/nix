{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media/tool.nix
  ];

  syncthing-custom.folders = {
    Credentials.maxAgeDays = 30;
    Documents.maxAgeDays = 30;
    Media.maxAgeDays = 7;
    Archive.maxAgeDays = 30;
  };

}
