{ config, pkgs, lib, ... }:

{
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
      
      containers.homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        
        volumes = [
          "/home/yanlin/deploy/data/home/config:/config"
          "/etc/localtime:/etc/localtime:ro"
          "/run/dbus:/run/dbus:ro"
        ];
        
        environment = {
          TZ = "Europe/Copenhagen";
          # Configure Home Assistant to trust reverse proxy
          HASS_HTTP_TRUSTED_PROXY_1 = "127.0.0.1";
          HASS_HTTP_TRUSTED_PROXY_2 = "::1";
          HASS_HTTP_USE_X_FORWARDED_FOR = "true";
        };
        
        extraOptions = [
          "--privileged"  # Required for USB device access
          "--network=host"  # Use host networking
          "--device=/dev/ttyUSB0:/dev/ttyUSB0"  # Sky Connect Zigbee dongle
          "--device=/dev/dri:/dev/dri"  # Hardware acceleration
        ];
        
        autoStart = true;
      };
    };
  };
}