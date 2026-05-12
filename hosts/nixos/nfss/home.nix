{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    texlive.combined.scheme-full
    httpie
  ];

  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media-tool.nix
    ../../../modules/terminal/claude.nix
    ../../../modules/schedule.nix
  ];

  syncthing-custom.folders = {
    Documents = { enable = true; maxAgeDays = 30; };
  };

  services.scheduled-commands.aicloud-backup = {
    enable = true;
    description = "Backup files on aicloud";
    interval = "*-*-* *:10:00";
    commands = [
      "rsync -avhP --mkpath aicloud.lan:~/{.zshrc,.gitconfig,.ssh,.config,.local} /mnt/storage/backup/aicloud-home/"
      "rsync -avhP aicloud.lan:~/xrd-cond-glass-gen /mnt/storage/backup/"
      "rsync -avhP aicloud.lan:~/charge-bal /mnt/storage/backup/"
      "rsync -avhP aicloud.lan:~/sr-gen-traj /mnt/storage/backup/"
      "rsync -avhP aicloud.lan:~/sim-mat-gen /mnt/storage/backup/"
    ];
  };

}
