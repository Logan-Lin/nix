{ config, pkgs, lib, ... }:

{
  # Traefik reverse proxy service
  services.traefik = {
    enable = true;
    
    # Static configuration
    staticConfigOptions = {
      # Entry points for HTTP and HTTPS
      entrypoints = {
        web = {
          address = ":80";
          http.redirections.entrypoint = {
            to = "websecure";
            scheme = "https";
            permanent = true;
          };
        };
        websecure = {
          address = ":443";
        };
      };

      # Certificate resolver using Cloudflare DNS challenge
      certificatesResolvers.cloudflare = {
        acme = {
          email = "cloudflare@yanlincs.com";
          storage = "/var/lib/traefik/acme.json";
          dnsChallenge = {
            provider = "cloudflare";
            delayBeforeCheck = 60;
            resolvers = [
              "1.1.1.1:53"
              "8.8.8.8:53"
            ];
          };
        };
      };

      # API and dashboard
      api = {
        dashboard = true;
        debug = false;
      };

      # Logging
      log = {
        level = "INFO";
      };
      accessLog = {};

      # Global settings
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
    };

    # Dynamic configuration for services
    dynamicConfigOptions = {
      http = {
        routers = {
          homeassistant = {
            rule = "Host(`home.hs.yanlincs.com`)";
            service = "homeassistant";
            tls = {
              certResolver = "cloudflare";
              domains = [{
                main = "*.hs.yanlincs.com";
              }];
            };
          };
          immich = {
            rule = "Host(`photo.hs.yanlincs.com`)";
            service = "immich";
            tls = {
              certResolver = "cloudflare";
              domains = [{
                main = "*.hs.yanlincs.com";
              }];
            };
          };
          syncthing = {
            rule = "Host(`syncthing.hs.yanlincs.com`)";
            service = "syncthing";
            tls = {
              certResolver = "cloudflare";
              domains = [{
                main = "*.hs.yanlincs.com";
              }];
            };
          };
        };
        services = {
          homeassistant = {
            loadBalancer = {
              servers = [{
                url = "http://localhost:8123";
              }];
            };
          };
          immich = {
            loadBalancer = {
              servers = [{
                url = "http://localhost:5000";
              }];
            };
          };
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

    # Environment variables for Cloudflare
    environmentFiles = [ "/run/secrets/traefik-env" ];
  };

  # Create environment file for Traefik Cloudflare credentials
  systemd.services.traefik-env-setup = {
    description = "Setup Traefik environment file";
    before = [ "traefik.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /run/secrets
      cat > /run/secrets/traefik-env << 'EOF'
      CF_API_EMAIL=cloudflare@yanlincs.com
      CF_DNS_API_TOKEN=JtIInpXOB8NIDGuYvjyV6kLCysN0mb7MKvryuya-
      EOF
      chmod 600 /run/secrets/traefik-env
    '';
  };
}
