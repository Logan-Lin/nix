# Cloudflare tunnel module that wraps the NixOS services.cloudflared service.
# It exposes a simplified services.cloudflare-tunnel interface.
# A host enables it by setting the tunnel UUID, the credentials file, and a mapping from public domains to local services.

# NOTE: authorize with `cloudflared tunnel login`.
# Create a new tunnel with `cloudflared tunnel create <name>`, then `sudo install -Dm600 ~/.cloudflared/<tunnelID>.json /etc/cloudflared/<tunnelID>.json`.
# Pair each ingress with `cloudflared tunnel route dns <name> <domain>` to add DNS record.

{ config, lib, ... }:

let
  cfg = config.services.cloudflare-tunnel;
in
{
  options.services.cloudflare-tunnel = {
    enable = lib.mkEnableOption "cloudflared tunnel";

    tunnelId = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the cloudflared tunnel to run";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/cloudflared/${cfg.tunnelId}.json";
      description = "Path to the tunnel credentials JSON file";
    };

    ingress = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = { "service.example.com" = "http://127.0.0.1:8888"; };
      description = "Public domain to local service mapping";
    };
  };

  config = lib.mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      tunnels.${cfg.tunnelId} = {
        inherit (cfg) credentialsFile ingress;
        # Fallback rule that cloudflared requires as the final ingress entry.
        # It returns 404 for any request that matches no ingress mapping.
        default = "http_status:404";
      };
    };
  };
}
