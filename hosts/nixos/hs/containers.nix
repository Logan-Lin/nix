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
    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      
      volumes = [
        "/var/lib/containers/home/config:/config"
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus:ro"
        # Mount declarative configuration files
        "/home/yanlin/.config/nix/config/homeassistant/configuration.yaml:/config/configuration.yaml:ro"
        "/home/yanlin/.config/nix/config/homeassistant/automations.yaml:/config/automations.yaml:ro"
        "/home/yanlin/.config/nix/config/homeassistant/scenes.yaml:/config/scenes.yaml:ro"
        "/home/yanlin/.config/nix/config/homeassistant/scripts.yaml:/config/scripts.yaml:ro"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.homeassistant.rule" = "Host(`home.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.homeassistant.entrypoints" = "websecure";
        "traefik.http.routers.homeassistant.tls" = "true";
        "traefik.http.routers.homeassistant.tls.certresolver" = "cloudflare";
        "traefik.http.routers.homeassistant.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.homeassistant.loadbalancer.server.port" = "8123";
      };
      
      environment = {
        TZ = systemTZ;
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
    immich = {
      image = "ghcr.io/imagegenius/immich:latest";
      
      volumes = [
        "/var/lib/containers/immich/config:/config"
        "/mnt/storage/appbulk/immich:/photos"
        "/mnt/storage/Media/DCIM:/libraries"
        # Mount the declarative config file
        "${immichConfigFile}:/config/immich.json:ro"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.immich.rule" = "Host(`photo.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.immich.entrypoints" = "websecure";
        "traefik.http.routers.immich.tls" = "true";
        "traefik.http.routers.immich.tls.certresolver" = "cloudflare";
        "traefik.http.routers.immich.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.immich.loadbalancer.server.port" = "8080";
      };
      
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
        "/var/lib/containers/immich/db:/var/lib/postgresql/data"
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
        "/var/lib/containers/plex/config:/config"
        "/mnt/storage/appbulk/plex-transcode:/transcode"
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
        "/var/lib/containers/sonarr/config:/config"
        "/mnt/storage/Media:/data"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.sonarr.rule" = "Host(`sonarr.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.sonarr.entrypoints" = "websecure";
        "traefik.http.routers.sonarr.tls" = "true";
        "traefik.http.routers.sonarr.tls.certresolver" = "cloudflare";
        "traefik.http.routers.sonarr.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.sonarr.loadbalancer.server.port" = "8989";
      };
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
      };
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # Radarr movie management
    radarr = {
      image = "docker.io/linuxserver/radarr:latest";
      
      volumes = [
        "/var/lib/containers/radarr/config:/config"
        "/mnt/storage/Media:/data"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.radarr.rule" = "Host(`radarr.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.radarr.entrypoints" = "websecure";
        "traefik.http.routers.radarr.tls" = "true";
        "traefik.http.routers.radarr.tls.certresolver" = "cloudflare";
        "traefik.http.routers.radarr.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.radarr.loadbalancer.server.port" = "7878";
      };
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
      };
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # Bazarr subtitle management
    bazarr = {
      image = "docker.io/linuxserver/bazarr:latest";
      
      volumes = [
        "/var/lib/containers/bazarr/config:/config"
        "/mnt/storage/Media:/data"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.bazarr.rule" = "Host(`bazarr.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.bazarr.entrypoints" = "websecure";
        "traefik.http.routers.bazarr.tls" = "true";
        "traefik.http.routers.bazarr.tls.certresolver" = "cloudflare";
        "traefik.http.routers.bazarr.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.bazarr.loadbalancer.server.port" = "6767";
      };
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
      };
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # qBittorrent torrent client with host networking
    qbittorrent = {
      image = "docker.io/linuxserver/qbittorrent:4.6.7";
      
      volumes = [
        "/var/lib/containers/qbit/config:/config"
        "/mnt/storage/Media:/data"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.qbittorrent.rule" = "Host(`qbit.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.qbittorrent.entrypoints" = "websecure";
        "traefik.http.routers.qbittorrent.tls" = "true";
        "traefik.http.routers.qbittorrent.tls.certresolver" = "cloudflare";
        "traefik.http.routers.qbittorrent.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.qbittorrent.loadbalancer.server.port" = "8080";
      };
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
        TORRENTING_PORT = "41234";
        WEBUI_PORT = "8080";
      };
      
      extraOptions = [
        "--network=host"  # Use host networking as requested
      ];
      
      autoStart = true;
    };

    # Paperless document management system
    paperless = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      
      volumes = [
        "/var/lib/containers/paperless/config:/usr/src/paperless/data"
        "/mnt/storage/appbulk/Paperless/media:/usr/src/paperless/media"
        "/mnt/storage/appbulk/Paperless/consume:/usr/src/paperless/consume"
        "/mnt/storage/appbulk/Paperless/export:/usr/src/paperless/export"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.paperless.rule" = "Host(`paperless.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.paperless.entrypoints" = "websecure";
        "traefik.http.routers.paperless.tls" = "true";
        "traefik.http.routers.paperless.tls.certresolver" = "cloudflare";
        "traefik.http.routers.paperless.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.paperless.loadbalancer.server.port" = "8000";
      };
      
      environment = {
        PAPERLESS_REDIS = "redis://paperless-redis:6379";
        PAPERLESS_OCR_LANGUAGE = "eng+chi_sim";
        PAPERLESS_OCR_LANGUAGES = "chi-sim";
        PAPERLESS_FILENAME_FORMAT = "{{ created }}-{{ correspondent }}-{{ title }}";
        PAPERLESS_TIME_ZONE = "Europe/Copenhagen";
        PAPERLESS_URL = "https://paperless.${config.networking.hostName}.yanlincs.com";
        PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.${config.networking.hostName}.yanlincs.com";
        PAPERLESS_ALLOWED_HOSTS = "paperless.${config.networking.hostName}.yanlincs.com";
        PAPERLESS_CORS_ALLOWED_HOSTS = "https://paperless.${config.networking.hostName}.yanlincs.com";
        PAPERLESS_SECRET_KEY = "e11fl1oa-*ytql8p)(06fbj4ukrlo+n7k&q5+$1md7i+mge=ee";
        USERMAP_UID = commonUID;
        USERMAP_GID = commonGID;
        CA_TS_FALLBACK_DIR = "/usr/src/paperless/data";
      };
      
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

    # RSS reader (Miniflux)
    rss = {
      image = "docker.io/miniflux/miniflux:latest";

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.rss.rule" = "Host(`rss.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.rss.entrypoints" = "websecure";
        "traefik.http.routers.rss.tls" = "true";
        "traefik.http.routers.rss.tls.certresolver" = "cloudflare";
        "traefik.http.routers.rss.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.rss.loadbalancer.server.port" = "8080";
      };
      
      environment = {
        DATABASE_URL = "postgres://miniflux:miniflux@rss-db/miniflux?sslmode=disable";
        ADMIN_USERNAME = "yanlin";
        ADMIN_PASSWORD = "1Hayashi-2Hiko";
        BASE_URL = "https://rss.${config.networking.hostName}.yanlincs.com";
        CREATE_ADMIN = "1";
        RUN_MIGRATIONS = "1";
        HTTP_CLIENT_TIMEOUT = "50000";
        POLLING_FREQUENCY = "60";
        CLEANUP_FREQUENCY_HOURS = "24";
        CLEANUP_ARCHIVE_READ_DAYS = "60";
        CLEANUP_REMOVE_SESSIONS_DAYS = "30";
      };
      
      extraOptions = [
        "--network=podman"
      ];
      
      dependsOn = [ "rss-db" ];
      autoStart = true;
    };

    # PostgreSQL database for RSS (Miniflux)
    rss-db = {
      image = "docker.io/postgres:17-alpine";
      
      volumes = [
        "/var/lib/containers/rss/db:/var/lib/postgresql/data"
      ];
      
      environment = {
        POSTGRES_USER = "miniflux";
        POSTGRES_PASSWORD = "miniflux";
        POSTGRES_DB = "miniflux";
      };
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # Linkding bookmark manager
    linkding = {
      image = "docker.io/sissbruecker/linkding:latest-plus";
      
      volumes = [
        "/var/lib/containers/link:/etc/linkding/data"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.linkding.rule" = "Host(`link.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.linkding.entrypoints" = "websecure";
        "traefik.http.routers.linkding.tls" = "true";
        "traefik.http.routers.linkding.tls.certresolver" = "cloudflare";
        "traefik.http.routers.linkding.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.linkding.loadbalancer.server.port" = "9090";
      };
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # Nextcloud cloud storage and file sharing
    cloud = {
      image = "docker.io/linuxserver/nextcloud:latest";
      
      volumes = [
        "/var/lib/containers/cloud/config:/config"
        "/mnt/storage/appbulk/cloud:/data"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.cloud.rule" = "Host(`cloud.${config.networking.hostName}.yanlincs.com`)";
        "traefik.http.routers.cloud.entrypoints" = "websecure";
        "traefik.http.routers.cloud.tls" = "true";
        "traefik.http.routers.cloud.tls.certresolver" = "cloudflare";
        "traefik.http.routers.cloud.tls.domains[0].main" = "*.${config.networking.hostName}.yanlincs.com";
        "traefik.http.services.cloud.loadbalancer.server.port" = "80";
      };
      
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
        "/var/lib/containers/cloud/db:/config"
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
  };
}