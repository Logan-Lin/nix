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

        # qBittorrent torrent client
        qbit = {
          rule = "Host(`qbit.yanlincs.com`)";
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
          service = "files";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # Linkding bookmark manager
        link = {
          rule = "Host(`link.yanlincs.com`)";
          service = "link";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # Navidrome music server
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

        # Photo service backend (via WireGuard)
        photo = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5000";
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

        # Linkding backend (via WireGuard)
        link = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5009";
            }];
          };
        };

        # Navidrome backend (via WireGuard)
        music = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5005";
            }];
          };
        };

      };

    };
  };
}
