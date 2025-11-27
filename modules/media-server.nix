{ config, pkgs, lib, ... }:

let
  cfg = config.services.media-server;
in
{
  options.services.media-server = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "media";
      description = "User to run media services";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group for media services";
    };

    sonarr.enable = lib.mkEnableOption "Sonarr TV show management"; # port 8989
    radarr.enable = lib.mkEnableOption "Radarr movie management"; # port 7878
    jellyfin.enable = lib.mkEnableOption "Jellyfin media server"; # port 8096
    deluge.enable = lib.mkEnableOption "Deluge torrent client"; # web port 8112
  };

  config = {
    services.sonarr = lib.mkIf cfg.sonarr.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
    };

    services.radarr = lib.mkIf cfg.radarr.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
    };

    services.jellyfin = lib.mkIf cfg.jellyfin.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
    };

    services.deluge = lib.mkIf cfg.deluge.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
      web.enable = true;
      web.openFirewall = false;
    };
  };
}
