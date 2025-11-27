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

  };
}
