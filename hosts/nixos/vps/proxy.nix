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

      };

      services = {

        photo = {
          loadBalancer = {
            serversTransport = "longTimeout";
            servers = [{
              url = "http://10.1.1.152:8080";
            }];
          };
        };

        music = {
          loadBalancer = {
            servers = [{
              url = "http://10.1.1.152:4533";
            }];
          };
        };

      };

    };

  };
}
