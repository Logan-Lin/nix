{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media/tool.nix
    ../../../modules/schedule.nix
  ];

  syncthing-custom.folders = {
    Credentials = { enable = true; maxAgeDays = 30; };
    Documents = { enable = true; maxAgeDays = 30; };
    Media = { enable = true; maxAgeDays = 7; };
    Archive = { enable = true; maxAgeDays = 30; };
    DCIM = { enable = true; maxAgeDays = 7; path = "~/DCIM" };
  };
  
  services.scheduled-commands.aicloud-backup = {
    enable = true;
    description = "Backup outputs files on aicloud";
    interval = "*-*-* *:10:00";
    commands = [
      "rsync -avhP aicloud.lan:~/xrd-cond-glass-gen/{outputs,checkpoints,stdout} ~/run/xrd-cond-glass-gen"
      "rsync -avhP aicloud.lan:~/charge-bal/{outputs,checkpoints,stdout} ~/run/charge-bal"
      "rsync -avhP aicloud.lan:~/sr-gen-traj/{outputs,checkpoints,stdout} ~/run/sr-gen-traj"
    ];
  };

}
