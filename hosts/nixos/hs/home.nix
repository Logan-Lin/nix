{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/tex.nix
    ../../../modules/schedule.nix
  ];

  services.scheduled-commands.aicloud-backup = {
    enable = true;
    description = "Backup aicloud files";
    interval = "*-*-* 18:00:00";
    commands = [
      "rsync -avP aicloud:~/ /mnt/storage/Backup/aicloud/ --exclude='/.*'"
    ];
  };

  home.packages = with pkgs; [
  ];
  
}
