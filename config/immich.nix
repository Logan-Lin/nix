{
  backup.database = {
    cronExpression = "0 02 * * *";
    enabled = false;  # Using Borg backup instead
    keepLastAmount = 14;
  };

  ffmpeg = {
    accel = "qsv";  # Intel QuickSync Video
    accelDecode = true;

    acceptedAudioCodecs = [ "aac" "mp3" "libopus" "pcm_s16le" ];
    acceptedContainers = [ "mov" "ogg" "webm" ];
    acceptedVideoCodecs = [ "h264" ];

    bframes = -1;  # auto
    cqMode = "auto";
    crf = 23;  # lower = better quality, larger files
    gopSize = 0;  # auto
    maxBitrate = "0";  # unlimited
    preferredHwDevice = "auto";
    preset = "ultrafast";
    refs = 0;  # auto

    targetAudioCodec = "aac";
    targetResolution = "720";
    targetVideoCodec = "h264";

    temporalAQ = false;
    threads = 0;  # all available
    tonemap = "hable";  # HDR to SDR tone mapping
    transcode = "bitrate";
    twoPass = false;
  };

  image = {
    colorspace = "p3";
    extractEmbedded = true;  # from RAW files

    fullsize = {
      enabled = true;
      format = "jpeg";
      quality = 80;
    };

    preview = {
      format = "jpeg";
      quality = 80;
      size = 1440;
    };

    thumbnail = {
      format = "webp";  # smaller files
      quality = 80;
      size = 250;
    };
  };

  job = {
    backgroundTask.concurrency = 5;
    faceDetection.concurrency = 2;  # CPU-intensive
    library.concurrency = 7;
    metadataExtraction.concurrency = 7;
    migration.concurrency = 5;
    notifications.concurrency = 5;
    search.concurrency = 5;
    sidecar.concurrency = 5;
    ocr.concurrency = 1;  # ML-intensive
    smartSearch.concurrency = 2;  # ML-intensive
    thumbnailGeneration.concurrency = 7;
    videoConversion.concurrency = 1;  # serialize for stability
  };

  library = {
    scan = {
      cronExpression = "0 19 * * *";
      enabled = true;
    };
    watch.enabled = false;
  };

  logging = {
    enabled = true;
    level = "log";  # verbose, debug, log, warn, error
  };

  machineLearning = {
    enabled = true;

    clip = {
      enabled = true;
      modelName = "immich-app/ViT-SO400M-16-SigLIP2-384__webli";  # smart search
    };

    duplicateDetection = {
      enabled = false;
      maxDistance = 0.01;  # lower = more similar
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
      modelName = "PP-OCRv5_server";
    };

    urls = [ "http://127.0.0.1:3003" ];  # internal container network
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
    generateMemories = true;
    missingThumbnails = true;
    startTime = "00:00";
    syncQuotaUsage = true;
  };

  notifications.smtp = {
    enabled = false;  # using Gotify instead
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
    enabled = false;  # using local accounts
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
    externalDomain = "https://photo.yanlincs.com";
    loginPageMessage = "";
    publicUsers = true;
  };

  storageTemplate = {
    enabled = true;
    hashVerificationEnabled = true;
    template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";  # year/year-month-day/filename
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
}
