# Disk health monitoring for a host through a systemd service that runs smartctl on the configured devices.
# A host enables it with services.disk-health.enable, lists the devices to check, and optionally sets frequency to run the check on a systemd timer.
# Each run pushes a report of the SMART status and wear level of every device to the ntfy topic, and a failure raises an urgent notification.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.disk-health;
  ntfyUrl = "ntfy.sh/yanlincs-homelab";
in

{
  options.services.disk-health = {
    enable = mkEnableOption "disk health monitoring";

    frequency = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "Sun *-*-* 06:00:00";
      description = "Systemd timer frequency (OnCalendar format). If null, no timer is created and the service must be triggered manually with `systemctl start disk-health.service`.";
    };

    devices = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "/dev/nvme0n1" "/dev/sda" ];
      description = "List of disk device paths to monitor with smartctl";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.disk-health = {
      description = "Disk Health Check";
      path = [ pkgs.smartmontools pkgs.curl pkgs.jq pkgs.coreutils ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
      };

      script = let
        devicesStr = concatStringsSep " " (map (d: "'${d}'") cfg.devices);
      in ''
        trap 'curl -s -H "Title: Disk health@${config.networking.hostName}" -d "FAILED" "${ntfyUrl}" || true; exit 1' ERR
        set -e

        FAILED=0
        REPORT=""

        for dev in ${devicesStr}; do
          JSON=$(smartctl --json=c -a "$dev") || true

          MODEL=$(echo "$JSON" | jq -r '.model_name // empty') || true
          if [ -z "$MODEL" ]; then
            REPORT="$REPORT
        $(basename "$dev"): smartctl error"
            FAILED=1
            continue
          fi

          PASSED=$(echo "$JSON" | jq -r '.smart_status.passed')

          PCT=$(echo "$JSON" | jq -r '.nvme_smart_health_information_log.percentage_used // empty')
          if [ -z "$PCT" ]; then
            # ATA and SATA disks lack the NVMe wear field, so fall back to SMART attributes 177 and 233, the SSD wear leveling indicators.
            # Their normalized value counts down from 100 as the disk wears, so 100 minus the value gives the percentage used.
            PCT=$(echo "$JSON" | jq -r '[(.ata_smart_attributes.table // [])[] | select(.id == 177 or .id == 233) | (100 - .value)] | .[0] // empty')
          fi

          if [ "$PASSED" = "true" ]; then
            HEALTH="PASSED"
          else
            HEALTH="FAILED"
            FAILED=1
          fi

          if [ -n "$PCT" ]; then
            REPORT="$REPORT
        $MODEL: $HEALTH ($PCT% used)"
          else
            REPORT="$REPORT
        $MODEL: $HEALTH"
          fi
        done

        if [ "$FAILED" -eq 1 ]; then
          curl -s -H "Title: Disk health@${config.networking.hostName}" -H "Priority: urgent" -H "Tags: warning" -d "$REPORT" "${ntfyUrl}" || true
        else
          curl -s -H "Title: Disk health@${config.networking.hostName}" -d "$REPORT" "${ntfyUrl}" || true
        fi
      '';
    };

    systemd.timers.disk-health = mkIf (cfg.frequency != null) {
      description = "Disk Health Check Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.frequency;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
