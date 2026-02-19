# NOTE: environment file at: `/etc/acme-env` with mode 600
# content (for Cloudflare API):
#   CF_API_EMAIL=your-email@example.com
#   CF_DNS_API_TOKEN=your-cloudflare-api-token

{ config, lib, ... }:

let
  cfg = config.services.reverse-proxy;

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
    };
  };

  allDomains = lib.unique (lib.mapAttrsToList (_: p: p.domain) cfg.proxies);
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

    environmentFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/acme-env";
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
        inherit (cfg) environmentFile;
      });
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      virtualHosts = lib.mapAttrs' (name: proxy:
        lib.nameValuePair "${name}.${proxy.domain}" {
          forceSSL = true;
          useACMEHost = proxy.domain;
          locations."/" = {
            proxyPass = proxy.backend;
            proxyWebsockets = true;
            extraConfig = proxy.extraConfig;
          };
        }
      ) cfg.proxies;
    };

    users.users.nginx.extraGroups = [ "acme" ];
  };
}
