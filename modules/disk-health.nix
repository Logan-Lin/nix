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
      type = types.str;
      default = "Sun *-*-* 06:00:00";
      description = "Systemd timer frequency (OnCalendar format)";
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
        trap 'curl -s -d "Disk health check FAILED on ${config.networking.hostName}" "${ntfyUrl}" || true; exit 1' ERR
        set -e

        FAILED=0
        REPORT="Disk health on ${config.networking.hostName}"

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
          curl -s -H "Priority: urgent" -H "Tags: warning" -d "$REPORT" "${ntfyUrl}" || true
        else
          curl -s -d "$REPORT" "${ntfyUrl}" || true
        fi
      '';
    };

    systemd.timers.disk-health = {
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
