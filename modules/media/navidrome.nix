{ config, lib, ... }:

let
  cfg = config.services.navidrome-custom;
in
{
  options.services.navidrome-custom = {
    enable = lib.mkEnableOption "Navidrome music server";

    musicDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/yanlin/Media/music";
      description = "Directory containing the music library.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4533;
      description = "Port for the Navidrome web UI / API.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.navidrome = {
      enable = true;
      user = "yanlin";
      group = "users";
      openFirewall = false;
      settings = {
        MusicFolder = cfg.musicDir;
        Address = "0.0.0.0";
        Port = cfg.port;
        EnableExternalServices = false;
        EnableInsightsCollector = false;
      };
    };

    systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce false;
  };
}
