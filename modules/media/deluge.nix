{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.deluge-custom;
in

{
  options.services.deluge-custom = {
    enable = mkEnableOption "Deluge torrent service";

    downloadDir = mkOption {
      type = types.str;
      description = "Directory for downloaded files";
    };

    webPort = mkOption {
      type = types.port;
      default = 8112;
      description = "Port for the Deluge web UI";
    };
  };

  config = mkIf cfg.enable {
    services.deluge = {
      enable = true;
      user = "yanlin";
      group = "users";
      declarative = true;
      authFile = pkgs.writeText "deluge-auth" "localclient:deluge:10";
      openFirewall = false;

      config = {
        download_location = cfg.downloadDir;
        allow_remote = false;
        daemon_port = 58846;

        random_port = false;
        listen_ports = [ 25000 25000 ];
        outgoing_ports = [ 0 0 ];
        random_outgoing_ports = true;
        upnp = true;
        natpmp = true;
        utpex = true;
        lsd = true;
        dht = true;
        peer_tos = "0x00";

        max_connections_global = -1;
        max_upload_slots_global = -1;
        max_download_speed = (-1.0);
        max_upload_speed = (-1.0);
        max_half_open_connections = -1;
        max_connections_per_second = -1;
        ignore_limits_on_local_network = true;
        rate_limit_ip_overhead = true;
        max_connections_per_torrent = -1;
        max_upload_slots_per_torrent = -1;
        max_download_speed_per_torrent = -1;
        max_upload_speed_per_torrent = -1;

        queue_new_to_top = false;
        max_active_limit = -1;
        max_active_downloading = 10;
        max_active_seeding = -1;
        dont_count_slow_torrents = false;
        auto_manage_prefer_seeds = false;
        stop_seed_at_ratio = false;
        stop_seed_ratio = 2.0;
        remove_seed_at_ratio = false;
        share_ratio_limit = (-1.0);
        seed_time_ratio_limit = (-1.0);
        seed_time_limit = -1;

        enabled_plugins = [ "Label" ];
      };

      web = {
        enable = true;
        port = cfg.webPort;
        openFirewall = false;
      };
    };
  };
}
