# NOTE: Passphrase file at: `/etc/borg-passphrase` with mode 600
# content: `BORG_PASSPHRASE=your-passphrase`

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.borg-client-custom;
  sshCommand = "ssh -F /home/yanlin/.ssh/config -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=60 -o ServerAliveCountMax=240";
  passphraseFile = "/etc/borg-passphrase";
  excludePatterns = [
    "*.tmp" "*.temp" "*/.cache/*" "*/.local/share/Trash/*" "*/tmp/*" "*/temp/*"
    "/proc/*" "/sys/*" "/dev/*" "/run/*" "/var/tmp/*" "/var/cache/*" "/var/log/*"
    "*/overlay2/*" "*/containers/storage/overlay/*"
    ".DS_Store" "._.DS_Store" ".Spotlight-V100" ".TemporaryItems" ".Trashes" ".fseventsd"
    "node_modules/*" "target/*" "*.o" "*.so" "*.pyc" "__pycache__/*"
    ".vscode/*" "*.swp" "*.swo" "*~"
  ];
  excludeArgs = concatMapStrings (pattern: " --exclude '${pattern}'") excludePatterns;
in

{
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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.borgbackup ];

    users.users.borg-backup = {
      isSystemUser = true;
      group = "borg-backup";
      description = "Borg backup user";
    };
    users.groups.borg-backup = {};

    systemd.services.borg-backup = {
      description = "Borg Backup Service";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ pkgs.borgbackup pkgs.openssh pkgs.curl ];

      unitConfig = {
        ConditionPathExists = "!/run/borg-backup.lock";
      };

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStartPre = "${pkgs.coreutils}/bin/touch /run/borg-backup.lock";
        ExecStopPost = "${pkgs.coreutils}/bin/rm -f /run/borg-backup.lock";
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = mkIf (!(lib.hasPrefix "ssh://" cfg.repositoryUrl)) "read-only";
        ReadWritePaths = [ "/run" ] ++ (if (lib.hasPrefix "ssh://" cfg.repositoryUrl) then [] else [ cfg.repositoryUrl ]);
        Environment = [
          "BORG_REPO=${cfg.repositoryUrl}"
          "BORG_RELOCATED_REPO_ACCESS_IS_OK=yes"
          "BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no"
        ];
        EnvironmentFile = passphraseFile;
      };

      script = let
        backupPathsStr = concatStringsSep " " (map (path: "'${path}'") cfg.backupPaths);
        retentionArgs = with cfg.retention; concatStringsSep " " [
          "--keep-daily ${toString keepDaily}"
          "--keep-weekly ${toString keepWeekly}"
          "--keep-monthly ${toString keepMonthly}"
          "--keep-yearly ${toString keepYearly}"
        ];
      in ''
        trap 'echo "ERROR: Critical backup failure with exit code $? at line $LINENO" >&2; exit 1' ERR
        set -e

        export BORG_RSH="${sshCommand}"

        if [ -f "${passphraseFile}" ]; then
          source "${passphraseFile}"
        fi

        if [[ "${cfg.repositoryUrl}" == ssh://* ]]; then
          mkdir -p /root/.ssh
          chmod 700 /root/.ssh

          if [ -f /home/yanlin/.ssh/config ]; then
            cp /home/yanlin/.ssh/config /root/.ssh/config
            chmod 600 /root/.ssh/config
          fi

          if [ -d /home/yanlin/Credentials/ssh_keys ]; then
            mkdir -p /root/Credentials
            cp -r /home/yanlin/Credentials/ssh_keys /root/Credentials/
            chmod -R 600 /root/Credentials/ssh_keys
          fi

          if [ -f /home/yanlin/.ssh/known_hosts ]; then
            cp /home/yanlin/.ssh/known_hosts /root/.ssh/known_hosts
            chmod 600 /root/.ssh/known_hosts
          fi
        fi

        if ! borg info > /dev/null 2>&1; then
          echo "Initializing Borg repository at ${cfg.repositoryUrl}"
          borg init --encryption=repokey-blake2
        fi

        ARCHIVE_NAME="backup-$(date +%Y-%m-%d_%H-%M-%S)"
        echo "Creating backup archive: $ARCHIVE_NAME"

        BACKUP_START=$(date +%s)
        borg create \
          --verbose \
          --stats \
          --progress \
          --compression lz4,6 \
          --exclude-caches \
          ${excludeArgs} \
          "::$ARCHIVE_NAME" \
          ${backupPathsStr} 2>&1 | tee /tmp/borg-create-output.log
        BACKUP_END=$(date +%s)
        BACKUP_DURATION=$((BACKUP_END - BACKUP_START))

        set +e

        echo "Pruning old backups..."
        if ! borg prune \
          --list \
          --prefix 'backup-' \
          --show-rc \
          ${retentionArgs}; then
          echo "WARNING: Pruning failed, but backup archive was created successfully" >&2
        fi

        echo "Compacting repository..."
        if ! borg compact; then
          echo "WARNING: Compacting failed, but backup archive was created successfully" >&2
        fi

        {
          echo "Extracting backup statistics..."
          BACKUP_STATS="Duration: ''${BACKUP_DURATION}s"

          if [ -f /tmp/borg-create-output.log ]; then
            ARCHIVE_SIZE=$(grep -E "This archive:" /tmp/borg-create-output.log | awk '{print $3, $4}' 2>/dev/null || echo "")
            if [ -n "''$ARCHIVE_SIZE" ]; then
              BACKUP_STATS="''$BACKUP_STATS, Archive: ''$ARCHIVE_SIZE"
            fi

            DEDUPE_SIZE=$(grep -E "This archive:.*Deduplicated size" /tmp/borg-create-output.log | awk '{for(i=1;i<=NF;i++) if($i~/[0-9]/) print $(i) " " $(i+1); break}' 2>/dev/null || echo "")
            if [ -z "''$DEDUPE_SIZE" ]; then
              DEDUPE_SIZE=$(grep -A 1 -E "This archive:" /tmp/borg-create-output.log | tail -1 | awk '{print ''$NF-1, ''$NF}' 2>/dev/null || echo "")
            fi
            if [ -n "''$DEDUPE_SIZE" ]; then
              BACKUP_STATS="''$BACKUP_STATS, Deduplicated: ''$DEDUPE_SIZE"
            fi

            rm -f /tmp/borg-create-output.log 2>/dev/null || true
          fi

          BACKUP_STATS="Backup completed successfully. ''$BACKUP_STATS"
          echo "Backup statistics: ''$BACKUP_STATS"

        } || {
          echo "WARNING: Statistics extraction failed, but backup succeeded" >&2
          echo "Backup completed successfully for ${config.networking.hostName}"
        }

        echo "Backup process completed successfully"
      '';
    };

    systemd.timers.borg-backup = {
      description = "Borg Backup Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.backupFrequency;
        Persistent = true;
        RandomizedDelaySec = "30min";
      };
    };

    systemd.targets.multi-user.wants = [ "borg-backup.timer" ];

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

    environment.shellAliases = {
      borg-init = "BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${sshCommand}' borg init --encryption=repokey-blake2";
      borg-status = "systemctl status borg-backup.service borg-backup.timer";
      borg-logs = "journalctl -u borg-backup.service -f";
      borg-backup-now = "sudo systemctl start borg-backup.service";
      borg-list = "BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${sshCommand}' borg list";
      borg-info = "BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${sshCommand}' borg info";
      borg-unlock = "sudo rm -f /run/borg-backup.lock && BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${sshCommand}' borg break-lock";
    };
  };
}
