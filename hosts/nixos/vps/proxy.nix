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

        api_test_server = {
          rule = "Host(`api.yanlincs.com`)";
          entrypoints = "websecure";
          service = "api_test_server";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
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

        # Paperless document management
        paperless = {
          rule = "Host(`paperless.yanlincs.com`)";
          entrypoints = "websecure";
          service = "paperless";
          tls = {
            certResolver = "cloudflare";
            domains = [{
              main = "*.yanlincs.com";
            }];
          };
        };

        # RSS reader (Miniflux)
        rss = {
          rule = "Host(`rss.yanlincs.com`)";
          entrypoints = "websecure";
          service = "rss";
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
          entrypoints = "websecure";
          service = "link";
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

        # WebDAV file server
        # files = {
        #   rule = "Host(`files.yanlincs.com`)";
        #   entrypoints = "websecure";
        #   service = "files";
        #   tls = {
        #     certResolver = "cloudflare";
        #     domains = [{
        #       main = "*.yanlincs.com";
        #     }];
        #   };
        # };
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

        api_test_server = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.30:8000";
            }];
          };
        };

        # Photo service backend (via WireGuard)
        photo = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5000";
            }];
          };
        };

        # Cloud service backend (via WireGuard)
        cloud = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5001";
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

        # Paperless backend (via WireGuard)
        paperless = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5005";
            }];
          };
        };

        # RSS reader backend (via WireGuard)
        rss = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5006";
            }];
          };
        };

        # Linkding backend (via WireGuard)
        link = {
          loadBalancer = {
            servers = [{
              url = "http://10.2.2.20:5007";
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

        # WebDAV file server backend (via WireGuard)
        # files = {
        #   loadBalancer = {
        #     servers = [{
        #       url = "http://10.2.2.20:5009";
        #     }];
        #   };
        # };
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
