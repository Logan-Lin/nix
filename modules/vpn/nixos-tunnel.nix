{ config, lib, pkgs, ... }:

let
  redsocksPort = 12345;
  defaultSocksPort = 1080;

  tunnelRedirect = pkgs.writeShellApplication {
    name = "tunnel-redirect";
    runtimeInputs = [ pkgs.nftables pkgs.systemd ];
    text = ''
      case "''${1:-}" in
        start)
          ssh_ip="''${2:-}"
          if [[ -z "$ssh_ip" ]]; then
            echo "Usage: tunnel-redirect start <ssh_server_ip>" >&2
            exit 1
          fi
          if ! systemctl start redsocks.service; then
            echo "Failed to start redsocks" >&2
            exit 1
          fi
          nft delete table ip tunnel_redirect 2>/dev/null || true
          nft delete table ip6 tunnel_redirect 2>/dev/null || true
          nft -f - <<EOF
      table ip tunnel_redirect {
        chain output {
          type nat hook output priority -100; policy accept;
          ip daddr $ssh_ip return
          ip daddr 0.0.0.0/8 return
          ip daddr 10.0.0.0/8 return
          ip daddr 127.0.0.0/8 return
          ip daddr 169.254.0.0/16 return
          ip daddr 172.16.0.0/12 return
          ip daddr 192.168.0.0/16 return
          ip daddr 224.0.0.0/4 return
          ip daddr 240.0.0.0/4 return
          meta skuid "redsocks" return
          meta l4proto tcp redirect to :${toString redsocksPort}
        }
      }
      table ip6 tunnel_redirect {
        chain output {
          type filter hook output priority 0; policy accept;
          ip6 daddr ::1/128 return
          ip6 daddr fe80::/10 return
          ip6 daddr fc00::/7 return
          reject
        }
      }
      EOF
          ;;
        stop)
          nft delete table ip tunnel_redirect 2>/dev/null || true
          nft delete table ip6 tunnel_redirect 2>/dev/null || true
          systemctl stop redsocks.service 2>/dev/null || true
          ;;
        *)
          echo "Usage: tunnel-redirect {start <ip>|stop}" >&2
          exit 1
          ;;
      esac
    '';
  };

  tunnelOn = pkgs.writeShellApplication {
    name = "tunnel-on";
    runtimeInputs = [ pkgs.openssh pkgs.glibc.bin pkgs.gawk ];
    text = ''
      host="''${1:-}"
      port="''${2:-${toString defaultSocksPort}}"
      sock="$HOME/.ssh/tunnel.sock"

      if [[ -z "$host" ]]; then
        echo "Usage: tunnel-on <ssh-host> [socks-port]" >&2
        exit 1
      fi

      if [[ -S "$sock" ]]; then
        echo "Tunnel already active" >&2
        exit 1
      fi

      ssh_host=$(ssh -G "$host" 2>/dev/null | awk '/^hostname / { print $2 }')
      [[ -z "$ssh_host" ]] && ssh_host="$host"
      ssh_ip=$(getent ahostsv4 "$ssh_host" | awk 'NR==1 { print $1 }')
      if [[ -z "$ssh_ip" ]]; then
        echo "Failed to resolve $ssh_host" >&2
        exit 1
      fi

      if ! ssh -4 -D "$port" -f -C -q -N -M -S "$sock" "$host"; then
        rm -f "$sock"
        echo "Failed to establish tunnel" >&2
        exit 1
      fi

      if ! sudo ${tunnelRedirect}/bin/tunnel-redirect start "$ssh_ip"; then
        ssh -S "$sock" -O exit _ 2>/dev/null
        rm -f "$sock"
        echo "Failed to install redirect rules, tunnel closed" >&2
        exit 1
      fi

      echo "Tunnel to $host ($ssh_ip) on :$port, TCP redirected via redsocks"
    '';
  };

  tunnelOff = pkgs.writeShellApplication {
    name = "tunnel-off";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      sock="$HOME/.ssh/tunnel.sock"

      sudo ${tunnelRedirect}/bin/tunnel-redirect stop || true

      if [[ -S "$sock" ]]; then
        ssh -S "$sock" -O exit _ 2>/dev/null
      fi
      rm -f "$sock"

      echo "Tunnel closed, redirect removed"
    '';
  };
in

{
  services.redsocks = {
    enable = true;
    redsocks = [{
      ip = "127.0.0.1";
      port = redsocksPort;
      proxy = "127.0.0.1:${toString defaultSocksPort}";
      type = "socks5";
      redirectCondition = false;
    }];
  };

  systemd.services.redsocks.wantedBy = lib.mkForce [ ];

  environment.systemPackages = [ tunnelOn tunnelOff ];
}
