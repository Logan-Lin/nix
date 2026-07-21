# Home-manager configuration for nadeshiko.
# This host acts as a backup target for the remote aicloud server.
# Every hour it pulls the server's home directory files and several project directories into local storage under /mnt/storage.

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    texliveFull
    httpie
  ];

  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media-tool.nix
    ../../../modules/agent/claude.nix
    ../../../modules/agent/codex.nix
    ../../../modules/schedule.nix
  ];

  syncthing-custom.folders = {
    Documents = { enable = true; maxAgeDays = 30; };
  };

  services.scheduled-commands.aicloud-backup = {
    enable = true;
    description = "Backup files on aicloud";
    # Runs at ten minutes past every hour.
    interval = "*-*-* *:10:00";
    commands = [
      "rsync -avhP --delete --mkpath aicloud:~/{.zshrc,.gitconfig,.ssh,.config,.local} /mnt/storage/backup/aicloud-home/"
      "rsync -avhP --delete aicloud:~/inv-am-bench /mnt/storage/backup/"
      "rsync -avhP --delete aicloud:~/agent-inv-am /mnt/storage/backup/"
      "rsync -avhP --delete aicloud:~/agent-am-sci /mnt/storage/backup/"
    ];
  };

}
