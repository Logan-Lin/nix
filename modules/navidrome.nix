{ config, lib, ... }:

with lib;

let
  cfg = config.services.navidrome-custom;
  systemTZ = config.time.timeZone;
in

{
  options.services.navidrome-custom = {
    enable = mkEnableOption "Navidrome music streaming service";

    musicDir = mkOption {
      type = types.str;
      description = "Directory containing the music library";
    };

    port = mkOption {
      type = types.port;
      default = 4533;
      description = "Host port for the Navidrome web UI";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.navidrome = {
      image = "ghcr.io/navidrome/navidrome:latest";

      volumes = [
        "/var/lib/navidrome:/data"
        "${cfg.musicDir}:/music:ro"
      ];

      environment = {
        TZ = systemTZ;
        ND_ENABLEEXTERNALSERVICES = "false";
      };

      ports = [
        "${toString cfg.port}:4533"
      ];

      extraOptions = [
        "--network=podman"
      ];

      autoStart = true;
    };
  };
}
