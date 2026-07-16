# Media streaming stack for a home server, bundling the Jellyfin media server with the Sonarr television manager and the Radarr movie manager behind a small options interface.
# A host enables the service and sets mediaDir, and the module runs the services as the same user so they share access to the media library and to the downloads that feed it.
# Sonarr organizes television into the tv subfolder and Radarr organizes movies into the movie subfolder, both under mediaDir, while Jellyfin serves the library.
# No service opens the firewall, so all are reached only over the trusted Tailscale network and through the reverse proxy.

{ config, lib, ... }:

with lib;

let
  cfg = config.services.media-stream;
  user = "yanlin";
  group = "users";
in

{
  options.services.media-stream = {
    enable = mkEnableOption "Jellyfin, Sonarr, and Radarr media streaming stack";

    mediaDir = mkOption {
      type = types.str;
      example = "/mnt/storage/media";
      description = "Directory holding the media library that Jellyfin serves and Sonarr organizes.";
    };
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      inherit user group;
      openFirewall = false;
    };

    services.sonarr = {
      enable = true;
      inherit user group;
      openFirewall = false;
    };

    services.radarr = {
      enable = true;
      inherit user group;
      openFirewall = false;
    };

    # Create the media library and its television and movie subfolders, owned by the shared user so every service can read and write them.
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0755 ${user} ${group} -"
      "d ${cfg.mediaDir}/tv 0755 ${user} ${group} -"
      "d ${cfg.mediaDir}/movie 0755 ${user} ${group} -"
    ];
  };
}
