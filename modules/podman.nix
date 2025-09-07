{ config, pkgs, lib, ... }:

let
  # Import Immich configuration from declarative config file
  immichConfig = import ../config/immich.nix;
  
  # Convert Nix configuration to JSON string
  immichConfigJson = builtins.toJSON immichConfig;
  
  # Write config file to a location accessible by the container
  immichConfigFile = pkgs.writeText "immich.json" immichConfigJson;
in
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
          "/var/lib/containers/home/config:/config"
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
          "/var/lib/containers/immich/config:/config"
          "/mnt/storage/appbulk/immich:/photos"
          "/mnt/storage/Media/DCIM:/libraries"
          # Mount the declarative config file
          "${immichConfigFile}:/config/immich.json:ro"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
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
      containers.immich-db = {
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
      containers.immich-redis = {
        image = "docker.io/redis:7.2-alpine";
        
        extraOptions = [
          "--network=podman"
        ];
        
        autoStart = true;
      };

      # Plex Media Server
      containers.plex = {
        image = "docker.io/linuxserver/plex:latest";
        
        volumes = [
          "/var/lib/containers/plex/config:/config"
          "/mnt/storage/appbulk/plex-transcode:/transcode"
          "/mnt/storage/Media:/data"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
          VERSION = "docker";
        };
        
        ports = [
          "32400:32400"
        ];
        
        extraOptions = [
          "--network=podman"
          "--device=/dev/dri:/dev/dri"  # Hardware acceleration
        ];
        
        autoStart = true;
      };

      # Sonarr TV show management
      containers.sonarr = {
        image = "docker.io/linuxserver/sonarr:latest";
        
        volumes = [
          "/var/lib/containers/sonarr/config:/config"
          "/mnt/storage/Media:/data"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
        };
        
        ports = [
          "8989:8989"
        ];
        
        extraOptions = [
          "--network=podman"
        ];
        
        autoStart = true;
      };

      # Radarr movie management
      containers.radarr = {
        image = "docker.io/linuxserver/radarr:latest";
        
        volumes = [
          "/var/lib/containers/radarr/config:/config"
          "/mnt/storage/Media:/data"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
        };
        
        ports = [
          "7878:7878"
        ];
        
        extraOptions = [
          "--network=podman"
        ];
        
        autoStart = true;
      };

      # Bazarr subtitle management
      containers.bazarr = {
        image = "docker.io/linuxserver/bazarr:latest";
        
        volumes = [
          "/var/lib/containers/bazarr/config:/config"
          "/mnt/storage/Media:/data"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
        };
        
        ports = [
          "6767:6767"
        ];
        
        extraOptions = [
          "--network=podman"
        ];
        
        autoStart = true;
      };

      # qBittorrent torrent client with host networking
      containers.qbittorrent = {
        image = "docker.io/linuxserver/qbittorrent:4.6.7";
        
        volumes = [
          "/var/lib/containers/qbit/config:/config"
          "/mnt/storage/Media:/data"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
          TORRENTING_PORT = "41234";
          WEBUI_PORT = "8080";
        };
        
        extraOptions = [
          "--network=host"  # Use host networking as requested
        ];
        
        autoStart = true;
      };

      # Paperless document management system
      containers.paperless = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        
        volumes = [
          "/var/lib/containers/paperless/config:/usr/src/paperless/data"
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
          PAPERLESS_URL = "https://paperless.hs.yanlincs.com";
          PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.hs.yanlincs.com";
          PAPERLESS_ALLOWED_HOSTS = "paperless.hs.yanlincs.com";
          PAPERLESS_CORS_ALLOWED_HOSTS = "https://paperless.hs.yanlincs.com";
          PAPERLESS_SECRET_KEY = "e11fl1oa-*ytql8p)(06fbj4ukrlo+n7k&q5+$1md7i+mge=ee";
          USERMAP_UID = "1000";
          USERMAP_GID = "100";
          CA_TS_FALLBACK_DIR = "/usr/src/paperless/data";
        };
        
        ports = [
          "8001:8000"
        ];
        
        extraOptions = [
          "--network=podman"
        ];
        
        dependsOn = [ "paperless-redis" ];
        autoStart = true;
      };

      # Redis cache for Paperless
      containers.paperless-redis = {
        image = "docker.io/redis:7.2-alpine";
        
        extraOptions = [
          "--network=podman"
        ];
        
        autoStart = true;
      };

      # RSS reader (Miniflux)
      containers.rss = {
        image = "docker.io/miniflux/miniflux:latest";
        
        environment = {
          DATABASE_URL = "postgres://miniflux:miniflux@rss-db/miniflux?sslmode=disable";
          ADMIN_USERNAME = "yanlin";
          ADMIN_PASSWORD = "1Hayashi-2Hiko";
          BASE_URL = "https://rss.hs.yanlincs.com";
          CREATE_ADMIN = "1";
          RUN_MIGRATIONS = "1";
          HTTP_CLIENT_TIMEOUT = "50000";
          POLLING_FREQUENCY = "60";
          CLEANUP_FREQUENCY_HOURS = "24";
          CLEANUP_ARCHIVE_READ_DAYS = "60";
          CLEANUP_REMOVE_SESSIONS_DAYS = "30";
        };
        
        ports = [
          "8002:8080"
        ];
        
        extraOptions = [
          "--network=podman"
        ];
        
        dependsOn = [ "rss-db" ];
        autoStart = true;
      };

      # PostgreSQL database for RSS (Miniflux)
      containers.rss-db = {
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
      containers.linkding = {
        image = "docker.io/sissbruecker/linkding:latest-plus";
        
        volumes = [
          "/var/lib/containers/link:/etc/linkding/data"
        ];
        
        ports = [
          "9090:9090"
        ];
        
        extraOptions = [
          "--network=podman"
        ];
        
        autoStart = true;
      };

      # Nextcloud cloud storage and file sharing
      containers.cloud = {
        image = "docker.io/linuxserver/nextcloud:latest";
        
        volumes = [
          "/var/lib/containers/cloud/config:/config"
          "/mnt/storage/appbulk/cloud:/data"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
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
      containers.cloud-db = {
        image = "docker.io/linuxserver/mariadb:latest";
        
        volumes = [
          "/var/lib/containers/cloud/db:/config"
        ];
        
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Copenhagen";
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
  };
}
