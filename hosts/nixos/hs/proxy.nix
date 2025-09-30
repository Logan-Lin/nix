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

      };

      services = {
        syncthing = {
          loadBalancer = {
            servers = [{
              url = "http://localhost:8384";
            }];
          };
        };

      };
    };
  };
}
