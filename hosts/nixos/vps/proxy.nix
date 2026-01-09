{ config, ... }:

{
  # Traefik dynamic configuration for vps host
  services.traefik.dynamicConfigOptions = {
    http = {
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

        file = {
          rule = "Host(`file.yanlincs.com`)";
          service = "file";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        deluge = {
          rule = "Host(`deluge.yanlincs.com`)";
          service = "file";
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
          };
        };

        file = {
          loadBalancer = {
            servers = [{
              url = "http://thinkpad.yanlincs.com:5099";
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
  };
}
