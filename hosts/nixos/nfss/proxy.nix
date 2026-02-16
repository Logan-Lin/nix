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

        deluge = {
          rule = "Host(`deluge.home.yanlincs.com`)";
          service = "deluge";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.home.yanlincs.com";
            }];
          };
        };

        photo = {
          rule = "Host(`photo.home.yanlincs.com`)";
          service = "photo";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.home.yanlincs.com";
            }];
          };
        };

      };

      services = {

        deluge = {
          loadBalancer = {
            servers = [{
              url = "http://127.0.0.1:8112";
            }];
          };
        };

        photo = {
          loadBalancer = {
            serversTransport = "longTimeout";
            servers = [{
              url = "http://127.0.0.1:8080";
            }];
          };
        };

      };

    };

  };
}
