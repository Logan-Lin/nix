# Deluge torrent daemon with its web UI, wrapped behind the services.deluge-custom options interface.
# A host enables the service and sets downloadDir, and the module configures the upstream services.deluge module in declarative mode.

# NOTE: auth file at: `/var/lib/deluge/auth` with owner `yanlin:users` and mode 600
# content:
#   localclient:<password>:10

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.deluge-custom;

  stable = import inputs.nixpkgs-stable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in

{
  options.services.deluge-custom = {
    enable = mkEnableOption "Deluge torrent service";

    downloadDir = mkOption {
      type = types.str;
      description = "Directory for downloaded files";
    };

    listenPort = mkOption {
      type = types.port;
      default = 25000;
      description = "Port for incoming peer connections";
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
      # Source Deluge from stable nixpkgs because the unstable package is missing pkg_resources and fails to start.
      package = stable.deluge-2_x;
      user = "yanlin";
      group = "users";
      declarative = true;
      authFile = "/var/lib/deluge/auth";
      openFirewall = true;

      config = {
        download_location = cfg.downloadDir;
        allow_remote = false;
        daemon_port = 58846;

        random_port = false;
        listen_ports = [ cfg.listenPort cfg.listenPort ];
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
