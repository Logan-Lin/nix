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
    Consume = { enable = true; maxAgeDays = 7; };
  };

  services.scheduled-commands.dcim-consume = {
    enable = false;
    description = "Move files in dcim consume folder to DCIM";
    interval = "*-*-* *:00/15:00";
    commands = [
      "photo-move -d /home/yanlin/Consume/dcim /mnt/essd/DCIM"
    ];
  };

}
