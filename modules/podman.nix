{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.virtualisation.podman;

  # System-wide script for updating containers (works with sudo)
  update-containers-script = pkgs.writeShellScriptBin "update-containers" ''
    echo "Scanning running containers..."
    containers=$(podman ps --format "{{.Names}}")

    if [[ -z "$containers" ]]; then
      echo "No running containers found."
      exit 0
    fi

    for container in $containers; do
      echo "=================================================="
      echo "Processing container: $container"

      # Get the image used by this container
      image=$(podman inspect "$container" --format "{{.ImageName}}")
      echo "Current image: $image"

      # Pull the latest version of the image
      echo "Pulling latest version of $image..."
      if podman pull "$image"; then
        # Check if the image was updated by comparing IDs
        old_id=$(podman inspect "$container" --format "{{.Image}}")
        new_id=$(podman inspect "$image" --format "{{.Id}}")

        if [[ "$old_id" != "$new_id" ]]; then
          echo "New version available! Restarting container..."
          podman restart "$container"
          echo "Container $container restarted with new image"
        else
          echo "Container $container is already using the latest image"
        fi
      else
        echo "Failed to pull image for $container"
      fi
      echo ""
    done

    echo "Container update scan complete!"
  '';
in
{
  options.virtualisation.podman.autoUpdate = {
    enable = mkEnableOption "automatic container updates";

    interval = mkOption {
      type = types.str;
      default = "daily";
      example = "*-*-* 03:00:00";
      description = "Systemd timer schedule for automatic updates (OnCalendar format)";
    };
  };

  config = {
    # Container virtualization with Podman
    virtualisation = {
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other
      defaultNetwork.settings.dns_enabled = true;
      # Extra packages for networking
      extraPackages = [ pkgs.netavark pkgs.aardvark-dns ];
    };
    # Enable OCI container support
    oci-containers = {
      backend = "podman";
      # Container definitions are now defined in host-specific containers.nix files
      # and will be merged with this base configuration
    };
  };

    # Make update-containers available system-wide (works with sudo)
    environment.systemPackages = [ update-containers-script ];

    # Automatic container updates via systemd timer
    systemd.services.container-update-all = mkIf cfg.autoUpdate.enable {
      description = "Automatic Podman container updates";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${update-containers-script}/bin/update-containers";
      };
    };

    systemd.timers.container-update-all = mkIf cfg.autoUpdate.enable {
      description = "Timer for automatic Podman container updates";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.autoUpdate.interval;
        Persistent = true;
      };
    };
  };
}
