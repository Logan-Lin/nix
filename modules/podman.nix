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

      # Immich photo and video backup system
      containers.immich = {
        image = "ghcr.io/imagegenius/immich:latest";
        
        volumes = [
          "/home/yanlin/deploy/data/immich/config:/config"
          "/mnt/storage/appbulk/immich:/photos"
          "/mnt/storage/Media/DCIM:/libraries"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
          DB_HOSTNAME = "immich-db";
          DB_USERNAME = "postgres";
          DB_PASSWORD = "postgres";
          DB_DATABASE_NAME = "postgres";
          DB_PORT = "5432";
          REDIS_HOSTNAME = "immich-redis";
          REDIS_PORT = "6379";
          MACHINE_LEARNING_HOST = "0.0.0.0";
          MACHINE_LEARNING_PORT = "3003";
          MACHINE_LEARNING_WORKERS = "1";
          MACHINE_LEARNING_WORKER_TIMEOUT = "120";
        };
        
        ports = [
          "5000:8080"
        ];
        
        extraOptions = [
          "--network=podman"
          "--device=/dev/dri:/dev/dri"  # Hardware acceleration
        ];
        
        dependsOn = [ "immich-db" "immich-redis" ];
        autoStart = true;
      };

      # PostgreSQL database for Immich with vector extension
      containers.immich-db = {
        image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0";
        
        volumes = [
          "/home/yanlin/deploy/data/immich/db:/var/lib/postgresql/data"
        ];
        
        environment = {
          POSTGRES_PASSWORD = "postgres";
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "postgres";
        };
        
        extraOptions = [
          "--network=podman"
        ];
        
        autoStart = true;
      };

      # Redis cache for Immich
      containers.immich-redis = {
        image = "docker.io/redis:7.2-alpine";
        
        extraOptions = [
          "--network=podman"
        ];
        
        autoStart = true;
      };
    };
  };
}