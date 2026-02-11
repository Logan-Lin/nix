{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media/tool.nix
    ../../../modules/schedule.nix
  ];

  services.scheduled-commands.dcim-consume = {
    enable = true;
    description = "Move files in dcim consume folder to DCIM";
    interval = "*-*-* *:00/15:00";
    commands = [
      "photo-move -d /home/yanlin/Media/dcim-consume /home/yanlin/DCIM"
    ];
  };

}
