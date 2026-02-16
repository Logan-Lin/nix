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
  virtualisation.oci-containers.containers = {

    immich = {
      image = "ghcr.io/imagegenius/immich:2.5.6";
      
      volumes = [
        "/var/lib/immich/config:/config"
        "/mnt/storage/photos:/photos"
        "${immichConfigFile}:/config/immich.json:ro"
      ];
      
      environment = {
        PUID = commonUID;
        PGID = commonGID;
        TZ = systemTZ;
        IMMICH_CONFIG_FILE = "/config/immich.json";
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
        "8080:8080"
      ];
      
      extraOptions = [
        "--network=podman"
        "--device=/dev/dri:/dev/dri"
      ];
      
      dependsOn = [ "immich-db" "immich-redis" ];
      autoStart = true;
    };

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

    immich-redis = {
      image = "docker.io/redis:7.2-alpine";
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

  };
}
