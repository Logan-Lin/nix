{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
  ];

  syncthing-custom = {
    enabledFolders = [ "Credentials" ];
    enableGui = false;
  };
}
