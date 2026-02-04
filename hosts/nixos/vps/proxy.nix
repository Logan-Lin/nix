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

        tv = {
          rule = "Host(`tv.yanlincs.com`)";
          service = "tv";
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

        tv = {
          loadBalancer = {
            servers = [{
              url = "http://nfss.yanlincs.com:32400";
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
