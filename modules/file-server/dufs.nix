# NOTE: Authentication file at: `/etc/dufs-auth` with mode 600
# content: `username:password`

{ config, pkgs, lib, ... }:

let
  cfg = config.services.dufs;
  authFile = "/etc/dufs-auth";
in
{
  options.services.dufs = {
    shares = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "Path to the folder to share via WebDAV";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 5099;
            description = "Port to listen on";
          };
        };
      });
      default = {};
      description = "WebDAV shares to expose via dufs. Each entry creates a separate dufs instance.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User account under which dufs runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "Group under which dufs runs";
    };
  };

  config = lib.mkIf (cfg.shares != {}) {
    environment.systemPackages = [ pkgs.dufs ];

    systemd.services = lib.mapAttrs' (name: s:
      lib.nameValuePair "dufs-${name}" {
        description = "Dufs WebDAV File Server - ${name}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          UMask = "0022";
          ExecStart = ''/bin/sh -c "${pkgs.dufs}/bin/dufs ${s.path} --port ${toString s.port} --bind 0.0.0.0 --allow-all --auth $(cat ${authFile})@/:rw"'';
          Restart = "on-failure";
          RestartSec = "10s";
        };
      }
    ) cfg.shares;
  };
}
