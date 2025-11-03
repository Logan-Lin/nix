{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.borg-client-custom;
in

{
    # options.services.borgbackup-custom = {
  options.services.borg-client-custom = {
    enable = mkEnableOption "Borg backup service";

    repositoryUrl = mkOption {
      type = types.str;
      example = "/mnt/backup/borg-repo";
      description = "Borg repository URL (local path or remote SSH URL)";
    };

    backupPaths = mkOption {
      type = types.listOf types.str;
      default = [ "/home" "/var/lib/containers" ];
      example = [ "/home" "/var/lib/containers" "/etc" ];
      description = "List of directories to backup";
    };

    backupFrequency = mkOption {
      type = types.str;
      default = "daily";
      example = "hourly";
      description = "Systemd timer frequency (OnCalendar format or shortcuts like daily, hourly)";
    };

    retention = mkOption {
      type = types.submodule {
        options = {
          keepDaily = mkOption {
            type = types.int;
            default = 7;
            description = "Number of daily backups to keep";
          };
          keepWeekly = mkOption {
            type = types.int;
            default = 4;
            description = "Number of weekly backups to keep";
          };
          keepMonthly = mkOption {
            type = types.int;
            default = 6;
            description = "Number of monthly backups to keep";
          };
          keepYearly = mkOption {
            type = types.int;
            default = 2;
            description = "Number of yearly backups to keep";
          };
        };
      };
      default = {};
      description = "Backup retention policy";
    };

    excludePatterns = mkOption {
      type = types.listOf types.str;
      default = [
        # Temporary and cache files
        "*.tmp"
        "*.temp"
        "*/.cache/*"
        "*/.local/share/Trash/*"
        "*/tmp/*"
        "*/temp/*"
        
        # System files
        "/proc/*"
        "/sys/*"
        "/dev/*"
        "/run/*"
        "/var/tmp/*"
        "/var/cache/*"
        "/var/log/*"
        
        # Container runtime files
        "*/overlay2/*"
        "*/containers/storage/overlay/*"
        
        # macOS metadata
        ".DS_Store"
        "._.DS_Store"
        ".Spotlight-V100"
        ".TemporaryItems"
        ".Trashes"
        ".fseventsd"
        
        # Build artifacts and dependencies
        "node_modules/*"
        "target/*"
        "*.o"
        "*.so"
        "*.pyc"
        "__pycache__/*"
        
        # Editor and IDE files
        ".vscode/*"
        "*.swp"
        "*.swo"
        "*~"
      ];
      description = "List of patterns to exclude from backup";
    };

    compressionLevel = mkOption {
      type = types.int;
      default = 6;
      description = "Borg compression level (0-9, where 6 is balanced)";
    };

    passphraseFile = mkOption {
      type = types.str;
      default = "/etc/borg-passphrase";
      description = "Path to file containing BORG_PASSPHRASE=yourpassphrase";
    };

    sshCommand = mkOption {
      type = types.str;
      default = "ssh -F /home/yanlin/.ssh/config -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=60 -o ServerAliveCountMax=240";
      description = "SSH command for remote repositories (uses SSH config for host aliases with keepalive)";
    };

    preHook = mkOption {
      type = types.str;
      default = "";
      example = "echo 'Starting backup...'";
      description = "Commands to run before backup";
    };

    postHook = mkOption {
      type = types.str;
      default = "";
      example = "echo 'Backup completed.'";
      description = "Commands to run after successful backup";
    };
  };

  config = mkIf cfg.enable {
    # Install Borg package
    environment.systemPackages = [ pkgs.borgbackup ];

    # Create backup user for better isolation (optional)
    users.users.borg-backup = {
      isSystemUser = true;
      group = "borg-backup";
      description = "Borg backup user";
    };
    users.groups.borg-backup = {};

    # Systemd service for backup
    systemd.services.borg-backup = {
      description = "Borg Backup Service";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      # Add borg and required tools to the service's PATH
      path = [ pkgs.borgbackup pkgs.openssh pkgs.curl ];

      # Prevent concurrent backup runs
      unitConfig = {
        ConditionPathExists = "!/run/borg-backup.lock";
      };

      serviceConfig = {
        Type = "oneshot";
        User = "root";  # Need root to access all backup paths
        Group = "root";

        # Create lock file on start, remove on stop
        ExecStartPre = "${pkgs.coreutils}/bin/touch /run/borg-backup.lock";
        ExecStopPost = "${pkgs.coreutils}/bin/rm -f /run/borg-backup.lock";

        # Security settings
        PrivateTmp = true;
        ProtectSystem = "strict";
        # Disable ProtectHome for SSH repositories to allow SSH key access
        ProtectHome = mkIf (!(lib.hasPrefix "ssh://" cfg.repositoryUrl)) "read-only";
        # Add ReadWritePaths for lock file and local repositories
        ReadWritePaths = [ "/run" ] ++ (if (lib.hasPrefix "ssh://" cfg.repositoryUrl) then [] else [ cfg.repositoryUrl ]);
        
        # Environment
        Environment = [
          "BORG_REPO=${cfg.repositoryUrl}"
          "BORG_RELOCATED_REPO_ACCESS_IS_OK=yes"
          "BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no"
        ];
        EnvironmentFile = mkIf (cfg.passphraseFile != "") cfg.passphraseFile;
      };

      script = let
        excludeArgs = concatMapStrings (pattern: " --exclude '${pattern}'") cfg.excludePatterns;
        backupPathsStr = concatStringsSep " " (map (path: "'${path}'") cfg.backupPaths);
        retentionArgs = with cfg.retention; concatStringsSep " " [
          "--keep-daily ${toString keepDaily}"
          "--keep-weekly ${toString keepWeekly}"
          "--keep-monthly ${toString keepMonthly}"
          "--keep-yearly ${toString keepYearly}"
        ];
      in ''
        # Error handling
        trap 'echo "ERROR: Critical backup failure with exit code $? at line $LINENO" >&2; exit 1' ERR
        set -e
        
        # Set SSH command for remote repositories
        export BORG_RSH="${cfg.sshCommand}"
        
        # Load passphrase from environment file
        if [ -f "${cfg.passphraseFile}" ]; then
          source "${cfg.passphraseFile}"
        fi
        
        # Ensure root has access to SSH keys for remote repositories
        if [[ "${cfg.repositoryUrl}" == ssh://* ]]; then
          mkdir -p /root/.ssh
          chmod 700 /root/.ssh
          
          # Copy SSH config if it exists
          if [ -f /home/yanlin/.ssh/config ]; then
            cp /home/yanlin/.ssh/config /root/.ssh/config
            chmod 600 /root/.ssh/config
          fi
          
          # Copy necessary SSH keys
          if [ -d /home/yanlin/.ssh/keys ]; then
            cp -r /home/yanlin/.ssh/keys /root/.ssh/
            chmod -R 600 /root/.ssh/keys
          fi
          
          # Copy known_hosts to avoid host key verification issues
          if [ -f /home/yanlin/.ssh/known_hosts ]; then
            cp /home/yanlin/.ssh/known_hosts /root/.ssh/known_hosts
            chmod 600 /root/.ssh/known_hosts
          fi
        fi
        
        # Pre-hook
        ${cfg.preHook}
        
        # Initialize repository if it doesn't exist
        if ! borg info > /dev/null 2>&1; then
          echo "Initializing Borg repository at ${cfg.repositoryUrl}"
          borg init --encryption=repokey-blake2
        fi
        
        # Create backup archive with timestamp
        ARCHIVE_NAME="backup-$(date +%Y-%m-%d_%H-%M-%S)"
        echo "Creating backup archive: $ARCHIVE_NAME"
        
        # Capture borg create output for statistics
        BACKUP_START=$(date +%s)
        borg create \
          --verbose \
          --stats \
          --progress \
          --compression lz4,${toString cfg.compressionLevel} \
          --exclude-caches \
          ${excludeArgs} \
          "::$ARCHIVE_NAME" \
          ${backupPathsStr} 2>&1 | tee /tmp/borg-create-output.log
        BACKUP_END=$(date +%s)
        BACKUP_DURATION=$((BACKUP_END - BACKUP_START))
        
        # Disable error trap for non-critical operations
        set +e
        
        # Prune old backups (non-critical)
        echo "Pruning old backups..."
        if ! borg prune \
          --list \
          --prefix 'backup-' \
          --show-rc \
          ${retentionArgs}; then
          echo "WARNING: Pruning failed, but backup archive was created successfully" >&2
        fi
        
        # Compact repository to free space (non-critical)
        echo "Compacting repository..."
        if ! borg compact; then
          echo "WARNING: Compacting failed, but backup archive was created successfully" >&2
        fi
        
        # Re-enable error trap for critical operations only if needed
        # set -e
        
        # Post-hook (allow failures)
        if [ -n "${cfg.postHook}" ]; then
          echo "Running post-hook..."
          (
            ${cfg.postHook}
          ) || echo "WARNING: Post-hook execution failed" >&2
        fi
        
        # Extract and send success notification (non-blocking)
        {
          echo "Extracting backup statistics..."
          
          # Robust statistics parsing with multiple fallbacks
          BACKUP_STATS="Duration: ''${BACKUP_DURATION}s"
          
          if [ -f /tmp/borg-create-output.log ]; then
            # Try to extract archive size
            ARCHIVE_SIZE=$(grep -E "This archive:" /tmp/borg-create-output.log | awk '{print $3, $4}' 2>/dev/null || echo "")
            if [ -n "''$ARCHIVE_SIZE" ]; then
              BACKUP_STATS="''$BACKUP_STATS, Archive: ''$ARCHIVE_SIZE"
            fi
            
            # Try to extract deduplicated size  
            DEDUPE_SIZE=$(grep -E "This archive:.*Deduplicated size" /tmp/borg-create-output.log | awk '{for(i=1;i<=NF;i++) if($i~/[0-9]/) print $(i) " " $(i+1); break}' 2>/dev/null || echo "")
            if [ -z "''$DEDUPE_SIZE" ]; then
              # Alternative pattern matching
              DEDUPE_SIZE=$(grep -A 1 -E "This archive:" /tmp/borg-create-output.log | tail -1 | awk '{print ''$NF-1, ''$NF}' 2>/dev/null || echo "")
            fi
            if [ -n "''$DEDUPE_SIZE" ]; then
              BACKUP_STATS="''$BACKUP_STATS, Deduplicated: ''$DEDUPE_SIZE"
            fi
            
            rm -f /tmp/borg-create-output.log 2>/dev/null || true
          fi
          
          # Add basic success info
          BACKUP_STATS="Backup completed successfully. ''$BACKUP_STATS"

          echo "Backup statistics: ''$BACKUP_STATS"

        } || {
          echo "WARNING: Statistics extraction failed, but backup succeeded" >&2
          echo "Backup completed successfully for ${config.networking.hostName}"
        }
        
        echo "Backup process completed successfully"
      '';
    };

    # Systemd timer for scheduled backups
    systemd.timers.borg-backup = {
      description = "Borg Backup Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.backupFrequency;
        Persistent = true;
        RandomizedDelaySec = "30min";  # Add some randomization to avoid load spikes
      };
    };

    # Enable and start the backup timer
    systemd.targets.multi-user.wants = [ "borg-backup.timer" ];

    # Create a convenience script for manual backups
    environment.etc."borg-backup-manual" = {
      text = ''
        echo "Starting manual Borg backup..."
        systemctl start borg-backup.service
        
        echo "Checking backup status..."
        systemctl status borg-backup.service
        
        echo "Recent backup logs:"
        journalctl -u borg-backup.service -n 20
      '';
      mode = "0755";
    };

    # Helpful aliases for managing backups
    environment.shellAliases = {
      borg-init = "BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${cfg.sshCommand}' borg init --encryption=repokey-blake2";
      borg-status = "systemctl status borg-backup.service borg-backup.timer";
      borg-logs = "journalctl -u borg-backup.service -f";
      borg-backup-now = "sudo systemctl start borg-backup.service";
      borg-list = "BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${cfg.sshCommand}' borg list";
      borg-info = "BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${cfg.sshCommand}' borg info";
      borg-unlock = "sudo rm -f /run/borg-backup.lock && BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${cfg.sshCommand}' borg break-lock";
    };
  };
}
