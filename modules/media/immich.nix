{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.immich-custom;

  immichConfig = {
    backup.database = {
      cronExpression = "0 02 * * *";
      enabled = false;
      keepLastAmount = 14;
    };

    ffmpeg = {
      accel = "vaapi";
      accelDecode = true;

      acceptedAudioCodecs = [ "aac" "mp3" "libopus" "pcm_s16le" ];
      acceptedContainers = [ "mov" "ogg" "webm" ];
      acceptedVideoCodecs = [ "h264" "hevc" ];

      bframes = -1;
      cqMode = "auto";
      crf = 28;
      gopSize = 0;
      maxBitrate = "0";
      preferredHwDevice = "auto";
      preset = "ultrafast";
      refs = 0;

      targetAudioCodec = "aac";
      targetResolution = "720";
      targetVideoCodec = "hevc";

      temporalAQ = false;
      threads = 0;
      tonemap = "hable";
      transcode = "bitrate";
      twoPass = false;
    };

    image = {
      colorspace = "p3";
      extractEmbedded = true;

      fullsize.enabled = false;

      preview = {
        format = "jpeg";
        quality = 80;
        size = 1080;
      };

      thumbnail = {
        format = "webp";
        quality = 80;
        size = 250;
      };
    };

    job = {
      backgroundTask.concurrency = 3;
      faceDetection.concurrency = 1;
      library.concurrency = 5;
      metadataExtraction.concurrency = 5;
      migration.concurrency = 5;
      notifications.concurrency = 5;
      search.concurrency = 5;
      sidecar.concurrency = 5;
      ocr.concurrency = 1;
      smartSearch.concurrency = 1;
      thumbnailGeneration.concurrency = 3;
      videoConversion.concurrency = 1;
    };

    library = {
      scan = {
        cronExpression = "0 19 * * *";
        enabled = true;
      };
      watch.enabled = true;
    };

    logging = {
      enabled = true;
      level = "log";
    };

    machineLearning = {
      enabled = true;

      clip = {
        enabled = true;
        modelName = "immich-app/ViT-B-16-SigLIP2__webli";
      };

      duplicateDetection = {
        enabled = false;
        maxDistance = 0.01;
      };

      facialRecognition = {
        enabled = true;
        maxDistance = 0.5;
        minFaces = 3;
        minScore = 0.7;
        modelName = "buffalo_l";
      };

      ocr = {
        enabled = true;
        maxResolution = 736;
        minDetectionScore = 0.5;
        minRecognitionScore = 0.8;
        modelName = "PP-OCRv5_mobile";
      };

      urls = [ "http://127.0.0.1:3003" ];
    };

    map = {
      enabled = true;
      darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
      lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
    };

    metadata = {
      faces.import = false;
    };

    newVersionCheck.enabled = false;

    nightlyTasks = {
      clusterNewFaces = true;
      databaseCleanup = true;
      generateMemories = false;
      missingThumbnails = true;
      startTime = "00:00";
      syncQuotaUsage = true;
    };

    notifications.smtp = {
      enabled = false;
      from = "";
      replyTo = "";
      transport = {
        host = "";
        ignoreCert = false;
        password = "";
        port = 587;
        username = "";
      };
    };

    oauth = {
      enabled = false;
      autoLaunch = false;
      autoRegister = true;
      buttonText = "Login with OAuth";
      clientId = "";
      clientSecret = "";
      defaultStorageQuota = null;
      issuerUrl = "";
      mobileOverrideEnabled = false;
      mobileRedirectUri = "";
      profileSigningAlgorithm = "none";
      roleClaim = "immich_role";
      scope = "openid email profile";
      signingAlgorithm = "RS256";
      storageLabelClaim = "preferred_username";
      storageQuotaClaim = "immich_quota";
      timeout = 30000;
      tokenEndpointAuthMethod = "client_secret_post";
    };

    passwordLogin.enabled = true;

    reverseGeocoding.enabled = true;

    server = {
      externalDomain = cfg.externalDomain;
      loginPageMessage = "";
      publicUsers = true;
    };

    storageTemplate = {
      enabled = true;
      hashVerificationEnabled = true;
      template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
    };

    templates.email = {
      albumInviteTemplate = "";
      albumUpdateTemplate = "";
      welcomeTemplate = "";
    };

    theme.customCss = "";

    trash = {
      enabled = true;
      days = 30;
    };

    user = {
      deleteDelay = 7;
    };
  };

  immichConfigFile = pkgs.writeText "immich.json" (builtins.toJSON immichConfig);

  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in

{
  options.services.immich-custom = {
    enable = mkEnableOption "Immich photo management service";

    photoDir = mkOption {
      type = types.str;
      description = "Directory for the photo library";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Host port for the Immich web UI";
    };

    externalDomain = mkOption {
      type = types.str;
      default = "";
      description = "Public-facing URL for Immich";
    };

    gpuDevice = mkOption {
      type = types.nullOr types.str;
      default = "/dev/dri";
      description = "GPU device path for VAAPI hardware acceleration, null to disable";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {

      immich = {
        image = "ghcr.io/imagegenius/immich:latest";

        volumes = [
          "/var/lib/immich/config:/config"
          "${cfg.photoDir}:/photos"
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
          "${toString cfg.port}:8080"
        ];

        extraOptions = [
          "--network=podman"
        ] ++ optionals (cfg.gpuDevice != null) [
          "--device=${cfg.gpuDevice}:${cfg.gpuDevice}"
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
  };
}
