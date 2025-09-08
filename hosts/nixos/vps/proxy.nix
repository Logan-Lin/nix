{ config, ... }:

{
  # Traefik dynamic configuration for vps host
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        # Redirect from yanlincs.com to www.yanlincs.com
        homepage-redirect = {
          rule = "Host(`yanlincs.com`)";
          entrypoints = "websecure";
          service = "homepage-redirect";
          middlewares = [ "homepage-redirect" ];
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "yanlincs.com";
              sans = [ "www.yanlincs.com" ];
            }];
          };
        };

        # Photo service (Immich)
        photo = {
          rule = "Host(`photo.yanlincs.com`)";
          entrypoints = "websecure";
          service = "photo";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # Cloud service (Nextcloud)
        cloud = {
          rule = "Host(`cloud.yanlincs.com`)";
          entrypoints = "websecure";
          service = "cloud";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };
      };
      services = {
        # Redirect service
        homepage-redirect = {
          loadBalancer = {
            servers = [{
              url = "http://localhost:1"; # Dummy backend, won't be used due to redirect
            }];
          };
        };

        # Photo service backend
        photo = {
          loadBalancer = {
            servers = [{
              url = "http://hs.yanlincs.com:5000";
            }];
          };
        };

        # Cloud service backend
        cloud = {
          loadBalancer = {
            servers = [{
              url = "http://hs.yanlincs.com:5001";
            }];
          };
        };
      };
      middlewares = {
        # Redirect middleware
        homepage-redirect = {
          redirectRegex = {
            regex = "^https://yanlincs\\.com/(.*)";
            replacement = "https://www.yanlincs.com/$1";
            permanent = true;
          };
        };
      };
    };
  };
}
