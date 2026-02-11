# NOTE: Auth key file at: `/etc/tailscale/authkey` with mode 600
# content: `tailscale-api-key`

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.tailscale-custom;
  isRouter = cfg.exitNode || cfg.subnetRoutes != [];
in

{
  options.services.tailscale-custom = {
    exitNode = mkOption {
      type = types.bool;
      default = false;
      description = "Advertise this node as an exit node";
    };

    subnetRoutes = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "10.1.1.0/24" "192.168.1.0/24" ];
      description = "Subnets to advertise to the Tailscale network";
    };

    acceptRoutes = mkOption {
      type = types.bool;
      default = true;
      description = "Accept subnet routes advertised by other nodes";
    };
  };

  config = {
    services.tailscale = {
      enable = true;
      authKeyFile = "/etc/tailscale/authkey";
      useRoutingFeatures = if isRouter then "server" else "client";
      extraUpFlags =
        optional cfg.exitNode "--advertise-exit-node"
        ++ optional (cfg.subnetRoutes != []) "--advertise-routes=${concatStringsSep "," cfg.subnetRoutes}"
        ++ optional cfg.acceptRoutes "--accept-routes";
    };

    boot.kernel.sysctl = mkIf isRouter {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
