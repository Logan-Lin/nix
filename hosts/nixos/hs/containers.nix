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

    # Paperless document management system
    paperless = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      
      volumes = [
        "/var/lib/containers/config/paperless:/usr/src/paperless/data"
        "/mnt/storage/appbulk/Paperless/media:/usr/src/paperless/media"
        "/mnt/storage/appbulk/Paperless/consume:/usr/src/paperless/consume"
        "/mnt/storage/appbulk/Paperless/export:/usr/src/paperless/export"
      ];

      environment = {
        PAPERLESS_REDIS = "redis://paperless-redis:6379";
        PAPERLESS_OCR_LANGUAGE = "eng+chi_sim";
        PAPERLESS_OCR_LANGUAGES = "chi-sim";
        PAPERLESS_FILENAME_FORMAT = "{{ created }}-{{ correspondent }}-{{ title }}";
        PAPERLESS_TIME_ZONE = "Europe/Copenhagen";
        PAPERLESS_URL = "https://paperless.yanlincs.com";
        PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.yanlincs.com";
        PAPERLESS_ALLOWED_HOSTS = "paperless.yanlincs.com";
        PAPERLESS_CORS_ALLOWED_HOSTS = "https://paperless.yanlincs.com";
        PAPERLESS_SECRET_KEY = "e11fl1oa-*ytql8p)(06fbj4ukrlo+n7k&q5+$1md7i+mge=ee";
        USERMAP_UID = commonUID;
        USERMAP_GID = commonGID;
        CA_TS_FALLBACK_DIR = "/usr/src/paperless/data";
      };
      
      ports = [
        "5005:8000"
      ];
      
      extraOptions = [
        "--network=podman"
      ];
      
      dependsOn = [ "paperless-redis" ];
      autoStart = true;
    };

    # Redis cache for Paperless
    paperless-redis = {
      image = "docker.io/redis:7.2-alpine";
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # Nextcloud cloud storage and file sharing
    cloud = {
      image = "docker.io/linuxserver/nextcloud:latest";
      
      volumes = [
        "/var/lib/containers/config/cloud:/config"
        "/mnt/storage/appbulk/cloud:/data"
        "/mnt/storage/Media/nsfw:/ext/nsfw"
      ];
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
      };
      
      ports = [
        "5001:80"
      ];
      
      extraOptions = [
        "--network=podman"
      ];
      
      dependsOn = [ "cloud-db" ];
      autoStart = true;
    };

    # MariaDB database for Nextcloud
    cloud-db = {
      image = "docker.io/linuxserver/mariadb:latest";

      volumes = [
        "/var/lib/containers/config/cloud-db:/config"
      ];

      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
        MYSQL_ROOT_PASSWORD = "nextcloud";
        MYSQL_DATABASE = "nextcloud";
        MYSQL_USER = "nextcloud";
        MYSQL_PASSWORD = "nextcloud";
      };

      extraOptions = [
        "--network=podman"
      ];

      autoStart = true;
    };

    # MicroBin web clipboard
    microbin = {
      image = "docker.io/danielszabo99/microbin:latest";

      volumes = [
        "/var/lib/containers/config/microbin:/app/microbin_data"
      ];

      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
        # HTTP Basic Authentication
        MICROBIN_BASIC_AUTH_USERNAME = "yanlin";
        MICROBIN_BASIC_AUTH_PASSWORD = "1Hayashi-2Hiko";
        # Administrator credentials (change from defaults)
        MICROBIN_ADMIN_USERNAME = "admin";
        MICROBIN_ADMIN_PASSWORD = "@i<i[_:-^)J7<30Tm;:j4:By-L9P{vilxK)Y#O>K";
        # Enable public pasta listing
        MICROBIN_NO_LISTING = "false";
        # Allow public/private pastes
        MICROBIN_PRIVATE = "true";
      };

      ports = [
        "5010:8080"
      ];

      extraOptions = [
        "--network=podman"
      ];

      autoStart = true;
    };
  };
}
