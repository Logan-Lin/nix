{ config, ... }:

{
  # Traefik dynamic configuration for vps host
  services.traefik.dynamic.files."proxy".settings = {
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

      };

      services = {

        photo = {
          loadBalancer = {
            servers = [{
              url = "http://nfss.yanlincs.com:8080";
            }];
            serversTransport = "longTimeout@file";
          };
        };

      };

    };

  };
}
