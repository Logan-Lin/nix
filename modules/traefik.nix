# NOTE: environment file at: `/etc/traefik-env` with mode 600
# content (for Cloudflare API):
#   CF_API_EMAIL=your-email@example.com
#   CF_DNS_API_TOKEN=your-cloudflare-api-token

{ ... }:

{
  services.traefik = {
    enable = true;
    useEnvSubst = false;

    dynamic.dir = "/var/lib/traefik/dynamic";

    static.settings = {
      entryPoints = {
        http = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
            permanent = true;
          };
        };
        websecure = {
          address = ":443";
          transport.respondingTimeouts.readTimeout = "0s";
        };
      };

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

      api = {
        dashboard = true;
        debug = false;
      };

      log = {
        level = "INFO";
      };
      accessLog = {};

      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
    };

    environmentFiles = [ "/etc/traefik-env" ];
  };

}
