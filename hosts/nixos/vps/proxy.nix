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
          };
        };

        audio = {
          loadBalancer = {
            servers = [{
              url = "http://nfss.yanlincs.com:8000";
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
