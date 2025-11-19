{ config, pkgs, lib, ... }:

{
  # Traefik reverse proxy service
  services.traefik = {
    enable = true;
    
    # Static configuration
    staticConfigOptions = {
      # Enable Docker provider for automatic service discovery
      providers.docker = {
        endpoint = "unix:///var/run/docker.sock";
        exposedByDefault = false;  # Only expose containers with traefik.enable=true
        network = "podman";  # Use podman network
      };
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

    # Dynamic configuration is now defined in host-specific proxy.nix files
    # and will be merged with this base configuration

    # Environment variables for Cloudflare
    environmentFiles = [ "/run/secrets/traefik-env" ];
  };

  # Ensure Traefik can access Docker socket
  systemd.services.traefik.serviceConfig = {
    SupplementaryGroups = [ "podman" ];
    # Mount Docker/Podman socket for service discovery
    BindPaths = [ "/run/podman/podman.sock:/var/run/docker.sock" ];
  };

  # NOTE: Cloudflare credentials must be manually created in /run/secrets/traefik-env
  # The file should contain:
  #   CF_API_EMAIL=your-email@example.com
  #   CF_DNS_API_TOKEN=your-cloudflare-api-token
  # Make sure to set permissions: chmod 600 /run/secrets/traefik-env
}
