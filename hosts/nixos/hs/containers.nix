{ config, pkgs, lib, ... }:

let
  # Import Immich configuration from declarative config file
  immichConfig = import ../../../config/immich.nix;
  
  # Convert Nix configuration to JSON string
  immichConfigJson = builtins.toJSON immichConfig;
  
  # Write config file to a location accessible by the container
  immichConfigFile = pkgs.writeText "immich.json" immichConfigJson;
  
  # Universal container configuration
  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in
{
  # Container definitions for hs host
  virtualisation.oci-containers.containers = {

    # Immich photo and video backup system
    immich = {
      image = "ghcr.io/imagegenius/immich:latest";
      
      volumes = [
        "/var/lib/containers/config/immich:/config"
        "/mnt/storage/appbulk/immich:/photos"
        "/mnt/storage/Media/DCIM:/libraries"
        # Mount the declarative config file
        "${immichConfigFile}:/config/immich.json:ro"
      ];
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
        # Point to the mounted config file
        IMMICH_CONFIG_FILE = "/config/immich.json";
        # Database connection (keep as env vars for security)
        DB_HOSTNAME = "immich-db";
        DB_USERNAME = "postgres";
        DB_PASSWORD = "postgres";
        DB_DATABASE_NAME = "postgres";
        DB_PORT = "5432";
        # Redis connection
        REDIS_HOSTNAME = "immich-redis";
        REDIS_PORT = "6379";
        # Machine Learning server (internal)
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
    immich-db = {
      image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0";
      
      volumes = [
        "/var/lib/containers/config/immich-db:/var/lib/postgresql/data"
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
    immich-redis = {
      image = "docker.io/redis:7.2-alpine";
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # Plex Media Server
    plex = {
      image = "docker.io/linuxserver/plex:latest";
      
      volumes = [
        "/var/lib/containers/config/plex:/config"
        "/mnt/storage/Media:/data"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.plex.rule" = "Host(`plex.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.plex.entrypoints" = "websecure";
        "traefik.http.routers.plex.tls" = "true";
        "traefik.http.routers.plex.tls.certresolver" = "cloudflare";
        "traefik.http.routers.plex.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.plex.loadbalancer.server.port" = "32400";
      };
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
        VERSION = "docker";
      };
      
      ports = [
        "5008:32400"
      ];
      
      extraOptions = [
        "--network=podman"
        "--device=/dev/dri:/dev/dri"  # Hardware acceleration
      ];
      
      autoStart = true;
    };

    # Jellyfin media server (alternative to Plex)
    jellyfin = {
      image = "docker.io/linuxserver/jellyfin:latest";
      
      volumes = [
        "/var/lib/containers/config/jellyfin:/config"
        "/mnt/storage/Media:/data"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.jellyfin.rule" = "Host(`jellyfin.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.jellyfin.entrypoints" = "websecure";
        "traefik.http.routers.jellyfin.tls" = "true";
        "traefik.http.routers.jellyfin.tls.certresolver" = "cloudflare";
        "traefik.http.routers.jellyfin.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.jellyfin.loadbalancer.server.port" = "8096";
      };
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
      };
      
      ports = [
        "5002:8096"
      ];
      
      extraOptions = [
        "--network=podman"
        "--device=/dev/dri:/dev/dri"  # Hardware acceleration
      ];
      
      autoStart = true;
    };

    # Sonarr TV show management
    sonarr = {
      image = "docker.io/linuxserver/sonarr:latest";
      
      volumes = [
        "/var/lib/containers/config/sonarr:/config"
        "/mnt/storage/Media:/data"
      ];
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
      };
      
      ports = [
        "5003:8989"
      ];
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # Radarr movie management
    radarr = {
      image = "docker.io/linuxserver/radarr:latest";
      
      volumes = [
        "/var/lib/containers/config/radarr:/config"
        "/mnt/storage/Media:/data"
      ];
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
      };
      
      ports = [
        "5004:7878"
      ];
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # qBittorrent torrent client with host networking
    qbittorrent = {
      image = "docker.io/linuxserver/qbittorrent:4.6.7";
      
      volumes = [
        "/var/lib/containers/config/qbittorrent:/config"
        "/mnt/storage/Media:/data"
      ];
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
        TORRENTING_PORT = "41234";
        WEBUI_PORT = "8080";
      };
      
      extraOptions = [
        "--network=host"
      ];
      
      autoStart = true;
    };

  };
}
