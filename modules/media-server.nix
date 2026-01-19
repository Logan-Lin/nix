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
    plex.enable = lib.mkEnableOption "Plex media server"; # port 32400
    lidarr.enable = lib.mkEnableOption "Lidarr music management"; # port 8686
    bazarr.enable = lib.mkEnableOption "Bazarr subtitle management"; # port 6767
    audiobookshelf.enable = lib.mkEnableOption "Audiobookshelf audiobook server"; # port 8000
    navidrome.enable = lib.mkEnableOption "Navidrome music server"; # port 4533
    navidrome.musicFolder = lib.mkOption {
      type = lib.types.str;
      default = "/home/Media/music";
      description = "Path to music folder for Navidrome";
    };
  };

  config = {
    users.users.${cfg.user}.extraGroups = lib.mkIf cfg.jellyfin.enable [ "render" "video" ];

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

    systemd.services.jellyfin.environment = lib.mkIf cfg.jellyfin.enable {
      LIBVA_DRIVER_NAME = "iHD";
    };

    services.deluge = lib.mkIf cfg.deluge.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
      web.enable = true;
      web.openFirewall = false;
    };

    services.plex = lib.mkIf cfg.plex.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
    };

    services.lidarr = lib.mkIf cfg.lidarr.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
    };

    services.bazarr = lib.mkIf cfg.bazarr.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
    };

    services.audiobookshelf = lib.mkIf cfg.audiobookshelf.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      host = "0.0.0.0";
      openFirewall = false;
    };

    services.navidrome = lib.mkIf cfg.navidrome.enable {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openFirewall = false;
      settings = {
        MusicFolder = cfg.navidrome.musicFolder;
      };
    };

    systemd.services.navidrome.serviceConfig = lib.mkIf cfg.navidrome.enable {
      ProtectHome = lib.mkForce false;
    };
  };
}
