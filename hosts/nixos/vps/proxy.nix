{ config, ... }:

{
  # Traefik dynamic configuration for vps host
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {

        # Photo service (Immich)
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

        # Jellyfin Media Server
        jellyfin = {
          rule = "Host(`jellyfin.yanlincs.com`)";
          service = "jellyfin";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # Deluge torrent client
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

        # Sonarr TV show management
        sonarr = {
          rule = "Host(`sonarr.yanlincs.com`)";
          service = "sonarr";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # Radarr movie management
        radarr = {
          rule = "Host(`radarr.yanlincs.com`)";
          service = "radarr";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # NSFW WebDAV (dufs on thinkpad)
        nsfw = {
          rule = "Host(`nsfw.yanlincs.com`)";
          service = "nsfw";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

      };

      services = {

        # Photo service backend 
        photo = {
          loadBalancer = {
            servers = [{
              url = "http://lan.hs.yanlincs.com:5000";
            }];
          };
        };

        # Jellyfin backend 
        jellyfin = {
          loadBalancer = {
            servers = [{
              url = "http://lan.hs.yanlincs.com:8096";
            }];
          };
        };

        # Deluge backend 
        deluge = {
          loadBalancer = {
            servers = [{
              url = "http://lan.hs.yanlincs.com:8112";
            }];
          };
        };

        # Sonarr backend 
        sonarr = {
          loadBalancer = {
            servers = [{
              url = "http://lan.hs.yanlincs.com:8989";
            }];
          };
        };

        # Radarr backend 
        radarr = {
          loadBalancer = {
            servers = [{
              url = "http://lan.hs.yanlincs.com:7878";
            }];
          };
        };

        # NSFW backend (dufs on thinkpad via WireGuard)
        nsfw = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.30:5099";
            }];
          };
        };

      };

    };
  };
}
