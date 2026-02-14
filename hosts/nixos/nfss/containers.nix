{ config, pkgs, lib, ... }:

let
  immichConfig = import ../../../config/immich.nix;
  immichConfigJson = builtins.toJSON immichConfig;
  immichConfigFile = pkgs.writeText "immich.json" immichConfigJson;

  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in
{
  # Container definitions for nfss host
  virtualisation.oci-containers.containers = {

    # Immich photo and video backup system
    immich = {
      image = "ghcr.io/imagegenius/immich:latest";

      volumes = [
        "/var/lib/immich/config:/config"
        "/mnt/essd/immich-lib:/photos"
        "/mnt/essd/DCIM:/ext-lib:ro"
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
        "8080:8080"
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
        "/var/lib/immich/db:/var/lib/postgresql/data"
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

  };
}
