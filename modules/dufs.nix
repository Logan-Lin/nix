{ config, pkgs, lib, ... }:

let
  cfg = config.services.dufs;
  authFile = "/etc/dufs-auth";
in
{
  options.services.dufs = {
    sharedPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the folder to share via WebDAV. Set to null to disable dufs.";
      example = "/mnt/storage/shared";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5099;
      description = "Port to listen on";
    };
  };

  config = lib.mkIf (cfg.sharedPath != null) {
    # Install dufs package
    environment.systemPackages = [ pkgs.dufs ];

    # Create systemd service
    # NOTE: Authentication credentials must be manually created in /etc/dufs-auth
    # The file should contain a single line in format: username:password
    # Make sure to set permissions: chmod 600 /etc/dufs-auth
    systemd.services.dufs = {
      description = "Dufs WebDAV File Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "root";  # Run as root to access any system path
        ExecStart = "${pkgs.dufs}/bin/dufs ${cfg.sharedPath} --port ${toString cfg.port} --bind 0.0.0.0 --auth $(cat ${authFile})@/:rw";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    # Open firewall port (optional, since traffic comes through WireGuard)
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
