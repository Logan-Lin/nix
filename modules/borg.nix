{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.borgbackup-custom;
in

{
  options.services.borgbackup-custom = {
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
      default = "ssh -F /home/yanlin/.ssh/config -o StrictHostKeyChecking=accept-new";
      description = "SSH command for remote repositories (uses SSH config for host aliases)";
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
      
      # Add borg to the service's PATH
      path = [ pkgs.borgbackup pkgs.openssh ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";  # Need root to access all backup paths
        Group = "root";
        
        # Security settings
        PrivateTmp = true;
        ProtectSystem = "strict";
        # Disable ProtectHome for SSH repositories to allow SSH key access
        ProtectHome = mkIf (!(lib.hasPrefix "ssh://" cfg.repositoryUrl)) "read-only";
        # Only add ReadWritePaths for local repositories
        ReadWritePaths = mkIf (!(lib.hasPrefix "ssh://" cfg.repositoryUrl)) [ cfg.repositoryUrl ];
        
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
        
        borg create \
          --verbose \
          --stats \
          --progress \
          --compression lz4,${toString cfg.compressionLevel} \
          --exclude-caches \
          ${excludeArgs} \
          "::$ARCHIVE_NAME" \
          ${backupPathsStr}
        
        # Prune old backups
        echo "Pruning old backups..."
        borg prune \
          --list \
          --prefix 'backup-' \
          --show-rc \
          ${retentionArgs}
        
        # Compact repository to free space
        echo "Compacting repository..."
        borg compact
        
        # Post-hook
        ${cfg.postHook}
        
        echo "Backup completed successfully"
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

    # Enable and start the timer
    systemd.targets.multi-user.wants = [ "borg-backup.timer" ];

    # Create a convenience script for manual backups
    environment.etc."borg-backup-manual" = {
      text = ''
        #!/usr/bin/env bash
        
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
    };
  };
}
