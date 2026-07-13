# NOTE: After deploy, get public key with: `sudo sh -c 'wg pubkey < /etc/wireguard/private.key'`

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.wireguard-client;
in

{
  options.services.wireguard-client = {
    enable = mkEnableOption "WireGuard VPN client";

    address = mkOption {
      type = types.str;
      example = "10.2.2.2/24";
    };

    serverPublicKey = mkOption { type = types.str; };

    serverEndpoint = mkOption {
      type = types.str;
      example = "vpn.example.com:51820";
    };

    allowedIPs = mkOption {
      type = types.listOf types.str;
      default = [ "10.2.2.0/24" ];
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wireguard-tools ];

    systemd.tmpfiles.rules = [
      "d /etc/wireguard 0700 root root - -"
      "f /etc/wireguard/private.key 0600 root root - -"
    ];

    systemd.services.wireguard-keygen = {
      description = "Generate WireGuard private key";
      before = [ "wg-quick-wg0.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [ ! -s /etc/wireguard/private.key ]; then
          ${pkgs.wireguard-tools}/bin/wg genkey > /etc/wireguard/private.key
          chmod 600 /etc/wireguard/private.key
          echo "Public key: $(${pkgs.wireguard-tools}/bin/wg pubkey < /etc/wireguard/private.key)"
        fi
      '';
    };

    networking.wg-quick.interfaces.wg0 = {
      privateKeyFile = "/etc/wireguard/private.key";
      address = [ cfg.address ];
      peers = [{
        publicKey = cfg.serverPublicKey;
        allowedIPs = cfg.allowedIPs;
        endpoint = cfg.serverEndpoint;
        persistentKeepalive = 25;
      }];
    };

    networking.firewall.trustedInterfaces = [ "wg0" ];
  };
}
