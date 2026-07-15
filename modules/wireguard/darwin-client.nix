# WireGuard VPN client for a nix-darwin host.
# A host enables it with services.wireguard-client and sets the interface address, the server public key and endpoint, and the routes to send over the tunnel.
# The private key is generated on the first deploy and its public key is printed so it can be registered on the server.

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
    system.activationScripts.extraActivation.text = ''
      mkdir -p /etc/wireguard
      chmod 700 /etc/wireguard
      if [ ! -s /etc/wireguard/private.key ]; then
        umask 077
        ${pkgs.wireguard-tools}/bin/wg genkey > /etc/wireguard/private.key
        echo "WireGuard public key: $(${pkgs.wireguard-tools}/bin/wg pubkey < /etc/wireguard/private.key)"
      fi
    '';

    # nix-darwin generates the launchd daemon that brings up wg0, and this overrides it to fix the boot order on macOS.
    # The /nix/store volume can mount after launchd starts the daemon, so wait4path blocks until the store is available before wg-quick starts the tunnel.
    launchd.daemons.wg-quick-wg0.serviceConfig = {
      KeepAlive = lib.mkForce {
        NetworkState = true;
        SuccessfulExit = true;
      };
      ProgramArguments = lib.mkForce [
        "/bin/sh" "-c"
        "/bin/wait4path /nix/store && exec ${pkgs.wireguard-tools}/bin/wg-quick up wg0"
      ];
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
  };

}
