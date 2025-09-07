# Immich photo and video backup system configuration
# This configuration is used by the Immich container in modules/podman.nix
# Documentation: https://immich.app/docs/install/config-file/

{
  # Database backup configuration
  backup.database = {
    cronExpression = "0 02 * * *";  # Daily at 2 AM
    enabled = false;  # Using Borg backup instead
    keepLastAmount = 14;  # Keep 14 days of backups when enabled
  };

  # Video transcoding configuration
  ffmpeg = {
    # Hardware acceleration using Intel QuickSync Video
    accel = "qsv";
    accelDecode = true;
    
    # Accepted codecs for direct playback (no transcoding needed)
    acceptedAudioCodecs = [ "aac" "mp3" "libopus" "pcm_s16le" ];
    acceptedContainers = [ "mov" "ogg" "webm" ];
    acceptedVideoCodecs = [ "h264" ];
    
    # Encoding settings
    bframes = -1;  # Auto-detect optimal B-frames
    cqMode = "auto";
    crf = 23;  # Constant Rate Factor (lower = better quality, larger files)
    gopSize = 0;  # Auto-detect GOP size
    maxBitrate = "0";  # No bitrate limit
    preferredHwDevice = "auto";
    preset = "ultrafast";  # Fastest encoding preset
    refs = 0;  # Auto-detect reference frames
    
    # Target formats for transcoding
    targetAudioCodec = "aac";
    targetResolution = "720";  # Transcode to 720p max
    targetVideoCodec = "h264";
    
    # Advanced settings
    temporalAQ = false;
    threads = 0;  # Use all available CPU threads
    tonemap = "hable";  # HDR to SDR tone mapping algorithm
    transcode = "bitrate";  # Transcoding strategy
    twoPass = false;  # Single-pass encoding for speed
  };

  # Image processing configuration
  image = {
    colorspace = "p3";  # Display P3 color space
    extractEmbedded = true;  # Extract embedded preview images from RAW files
    
    # Full-size image settings
    fullsize = {
      enabled = true;
      format = "jpeg";
      quality = 80;
    };
    
    # Preview image settings (for web UI)
    preview = {
      format = "jpeg";
      quality = 80;
      size = 1440;  # Max dimension in pixels
    };
    
    # Thumbnail settings
    thumbnail = {
      format = "webp";  # Modern format for smaller files
      quality = 80;
      size = 250;  # Max dimension in pixels
    };
  };

  # Background job concurrency settings
  job = {
    backgroundTask.concurrency = 5;
    faceDetection.concurrency = 2;  # CPU-intensive
    library.concurrency = 7;
    metadataExtraction.concurrency = 7;
    migration.concurrency = 5;
    notifications.concurrency = 5;
    search.concurrency = 5;
    sidecar.concurrency = 5;
    smartSearch.concurrency = 2;  # ML-intensive
    thumbnailGeneration.concurrency = 7;
    videoConversion.concurrency = 1;  # Hardware-accelerated, serialize for stability
  };

  # External library management
  library = {
    scan = {
      cronExpression = "0 0 * * *";  # Daily at midnight
      enabled = true;  # Scan external libraries for changes
    };
    watch.enabled = false;  # Don't watch for real-time changes (saves resources)
  };

  # Logging configuration
  logging = {
    enabled = true;
    level = "log";  # Options: verbose, debug, log, warn, error
  };

  # Machine learning configuration
  machineLearning = {
    enabled = true;
    
    # CLIP model for smart search
    clip = {
      enabled = true;
      modelName = "immich-app/ViT-L-16-SigLIP-256__webli";  # Large model for better accuracy
    };
    
    # Duplicate photo detection
    duplicateDetection = {
      enabled = false;
      maxDistance = 0.01;  # Similarity threshold (lower = more similar)
    };
    
    # Facial recognition
    facialRecognition = {
      enabled = true;
      maxDistance = 0.5;  # Face similarity threshold
      minFaces = 3;  # Minimum faces to create a person
      minScore = 0.7;  # Face detection confidence threshold
      modelName = "buffalo_l";  # Large model for better accuracy
    };
    
    # ML processing URLs (internal container network)
    urls = [ "http://127.0.0.1:3003" ];
  };

  # Map configuration for geo-location features
  map = {
    enabled = true;
    darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
    lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
  };

  # Metadata handling
  metadata = {
    faces.import = false;  # Don't import face tags from image metadata
  };

  # Version checking
  newVersionCheck.enabled = false;

  # Nightly maintenance tasks
  nightlyTasks = {
    clusterNewFaces = true;  # Group new faces with existing people
    databaseCleanup = true;  # Clean up orphaned database entries
    generateMemories = true;  # Create "On This Day" memories
    missingThumbnails = true;  # Generate missing thumbnails
    startTime = "00:00";  # Midnight
    syncQuotaUsage = true;  # Update storage quota calculations
  };

  # Email notifications (disabled - using Gotify instead)
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

  # OAuth configuration (disabled - using local accounts)
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

  # Password login configuration
  passwordLogin.enabled = true;

  # Reverse geocoding for location names
  reverseGeocoding.enabled = true;

  # Server configuration
  server = {
    externalDomain = "https://photo.yanlincs.com";  # Public URL
    loginPageMessage = "";
    publicUsers = true;  # Allow public user profiles
  };

  # File organization template
  storageTemplate = {
    enabled = true;
    hashVerificationEnabled = true;  # Verify file integrity
    # Organize files by year/month-day/original-filename
    template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
  };

  # Email templates (empty - using defaults)
  templates.email = {
    albumInviteTemplate = "";
    albumUpdateTemplate = "";
    welcomeTemplate = "";
  };

  # Theme customization
  theme.customCss = "";

  # Trash/recycle bin configuration
  trash = {
    enabled = true;
    days = 30;  # Keep deleted items for 30 days
  };

  # User management
  user = {
    deleteDelay = 7;  # Days before permanently deleting user data
  };
}
