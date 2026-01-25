{ config, ... }:

{
  # Traefik dynamic configuration for vps host
  services.traefik.dynamicConfigOptions = {
    http = {
      serversTransports = {
        longTimeout = {
          forwardingTimeouts = {
            dialTimeout = "30s";
            responseHeaderTimeout = "1200s";
            idleConnTimeout = "1200s";
          };
        };
      };

      routers = {

        photo = {
          rule = "Host(`photo.yanlincs.com`)";
          service = "photo";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        immich-lib = {
          rule = "Host(`immich-lib.yanlincs.com`)";
          service = "immich-lib";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        audio = {
          rule = "Host(`audio.yanlincs.com`)";
          service = "audio";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        music = {
          rule = "Host(`music.yanlincs.com`)";
          service = "music";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        deluge = {
          rule = "Host(`deluge.yanlincs.com`)";
          service = "deluge";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

      };

      services = {

        photo = {
          loadBalancer = {
            servers = [{
              url = "http://thinkpad.yanlincs.com:5000";
            }];
            serversTransport = "longTimeout@file";
          };
        };

        immich-lib = {
          loadBalancer = {
            servers = [{
              url = "http://thinkpad.yanlincs.com:5099";
            }];
            serversTransport = "longTimeout@file";
          };
        };

        audio = {
          loadBalancer = {
            servers = [{
              url = "http://nfss.yanlincs.com:8000";
            }];
          };
        };

        music = {
          loadBalancer = {
            servers = [{
              url = "http://nfss.yanlincs.com:4533";
            }];
          };
        };

        deluge = {
          loadBalancer = {
            servers = [{
              url = "http://nfss.yanlincs.com:8112";
            }];
          };
        };

      };

    };

    tcp = {
      routers.mongodb = {
        rule = "HostSNI(`mongodb.yanlincs.com`)";
        service = "mongodb";
        entrypoints = [ "mongodb" ];
        tls = {
          certResolver = "cloudflare";
          domains = [{ main = "*.yanlincs.com"; }];
        };
      };
      services.mongodb = {
        loadBalancer.servers = [{ address = "nfss.yanlincs.com:27017"; }];
      };
    };

  };
}
