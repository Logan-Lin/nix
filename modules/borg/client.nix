# NOTE: Passphrase file at: `/etc/borg-passphrase` with mode 600
# content: `BORG_PASSPHRASE=your-passphrase`

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.borg-client-custom;
  sshCommand = "ssh -F /home/yanlin/.ssh/config -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=60 -o ServerAliveCountMax=240";
  passphraseFile = "/etc/borg-passphrase";
  excludePatterns = [
    "**/.stversions/"
    "**/.syncthing.*.tmp"
  ];
  excludeArgs = concatMapStrings (pattern: " --exclude '${pattern}'") excludePatterns;
  ntfyUrl = "ntfy.sh/yanlincs-homelab";
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

    checkFrequency = mkOption {
      type = types.str;
      default = "Sun *-*-* 12:00:00";
      description = "Systemd timer frequency for borg check";
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
        trap 'curl -s -d "Borg backup FAILED on ${config.networking.hostName} (exit $? at line $LINENO)" "${ntfyUrl}" || true; exit 1' ERR
        set -e

        export BORG_RSH="${sshCommand}"

        if [ -f "${passphraseFile}" ]; then
          source "${passphraseFile}"
        fi

        if [[ "${cfg.repositoryUrl}" == ssh://* ]]; then
          mkdir -p /root/.ssh && chmod 700 /root/.ssh
          [ -f /home/yanlin/.ssh/config ] && cp /home/yanlin/.ssh/config /root/.ssh/config && chmod 600 /root/.ssh/config
          [ -d /home/yanlin/Credentials/ssh_keys ] && mkdir -p /root/Credentials && cp -r /home/yanlin/Credentials/ssh_keys /root/Credentials/ && chmod -R 600 /root/Credentials/ssh_keys
          [ -f /home/yanlin/.ssh/known_hosts ] && cp /home/yanlin/.ssh/known_hosts /root/.ssh/known_hosts && chmod 600 /root/.ssh/known_hosts
        fi

        if ! borg info > /dev/null 2>&1; then
          borg init --encryption=repokey-blake2
        fi

        BACKUP_START=$(date +%s)
        borg create \
          --verbose --stats \
          --compression lz4,6 \
          --exclude-caches \
          ${excludeArgs} \
          "::backup-$(date +%Y-%m-%d_%H-%M-%S)" \
          ${backupPathsStr}
        BACKUP_DURATION=$(( $(date +%s) - BACKUP_START ))

        set +e
        borg prune --list --prefix 'backup-' --show-rc ${retentionArgs} || true
        borg compact || true

        curl -s -d "Backup OK on ${config.networking.hostName} (''${BACKUP_DURATION}s)" "${ntfyUrl}" || true
      '';
    };

    systemd.services.borg-check = {
      description = "Borg Repository Check";
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

      script = ''
        trap 'curl -s -d "Borg check FAILED on ${config.networking.hostName} (exit $? at line $LINENO)" "${ntfyUrl}" || true; exit 1' ERR
        set -e

        export BORG_RSH="${sshCommand}"

        if [ -f "${passphraseFile}" ]; then
          source "${passphraseFile}"
        fi

        if [[ "${cfg.repositoryUrl}" == ssh://* ]]; then
          mkdir -p /root/.ssh && chmod 700 /root/.ssh
          [ -f /home/yanlin/.ssh/config ] && cp /home/yanlin/.ssh/config /root/.ssh/config && chmod 600 /root/.ssh/config
          [ -d /home/yanlin/Credentials/ssh_keys ] && mkdir -p /root/Credentials && cp -r /home/yanlin/Credentials/ssh_keys /root/Credentials/ && chmod -R 600 /root/Credentials/ssh_keys
          [ -f /home/yanlin/.ssh/known_hosts ] && cp /home/yanlin/.ssh/known_hosts /root/.ssh/known_hosts && chmod 600 /root/.ssh/known_hosts
        fi

        CHECK_START=$(date +%s)
        borg check --verbose --last 7
        CHECK_DURATION=$(( $(date +%s) - CHECK_START ))

        curl -s -d "Borg check OK on ${config.networking.hostName} (''${CHECK_DURATION}s)" "${ntfyUrl}" || true
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

    systemd.timers.borg-check = {
      description = "Borg Repository Check Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.checkFrequency;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    systemd.targets.multi-user.wants = [ "borg-backup.timer" "borg-check.timer" ];

    environment.shellAliases = {
      borg-unlock = "sudo rm -f /run/borg-backup.lock && BORG_REPO='${cfg.repositoryUrl}' BORG_RSH='${sshCommand}' borg break-lock";
    };
  };
}
