{ config, ... }:

{
  # Traefik dynamic configuration for hs host
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        syncthing = {
          rule = "Host(`syncthing.${config.networking.hostName}.yanlincs.com`)";
          service = "syncthing";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.${config.networking.hostName}.yanlincs.com";
            }];
          };
        };

        jellyfin = {
          rule = "Host(`jellyfin.${config.networking.hostName}.yanlincs.com`)";
          service = "jellyfin";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.${config.networking.hostName}.yanlincs.com";
            }];
          };
        };

      };

      services = {
        syncthing = {
          loadBalancer = {
            servers = [{
              url = "http://127.0.0.1:8384";
            }];
          };
        };

        jellyfin = {
          loadBalancer = {
            servers = [{
              url = "http://127.0.0.1:8096";
            }];
          };
        };

      };
    };
  };
}
