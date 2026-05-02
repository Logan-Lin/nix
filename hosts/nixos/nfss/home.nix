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
    Credentials = { enable = true; maxAgeDays = 30; };
    Documents = { enable = true; maxAgeDays = 30; };
    Media = { enable = true; maxAgeDays = 7; };
    Archive = { enable = true; maxAgeDays = 30; };
    Share = { enable = true; maxAgeDays = 7; };
  };

  services.scheduled-commands.aicloud-backup = {
    enable = true;
    description = "Backup files on aicloud";
    interval = "*-*-* *:10:00";
    commands = [
      "rsync -avhP aicloud.lan:~/xrd-cond-glass-gen /mnt/storage/run/"
      "rsync -avhP aicloud.lan:~/charge-bal /mnt/storage/run/"
      "rsync -avhP aicloud.lan:~/sr-gen-traj /mnt/storage/run/"
    ];
  };

}
