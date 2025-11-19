{ config, ... }:

{
  # Traefik dynamic configuration for vps host
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {

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

        # Sonarr TV show management
        sonarr = {
          rule = "Host(`sonarr.yanlincs.com`)";
          entrypoints = "websecure";
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
          entrypoints = "websecure";
          service = "radarr";
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
          entrypoints = "websecure";
          service = "jellyfin";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # Plex Media Server
        plex = {
          rule = "Host(`plex.yanlincs.com`)";
          entrypoints = "websecure";
          service = "plex";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # qBittorrent torrent client
        qbit = {
          rule = "Host(`qbit.yanlincs.com`)";
          entrypoints = "websecure";
          service = "qbit";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # Dufs file server
        files = {
          rule = "Host(`files.yanlincs.com`)";
          entrypoints = "websecure";
          service = "files";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

      };
      services = {

        # Photo service backend (via WireGuard)
        photo = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5000";
            }];
          };
        };

        # Sonarr backend (via WireGuard)
        sonarr = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5003";
            }];
          };
        };

        # Radarr backend (via WireGuard)
        radarr = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5004";
            }];
          };
        };

        # Jellyfin backend (via WireGuard)
        jellyfin = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5002";
            }];
          };
        };

        # Plex backend (via WireGuard)
        plex = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5008";
            }];
          };
        };

        # qBittorrent backend (via WireGuard)
        qbit = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:8080";
            }];
          };
        };

        # Dufs backend (via WireGuard)
        files = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5099";
            }];
          };
        };

      };

      middlewares = { };
    };
  };
}
