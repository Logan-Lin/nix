{ config, lib, ... }:

let
  cfg = config.services.miniflux-custom;
in
{
  options.services.miniflux-custom = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8070;
      description = "Port for Miniflux to listen on";
    };
  };

  config = {
    services.miniflux = {
      enable = true;
      adminCredentialsFile = "/etc/miniflux-admin-credentials";
      config = {
        LISTEN_ADDR = "0.0.0.0:${toString cfg.port}";
        BASE_URL = "https://rss.yanlincs.com";
      };
    };
  };
}
