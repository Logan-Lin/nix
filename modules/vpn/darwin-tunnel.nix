{ config, lib, ... }:

let
  cfg = config.tunnel;
  servicesShell = lib.concatStringsSep " " cfg.services;
  servicesLabel = lib.concatStringsSep " and " cfg.services;
in
{
  options.tunnel = {
    services = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "Wi-Fi" ];
      example = [ "Wi-Fi" "Ethernet" ];
      description = "macOS network services to toggle the SOCKS firewall proxy on.";
    };
  };

  config.programs.zsh.initContent = ''
    function tunnel-on() {
      local host="$1"
      local port="''${2:-1080}"
      local sock="$HOME/.ssh/tunnel.sock"

      if [[ -z "$host" ]]; then
        echo "Usage: tunnel-on <ssh-host> [port]" >&2
        return 1
      fi

      if [[ -S "$sock" ]]; then
        echo "Tunnel already active" >&2
        return 1
      fi

      ssh -D "$port" -f -C -q -N -M -S "$sock" "$host" || {
        rm -f "$sock"
        echo "Failed to establish tunnel" >&2
        return 1
      }

      for svc in ${servicesShell}; do
        networksetup -setsocksfirewallproxy "$svc" localhost "$port"
        networksetup -setsocksfirewallproxystate "$svc" on
      done
      echo "Tunnel to $host on :$port, SOCKS proxy enabled on ${servicesLabel}"
    }

    function tunnel-off() {
      local sock="$HOME/.ssh/tunnel.sock"

      if [[ -S "$sock" ]]; then
        ssh -S "$sock" -O exit _ 2>/dev/null
      fi
      rm -f "$sock"

      for svc in ${servicesShell}; do
        networksetup -setsocksfirewallproxystate "$svc" off
      done
      echo "Tunnel closed, SOCKS proxy disabled on ${servicesLabel}"
    }
  '';
}
