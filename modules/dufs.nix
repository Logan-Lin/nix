{ config, pkgs, lib, ... }:

let
  cfg = config.services.dufs;
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

    auth = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Basic authentication in format 'username:password'. Will be automatically formatted for dufs.";
      example = "admin:secret123";
    };
  };

  config = lib.mkIf (cfg.sharedPath != null) {
    # Install dufs package
    environment.systemPackages = [ pkgs.dufs ];

    # Create systemd service
    systemd.services.dufs = {
      description = "Dufs WebDAV File Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "root";  # Run as root to access any system path
        ExecStart = "${pkgs.dufs}/bin/dufs ${cfg.sharedPath} --port ${toString cfg.port} --bind 0.0.0.0"
          + lib.optionalString (cfg.auth != null) " --auth ${cfg.auth}@/:rw";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    # Open firewall port (optional, since traffic comes through WireGuard)
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
