{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.login-display;
in

{
  options.services.login-display = {
    enable = mkEnableOption "login information display on SSH sessions";

    showSmartStatus = mkOption {
      type = types.bool;
      default = false;
      description = "Show SMART disk health status";
    };

    smartDrives = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Drives to monitor for SMART status (device path -> name mapping)";
      example = {
        "/dev/disk/by-id/ata-Samsung_SSD" = "System_SSD";
      };
    };

    showSystemInfo = mkOption {
      type = types.bool;
      default = true;
      description = "Show basic system information (hostname, uptime, load)";
    };

    showDiskUsage = mkOption {
      type = types.bool;
      default = false;
      description = "Show disk usage information";
    };

    diskUsagePaths = mkOption {
      type = types.listOf types.str;
      default = [ "/" ];
      description = "Paths to check for disk usage";
    };

    showBorgStatus = mkOption {
      type = types.bool;
      default = false;
      description = "Show last borg backup status";
    };
  };

  config = mkIf cfg.enable {
    # Add smartmontools if SMART status is enabled
    environment.systemPackages = mkIf cfg.showSmartStatus [ pkgs.smartmontools ];

    # Configure shell login initialization
    programs.zsh.loginShellInit = mkIf config.programs.zsh.enable (
      let
        # ANSI color codes for truecolor (using \033 for better compatibility)
        colors = {
          reset = "\\033[0m";
          dim = "\\033[2m";
          cyan = "\\033[38;2;0;200;255m";
          blue = "\\033[38;2;100;150;255m";
          green = "\\033[38;2;80;250;123m";
          yellow = "\\033[38;2;241;250;140m";
          orange = "\\033[38;2;255;184;108m";
          red = "\\033[38;2;255;85;85m";
          gray = "\\033[38;2;100;100;120m";
        };

        # Build SMART status display
        smartStatusCode = optionalString cfg.showSmartStatus ''
          ${concatStringsSep "\n" (mapAttrsToList (device: name: ''
            if [[ -e "${device}" ]]; then
              # Get health status
              if [[ "${device}" == *"nvme"* ]]; then
                HEALTH_OUTPUT=$(sudo ${pkgs.smartmontools}/bin/smartctl -d nvme -H "${device}" 2>/dev/null)
              else
                HEALTH_OUTPUT=$(sudo ${pkgs.smartmontools}/bin/smartctl -H "${device}" 2>/dev/null)
              fi

              if HEALTH=$(echo "$HEALTH_OUTPUT" | ${pkgs.gnugrep}/bin/grep -o "PASSED\|FAILED" | head -1); then
                : # HEALTH is set
              else
                HEALTH="UNKNOWN"
              fi

              # Get temperature
              TEMP="N/A"
              if [[ "$HEALTH" == "PASSED" ]]; then
                if [[ "${device}" == *"nvme"* ]]; then
                  SMART_DATA=$(sudo ${pkgs.smartmontools}/bin/smartctl -d nvme -A "${device}" 2>/dev/null)
                  TEMP=$(echo "$SMART_DATA" | ${pkgs.gawk}/bin/awk '/^Temperature:/ {print $2}' | head -1)
                  [[ -n "$TEMP" && "$TEMP" =~ ^[0-9]+$ ]] && TEMP="''${TEMP}" || TEMP="N/A"
                else
                  SMART_DATA=$(sudo ${pkgs.smartmontools}/bin/smartctl -A "${device}" 2>/dev/null)
                  TEMP=$(echo "$SMART_DATA" | ${pkgs.gawk}/bin/awk '/Temperature_Celsius/ {print $10}' | head -1)
                  [[ -n "$TEMP" && "$TEMP" =~ ^[0-9]+$ ]] && TEMP="''${TEMP}" || TEMP="N/A"
                fi
              fi

              # Color-code status and temperature
              if [[ "$HEALTH" == "PASSED" ]]; then
                STATUS="\\033[38;2;80;250;123m✓\\033[0m"
                HEALTH_COLOR="\\033[38;2;80;250;123m"
                # Color temp based on value
                if [[ "$TEMP" =~ ^[0-9]+$ ]]; then
                  if [[ $TEMP -ge 70 ]]; then
                    TEMP_COLOR="\\033[38;2;255;85;85m"
                  elif [[ $TEMP -ge 50 ]]; then
                    TEMP_COLOR="\\033[38;2;255;184;108m"
                  else
                    TEMP_COLOR="\\033[38;2;241;250;140m"
                  fi
                  TEMP_STR="$(printf "%b" "''${TEMP_COLOR}''${TEMP}°C\\033[0m")"
                else
                  TEMP_STR="$(printf "%b" "\\033[2m$TEMP\\033[0m")"
                fi
              elif [[ "$HEALTH" == "FAILED" ]]; then
                STATUS="\\033[38;2;255;85;85m✗\\033[0m"
                HEALTH_COLOR="\\033[38;2;255;85;85m"
                TEMP_STR="$(printf "%b" "\\033[2m$TEMP\\033[0m")"
              else
                STATUS="\\033[38;2;241;250;140m⚠\\033[0m"
                HEALTH_COLOR="\\033[38;2;241;250;140m"
                TEMP_STR="$(printf "%b" "\\033[2m$TEMP\\033[0m")"
              fi

              printf "  %b \\033[2m%-15s\\033[0m %b%-7s\\033[0m %s\n" "$STATUS" "${name}" "$HEALTH_COLOR" "$HEALTH" "$TEMP_STR"
            else
              printf "  \\033[38;2;241;250;140m⚠\\033[0m \\033[2m%-15s\\033[0m \\033[38;2;255;85;85m%-20s\\033[0m\n" "${name}" "Not found"
            fi
          '') cfg.smartDrives)}
        '';

        # Build system info display
        systemInfoCode = optionalString cfg.showSystemInfo ''
          # Parse uptime
          UPTIME_STR=$(uptime | ${pkgs.gawk}/bin/awk '{
            match($0, /up\s+(.+?),\s+[0-9]+\s+user/, arr)
            if (arr[1] != "") {
              gsub(/^ +| +$/, "", arr[1])
              # Shorten format: "5 days, 3:42" -> "5d 3h"
              gsub(/ days?,/, "d", arr[1])
              gsub(/ hours?,/, "h", arr[1])
              gsub(/ mins?,/, "m", arr[1])
              gsub(/:[0-9]+$/, "", arr[1])
              print arr[1]
            }
          }')
          LOAD=$(uptime | ${pkgs.gawk}/bin/awk -F'load average:' '{gsub(/^ +| +$/, "", $2); print $2}')

          printf "  \\033[38;2;0;200;255m%s\\033[0m \\033[2m·\\033[0m \\033[2m↑\\033[0m %s \\033[2m· load\\033[0m %s\n" "$(hostname)" "$UPTIME_STR" "$LOAD"
        '';

        # Build disk usage display with bar
        diskUsageCode = optionalString cfg.showDiskUsage ''
          ${concatMapStringsSep "\n" (path: ''
            DF_OUTPUT=$(df -h "${path}" | ${pkgs.gawk}/bin/awk 'NR==2 {print $3, $2, $5}')
            read -r USED TOTAL PCT <<< "$DF_OUTPUT"
            PCT_NUM=''${PCT%\%}

            # Create progress bar (10 chars)
            FILLED=$((PCT_NUM / 10))
            EMPTY=$((10 - FILLED))
            BAR=""
            for ((i=0; i<FILLED; i++)); do BAR="$BAR█"; done
            for ((i=0; i<EMPTY; i++)); do BAR="$BAR░"; done

            # Color bar based on usage
            if [[ $PCT_NUM -ge 90 ]]; then
              BAR_COLOR="\\033[38;2;255;85;85m"
            elif [[ $PCT_NUM -ge 70 ]]; then
              BAR_COLOR="\\033[38;2;255;184;108m"
            elif [[ $PCT_NUM -ge 50 ]]; then
              BAR_COLOR="\\033[38;2;241;250;140m"
            else
              BAR_COLOR="\\033[38;2;80;250;123m"
            fi

            printf "  \\033[2m%-12s\\033[0m %6s/%-6s %b%s\\033[0m %5s\n" "${path}" "$USED" "$TOTAL" "$BAR_COLOR" "$BAR" "$PCT"
          '') cfg.diskUsagePaths}
        '';

        # Build borg backup status display
        borgStatusCode = optionalString cfg.showBorgStatus ''
          # Query journalctl for borg-backup.service
          BORG_LOG=$(journalctl -u borg-backup.service -n 50 --no-pager --output=cat 2>/dev/null || echo "")

          if [[ -z "$BORG_LOG" ]]; then
            # Service never ran
            printf "  \\033[38;2;241;250;140m⚠\\033[0m \\033[2mNever run\\033[0m\n"
          else
            # Check if last backup succeeded
            if echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -q "Backup process completed successfully"; then
              STATUS_SYMBOL="\\033[38;2;80;250;123m✓\\033[0m"
              STATUS_TEXT="SUCCESS"
              STATUS_COLOR="\\033[38;2;80;250;123m"

              # Get timestamp of last successful backup
              LAST_TIMESTAMP=$(journalctl -u borg-backup.service --output=short-iso -n 50 --no-pager 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Backup process completed successfully" | tail -1 | ${pkgs.gawk}/bin/awk '{print $1}')

              if [[ -n "$LAST_TIMESTAMP" ]]; then
                # Calculate time ago
                LAST_EPOCH=$(date -d "$LAST_TIMESTAMP" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$LAST_TIMESTAMP" +%s 2>/dev/null || echo "0")
                NOW_EPOCH=$(date +%s)
                DIFF_SECONDS=$((NOW_EPOCH - LAST_EPOCH))

                if [[ $DIFF_SECONDS -lt 3600 ]]; then
                  TIME_AGO="$((DIFF_SECONDS / 60))m ago"
                elif [[ $DIFF_SECONDS -lt 86400 ]]; then
                  TIME_AGO="$((DIFF_SECONDS / 3600))h ago"
                else
                  TIME_AGO="$((DIFF_SECONDS / 86400))d ago"
                fi

                # Adjust color based on age
                if [[ $DIFF_SECONDS -gt 172800 ]]; then
                  # > 48h - red
                  STATUS_SYMBOL="\\033[38;2;255;85;85m✗\\033[0m"
                  STATUS_COLOR="\\033[38;2;255;85;85m"
                elif [[ $DIFF_SECONDS -gt 86400 ]]; then
                  # 24-48h - yellow
                  STATUS_SYMBOL="\\033[38;2;241;250;140m⚠\\033[0m"
                  STATUS_COLOR="\\033[38;2;241;250;140m"
                fi
              else
                TIME_AGO="Unknown"
              fi

              # Try to extract archive size
              ARCHIVE_SIZE=$(echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -E "Archive:" | tail -1 | ${pkgs.gawk}/bin/awk '{print $2, $3}')

              if [[ -n "$ARCHIVE_SIZE" ]]; then
                printf "  %b \\033[2mLast backup\\033[0m  %b%s\\033[0m  \\033[2m%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_COLOR" "$TIME_AGO" "$ARCHIVE_SIZE"
              else
                printf "  %b \\033[2mLast backup\\033[0m  %b%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_COLOR" "$TIME_AGO"
              fi
            else
              # Check for errors
              if echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -q "ERROR"; then
                STATUS_SYMBOL="\\033[38;2;255;85;85m✗\\033[0m"
                STATUS_TEXT="FAILED"
                printf "  %b \\033[2mLast backup\\033[0m  \\033[38;2;255;85;85m%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_TEXT"
              else
                STATUS_SYMBOL="\\033[38;2;241;250;140m⚠\\033[0m"
                STATUS_TEXT="Unknown"
                printf "  %b \\033[2mLast backup\\033[0m  \\033[38;2;241;250;140m%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_TEXT"
              fi
            fi
          fi
        '';

        # Combine all sections
        hasDisks = cfg.showSmartStatus && (builtins.length (builtins.attrNames cfg.smartDrives) > 0);
        hasStorage = cfg.showDiskUsage && (builtins.length cfg.diskUsagePaths > 0);

      in ''
        if [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_TTY" ]]; then
          echo ""
          printf "\\033[38;2;0;200;255m━━ System ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
          ${systemInfoCode}
          ${optionalString hasDisks ''
            printf "\\033[38;2;100;150;255m━━ Disks ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
            ${smartStatusCode}
          ''}
          ${optionalString hasStorage ''
            printf "\\033[38;2;100;150;255m━━ Storage ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
            ${diskUsageCode}
          ''}
          ${optionalString cfg.showBorgStatus ''
            printf "\\033[38;2;100;150;255m━━ Backup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
            ${borgStatusCode}
          ''}
          echo ""
        fi
      ''
    );

    # Also support bash if needed
    programs.bash.loginShellInit = mkIf (!config.programs.zsh.enable) (
      # Same content as zsh
      programs.zsh.loginShellInit
    );
  };
}
