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
    ../../../modules/claude.nix
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
      "rsync -avhP --delete --mkpath aicloud.lan:~/{.zshrc,.gitconfig,.ssh,.config,.local} /mnt/storage/backup/aicloud-home/"
      "rsync -avhP --delete aicloud.lan:~/inv-am-bench /mnt/storage/backup/"
      "rsync -avhP --delete aicloud.lan:~/agent-inv-am /mnt/storage/backup/"
      "rsync -avhP --delete aicloud.lan:~/agent-am-sci /mnt/storage/backup/"
    ];
  };

}
