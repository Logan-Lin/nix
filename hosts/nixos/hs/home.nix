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

  services.scheduled-commands.backup-to-thinkpad = {
    enable = true;
    description = "Backup files to thinkpad";
    interval = "*-*-* 00:00:00";
    commands = [
      "rsync-backup /mnt/storage/appbulk/immich/library/admin thinkpad:~/Backup/photos/immich-library"
      "rsync-backup /mnt/storage/Media/DCIM thinkpad:~/Backup/photos/DCIM"
      "rsync-backup /mnt/storage/Media/nsfw thinkpad:~/Backup/nsfw"
    ];
  };
  
  home.packages = with pkgs; [
  ];
  
}
