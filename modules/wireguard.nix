# NOTE: Private key file at: `/etc/wireguard/private.key` with mode 600
# Generate with: `wg genkey > /etc/wireguard/private.key`

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.wireguard-custom;
in

{
  options.services.wireguard-custom = {
    enable = mkEnableOption "WireGuard VPN";
    
    mode = mkOption {
      type = types.enum [ "server" "client" ];
      description = "Whether to run as server (hub) or client (spoke)";
    };
    
    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = "WireGuard interface name";
    };
    
    listenPort = mkOption {
      type = types.port;
      default = 51820;
      description = "UDP port to listen on (server mode only)";
    };

    privateKeyFile = mkOption {
      type = types.str;
      default = "/etc/wireguard/private.key";
      description = "Path to private key file";
    };
    
    serverConfig = mkOption {
      type = types.submodule {
        options = {
          address = mkOption {
            type = types.str;
            example = "10.2.2.1/24";
            description = "Server IP address with CIDR";
          };
          
          peers = mkOption {
            type = types.listOf (types.submodule {
              options = {
                name = mkOption {
                  type = types.str;
                  description = "Peer name for identification";
                };
                
                publicKey = mkOption {
                  type = types.str;
                  description = "Peer's public key";
                };
                
                allowedIPs = mkOption {
                  type = types.listOf types.str;
                  description = "IP addresses this peer is allowed to use";
                };
              };
            });
            default = [];
            description = "List of client peers";
          };
        };
      };
      description = "Server-specific configuration";
    };
    
    clientConfig = mkOption {
      type = types.submodule {
        options = {
          address = mkOption {
            type = types.str;
            example = "10.2.2.20/24";
            description = "Client IP address with CIDR";
          };
          
          serverPublicKey = mkOption {
            type = types.str;
            description = "Server's public key";
          };
          
          serverEndpoint = mkOption {
            type = types.str;
            example = "vpn.example.com:51820";
            description = "Server endpoint (host:port)";
          };
          
          allowedIPs = mkOption {
            type = types.listOf types.str;
            default = [ "10.2.2.0/24" ];
            description = "IP ranges to route through the tunnel";
          };
        };
      };
      description = "Client-specific configuration";
    };
  };

  config = mkIf cfg.enable {
    # Install WireGuard tools
    environment.systemPackages = with pkgs; [ wireguard-tools ];

    # Create private key file if it doesn't exist
    systemd.tmpfiles.rules = [
      "d /etc/wireguard 0700 root root - -"
      "f ${cfg.privateKeyFile} 0600 root root - -"
    ];

    # Generate private key on first run
    systemd.services.wireguard-keygen = {
      description = "Generate WireGuard private key";
      before = [ "wg-quick-${cfg.interface}.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [ ! -s ${cfg.privateKeyFile} ]; then
          echo "Generating WireGuard private key..."
          ${pkgs.wireguard-tools}/bin/wg genkey > ${cfg.privateKeyFile}
          chmod 600 ${cfg.privateKeyFile}
          echo "Private key generated. Public key:"
          ${pkgs.wireguard-tools}/bin/wg pubkey < ${cfg.privateKeyFile}
          echo "Please add this public key to your peer configurations."
        fi
      '';
    };

    # WireGuard interface configuration (combined server and client)
    networking.wg-quick.interfaces = {
      ${cfg.interface} = mkMerge [
        # Common configuration
        {
          privateKeyFile = cfg.privateKeyFile;
        }
        
        # Server-specific configuration
        (mkIf (cfg.mode == "server") {
          address = [ cfg.serverConfig.address ];
          listenPort = cfg.listenPort;
          
          # Enable IP forwarding and NAT for server
          preUp = ''
            ${pkgs.iptables}/bin/iptables -A FORWARD -i ${cfg.interface} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -A FORWARD -o ${cfg.interface} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.2.2.0/24 -o eth0 -j MASQUERADE
          '';
          
          postDown = ''
            ${pkgs.iptables}/bin/iptables -D FORWARD -i ${cfg.interface} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -D FORWARD -o ${cfg.interface} -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.2.2.0/24 -o eth0 -j MASQUERADE
          '';

          peers = map (peer: {
            publicKey = peer.publicKey;
            allowedIPs = peer.allowedIPs;
          }) cfg.serverConfig.peers;
        })
        
        # Client-specific configuration
        (mkIf (cfg.mode == "client") {
          address = [ cfg.clientConfig.address ];
          
          peers = [{
            publicKey = cfg.clientConfig.serverPublicKey;
            allowedIPs = cfg.clientConfig.allowedIPs;
            endpoint = cfg.clientConfig.serverEndpoint;
            persistentKeepalive = 25;
          }];
        })
      ];
    };

    # Firewall configuration
    networking.firewall = mkMerge [
      # Server firewall rules
      (mkIf (cfg.mode == "server") {
        allowedUDPPorts = [ cfg.listenPort ];
        trustedInterfaces = [ cfg.interface ];
      })
      
      # Client firewall rules  
      (mkIf (cfg.mode == "client") {
        trustedInterfaces = [ cfg.interface ];
      })
    ];

    # Enable IP forwarding for server
    boot.kernel.sysctl = mkIf (cfg.mode == "server") {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
