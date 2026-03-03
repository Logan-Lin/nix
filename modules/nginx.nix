# NOTE: environment file at: `/etc/acme-env` with mode 600
# content (for Cloudflare API):
#   CF_API_EMAIL=your-email@example.com
#   CF_DNS_API_TOKEN=your-cloudflare-api-token

{ config, lib, ... }:

let
  cfg = config.services.reverse-proxy;

  rateLimitSubmodule = lib.types.submodule {
    options = {
      rate = lib.mkOption {
        type = lib.types.str;
        example = "10r/s";
      };
      burst = lib.mkOption {
        type = lib.types.int;
        default = 20;
      };
    };
  };

  proxySubmodule = lib.types.submodule {
    options = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = cfg.defaultDomain;
      };
      backend = lib.mkOption {
        type = lib.types.str;
        example = "http://127.0.0.1:3000";
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
      };
      rateLimit = lib.mkOption {
        type = lib.types.nullOr rateLimitSubmodule;
        default = null;
      };
      blockRobots = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };

  allDomains = lib.unique (lib.mapAttrsToList (_: p: p.domain) cfg.proxies);
  rateLimitedProxies = lib.filterAttrs (_: p: p.rateLimit != null) cfg.proxies;
in
{
  options.services.reverse-proxy = {
    enable = lib.mkEnableOption "nginx reverse proxy with ACME";

    defaultDomain = lib.mkOption {
      type = lib.types.str;
      example = "example.com";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
    };

    proxies = lib.mkOption {
      type = lib.types.attrsOf proxySubmodule;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.acmeEmail;
      certs = lib.genAttrs allDomains (domain: {
        domain = "*.${domain}";
        dnsProvider = "cloudflare";
        environmentFile = "/etc/acme-env";
      });
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      appendHttpConfig = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: proxy:
        "limit_req_zone $binary_remote_addr zone=ratelimit_${name}:10m rate=${proxy.rateLimit.rate};"
      ) rateLimitedProxies);

      virtualHosts = {
        "_" = {
          default = true;
          rejectSSL = true;
          locations."/".return = "444";
        };
      } // lib.mapAttrs' (name: proxy:
        lib.nameValuePair "${name}.${proxy.domain}" {
          forceSSL = true;
          useACMEHost = proxy.domain;
          locations."/" = {
            proxyPass = proxy.backend;
            proxyWebsockets = true;
            extraConfig = ''
              client_max_body_size 0;
              proxy_read_timeout 600s;
              proxy_send_timeout 600s;
              send_timeout 600s;
            '' + (lib.optionalString (proxy.rateLimit != null) ''
              limit_req zone=ratelimit_${name} burst=${toString proxy.rateLimit.burst} nodelay;
              limit_req_status 429;
            '') + proxy.extraConfig;
          };
          locations."= /robots.txt" = lib.mkIf proxy.blockRobots {
            extraConfig = ''
              default_type text/plain;
              return 200 "User-agent: *\nDisallow: /\n";
            '';
          };
        }
      ) cfg.proxies;
    };

    users.users.nginx.extraGroups = [ "acme" ];
  };
}
