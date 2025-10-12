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

    showContainerUpdater = mkOption {
      type = types.bool;
      default = false;
      description = "Show last container updater status";
    };

    showSnapraidStatus = mkOption {
      type = types.bool;
      default = false;
      description = "Show SnapRAID sync and scrub status";
    };
  };

  config = mkIf cfg.enable {
    # Add smartmontools if SMART status is enabled
    environment.systemPackages = mkIf cfg.showSmartStatus [ pkgs.smartmontools ];

    # Configure shell login initialization
    programs.zsh.loginShellInit = mkIf config.programs.zsh.enable (
      let
        # ANSI color codes for truecolor (using \033 for better compatibility)
        # Gruvbox Hard Dark theme colors to match nvim
        colors = {
          reset = "\\033[0m";
          dim = "\\033[2m";
          aqua = "\\033[38;2;142;192;124m";   # Gruvbox aqua #8ec07c
          blue = "\\033[38;2;131;165;152m";   # Gruvbox blue #83a598
          green = "\\033[38;2;184;187;38m";   # Gruvbox green #b8bb26
          yellow = "\\033[38;2;250;189;47m";  # Gruvbox yellow #fabd2f
          orange = "\\033[38;2;254;128;25m";  # Gruvbox orange #fe8019
          red = "\\033[38;2;251;73;52m";      # Gruvbox red #fb4934
          gray = "\\033[38;2;146;131;116m";   # Gruvbox gray #928374
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
                STATUS="\\033[38;2;184;187;38m✓\\033[0m"
                HEALTH_COLOR="\\033[38;2;184;187;38m"
                # Color temp based on value
                if [[ "$TEMP" =~ ^[0-9]+$ ]]; then
                  if [[ $TEMP -ge 70 ]]; then
                    TEMP_COLOR="\\033[38;2;251;73;52m"
                  elif [[ $TEMP -ge 50 ]]; then
                    TEMP_COLOR="\\033[38;2;254;128;25m"
                  else
                    TEMP_COLOR="\\033[38;2;250;189;47m"
                  fi
                  TEMP_STR="$(printf "%b" "''${TEMP_COLOR}''${TEMP}°C\\033[0m")"
                else
                  TEMP_STR="$(printf "%b" "\\033[2m$TEMP\\033[0m")"
                fi
              elif [[ "$HEALTH" == "FAILED" ]]; then
                STATUS="\\033[38;2;251;73;52m✗\\033[0m"
                HEALTH_COLOR="\\033[38;2;251;73;52m"
                TEMP_STR="$(printf "%b" "\\033[2m$TEMP\\033[0m")"
              else
                STATUS="\\033[38;2;250;189;47m⚠\\033[0m"
                HEALTH_COLOR="\\033[38;2;250;189;47m"
                TEMP_STR="$(printf "%b" "\\033[2m$TEMP\\033[0m")"
              fi

              printf "  %b \\033[2m%-15s\\033[0m %b%-7s\\033[0m %s\n" "$STATUS" "${name}" "$HEALTH_COLOR" "$HEALTH" "$TEMP_STR"
            else
              printf "  \\033[38;2;250;189;47m⚠\\033[0m \\033[2m%-15s\\033[0m \\033[38;2;251;73;52m%-20s\\033[0m\n" "${name}" "Not found"
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

          printf "  \\033[38;2;142;192;124m%s\\033[0m \\033[2m·\\033[0m \\033[2m↑\\033[0m %s \\033[2m· load\\033[0m %s\n" "$(hostname)" "$UPTIME_STR" "$LOAD"
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
              BAR_COLOR="\\033[38;2;251;73;52m"
            elif [[ $PCT_NUM -ge 70 ]]; then
              BAR_COLOR="\\033[38;2;254;128;25m"
            elif [[ $PCT_NUM -ge 50 ]]; then
              BAR_COLOR="\\033[38;2;250;189;47m"
            else
              BAR_COLOR="\\033[38;2;184;187;38m"
            fi

            printf "  \\033[2m%-12s\\033[0m %6s/%-6s %b%s\\033[0m %5s\n" "${path}" "$USED" "$TOTAL" "$BAR_COLOR" "$BAR" "$PCT"
          '') cfg.diskUsagePaths}
        '';

        # Build SnapRAID status display
        snapraidStatusCode = optionalString cfg.showSnapraidStatus ''
          # Query journalctl for snapraid services
          SNAPRAID_SYNC_LOG=$(journalctl -u snapraid-sync.service -n 100 --no-pager --output=cat 2>/dev/null || echo "")
          SNAPRAID_SCRUB_LOG=$(journalctl -u snapraid-scrub.service -n 100 --no-pager --output=cat 2>/dev/null || echo "")

          # Parse sync status
          if [[ -n "$SNAPRAID_SYNC_LOG" ]]; then
            # Check for completion messages
            if echo "$SNAPRAID_SYNC_LOG" | ${pkgs.gnugrep}/bin/grep -q "Everything OK"; then
              SYNC_STATUS="✓"
              SYNC_COLOR="\\033[38;2;184;187;38m"

              # Get timestamp
              SYNC_TIMESTAMP=$(journalctl -u snapraid-sync.service --output=short-iso -n 100 --no-pager 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Everything OK" | tail -1 | ${pkgs.gawk}/bin/awk '{print $1}')

              if [[ -n "$SYNC_TIMESTAMP" ]]; then
                SYNC_EPOCH=$(date -d "$SYNC_TIMESTAMP" +%s 2>/dev/null || echo "0")
                NOW_EPOCH=$(date +%s)
                DIFF_SECONDS=$((NOW_EPOCH - SYNC_EPOCH))

                if [[ $DIFF_SECONDS -lt 3600 ]]; then
                  SYNC_TIME="$((DIFF_SECONDS / 60))m ago"
                elif [[ $DIFF_SECONDS -lt 86400 ]]; then
                  SYNC_TIME="$((DIFF_SECONDS / 3600))h ago"
                else
                  SYNC_TIME="$((DIFF_SECONDS / 86400))d ago"
                fi

                # Adjust color if old
                if [[ $DIFF_SECONDS -gt 172800 ]]; then
                  SYNC_STATUS="✗"
                  SYNC_COLOR="\\033[38;2;251;73;52m"
                elif [[ $DIFF_SECONDS -gt 86400 ]]; then
                  SYNC_STATUS="⚠"
                  SYNC_COLOR="\\033[38;2;250;189;47m"
                fi
              else
                SYNC_TIME="Unknown"
              fi

              # Extract stats
              FILES_SYNCED=$(echo "$SNAPRAID_SYNC_LOG" | ${pkgs.gnugrep}/bin/grep -oP "equal\s+\K[0-9]+" | tail -1)
              FILES_ADDED=$(echo "$SNAPRAID_SYNC_LOG" | ${pkgs.gnugrep}/bin/grep -oP "added\s+\K[0-9]+" | tail -1)
              FILES_REMOVED=$(echo "$SNAPRAID_SYNC_LOG" | ${pkgs.gnugrep}/bin/grep -oP "removed\s+\K[0-9]+" | tail -1)
              FILES_UPDATED=$(echo "$SNAPRAID_SYNC_LOG" | ${pkgs.gnugrep}/bin/grep -oP "updated\s+\K[0-9]+" | tail -1)

              # Build sync details
              SYNC_DETAILS=""
              [[ -n "$FILES_ADDED" && "$FILES_ADDED" != "0" ]] && SYNC_DETAILS="$SYNC_DETAILS, $FILES_ADDED added"
              [[ -n "$FILES_REMOVED" && "$FILES_REMOVED" != "0" ]] && SYNC_DETAILS="$SYNC_DETAILS, $FILES_REMOVED removed"
              [[ -n "$FILES_UPDATED" && "$FILES_UPDATED" != "0" ]] && SYNC_DETAILS="$SYNC_DETAILS, $FILES_UPDATED updated"
              SYNC_DETAILS=$(echo "$SYNC_DETAILS" | sed 's/^, //')

              if [[ -n "$FILES_SYNCED" ]]; then
                if [[ -n "$SYNC_DETAILS" ]]; then
                  printf "  %b%s\\033[0m \\033[2mLast sync\\033[0m    %b%s\\033[0m  \\033[2m%s files (%s)\\033[0m\n" "$SYNC_COLOR" "$SYNC_STATUS" "$SYNC_COLOR" "$SYNC_TIME" "$FILES_SYNCED" "$SYNC_DETAILS"
                else
                  printf "  %b%s\\033[0m \\033[2mLast sync\\033[0m    %b%s\\033[0m  \\033[2m%s files\\033[0m\n" "$SYNC_COLOR" "$SYNC_STATUS" "$SYNC_COLOR" "$SYNC_TIME" "$FILES_SYNCED"
                fi
              else
                printf "  %b%s\\033[0m \\033[2mLast sync\\033[0m    %b%s\\033[0m\n" "$SYNC_COLOR" "$SYNC_STATUS" "$SYNC_COLOR" "$SYNC_TIME"
              fi

            elif echo "$SNAPRAID_SYNC_LOG" | ${pkgs.gnugrep}/bin/grep -q "error\|Error\|ERROR"; then
              SYNC_STATUS="✗"
              SYNC_COLOR="\\033[38;2;251;73;52m"
              printf "  %b%s\\033[0m \\033[2mLast sync\\033[0m    %bFAILED\\033[0m\n" "$SYNC_COLOR" "$SYNC_STATUS" "$SYNC_COLOR"
            else
              SYNC_STATUS="⚠"
              printf "  %b%s\\033[0m \\033[2mLast sync\\033[0m    \\033[38;2;250;189;47mUnknown\\033[0m\n" "$SYNC_STATUS"
            fi
          else
            printf "  \\033[38;2;250;189;47m⚠\\033[0m \\033[2mLast sync\\033[0m    \\033[2mNever run\\033[0m\n"
          fi

          # Parse scrub status
          if [[ -n "$SNAPRAID_SCRUB_LOG" ]]; then
            if echo "$SNAPRAID_SCRUB_LOG" | ${pkgs.gnugrep}/bin/grep -q "Everything OK"; then
              SCRUB_STATUS="✓"
              SCRUB_COLOR="\\033[38;2;184;187;38m"

              # Get timestamp
              SCRUB_TIMESTAMP=$(journalctl -u snapraid-scrub.service --output=short-iso -n 100 --no-pager 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Everything OK" | tail -1 | ${pkgs.gawk}/bin/awk '{print $1}')

              if [[ -n "$SCRUB_TIMESTAMP" ]]; then
                SCRUB_EPOCH=$(date -d "$SCRUB_TIMESTAMP" +%s 2>/dev/null || echo "0")
                NOW_EPOCH=$(date +%s)
                DIFF_SECONDS=$((NOW_EPOCH - SCRUB_EPOCH))

                if [[ $DIFF_SECONDS -lt 3600 ]]; then
                  SCRUB_TIME="$((DIFF_SECONDS / 60))m ago"
                elif [[ $DIFF_SECONDS -lt 86400 ]]; then
                  SCRUB_TIME="$((DIFF_SECONDS / 3600))h ago"
                else
                  SCRUB_TIME="$((DIFF_SECONDS / 86400))d ago"
                fi

                # Adjust color if old (scrub is weekly so >10d is concerning)
                if [[ $DIFF_SECONDS -gt 864000 ]]; then
                  SCRUB_STATUS="⚠"
                  SCRUB_COLOR="\\033[38;2;250;189;47m"
                fi
              else
                SCRUB_TIME="Unknown"
              fi

              printf "  %b%s\\033[0m \\033[2mLast scrub\\033[0m   %b%s\\033[0m  \\033[2mNo errors\\033[0m\n" "$SCRUB_COLOR" "$SCRUB_STATUS" "$SCRUB_COLOR" "$SCRUB_TIME"

            elif echo "$SNAPRAID_SCRUB_LOG" | ${pkgs.gnugrep}/bin/grep -q "error"; then
              ERROR_COUNT=$(echo "$SNAPRAID_SCRUB_LOG" | ${pkgs.gnugrep}/bin/grep -oP "[0-9]+\s+error" | ${pkgs.gawk}/bin/awk '{print $1}' | tail -1)
              SCRUB_STATUS="✗"
              SCRUB_COLOR="\\033[38;2;251;73;52m"

              if [[ -n "$ERROR_COUNT" ]]; then
                printf "  %b%s\\033[0m \\033[2mLast scrub\\033[0m   %b%s error(s)\\033[0m\n" "$SCRUB_COLOR" "$SCRUB_STATUS" "$SCRUB_COLOR" "$ERROR_COUNT"
              else
                printf "  %b%s\\033[0m \\033[2mLast scrub\\033[0m   %bErrors detected\\033[0m\n" "$SCRUB_COLOR" "$SCRUB_STATUS" "$SCRUB_COLOR"
              fi
            else
              printf "  \\033[38;2;250;189;47m⚠\\033[0m \\033[2mLast scrub\\033[0m   \\033[38;2;250;189;47mUnknown\\033[0m\n"
            fi
          else
            printf "  \\033[38;2;250;189;47m⚠\\033[0m \\033[2mLast scrub\\033[0m   \\033[2mNever run\\033[0m\n"
          fi
        '';

        # Build container updater status display
        containerUpdaterStatusCode = optionalString cfg.showContainerUpdater ''
          # Query journalctl for container-updater.service
          CONTAINER_LOG=$(journalctl -u container-updater.service -n 150 --no-pager --output=cat 2>/dev/null || echo "")

          if [[ -z "$CONTAINER_LOG" ]]; then
            # Service never ran
            printf "  \\033[38;2;250;189;47m⚠\\033[0m \\033[2mNever run\\033[0m\n"
          else
            # Check if last update completed
            if echo "$CONTAINER_LOG" | ${pkgs.gnugrep}/bin/grep -q "Container update completed successfully"; then
              STATUS_SYMBOL="\\033[38;2;184;187;38m✓\\033[0m"
              STATUS_COLOR="\\033[38;2;184;187;38m"
              STATUS_TEXT="SUCCESS"

              # Get timestamp of last successful update
              LAST_TIMESTAMP=$(journalctl -u container-updater.service --output=short-iso -n 150 --no-pager 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Container update completed successfully" | tail -1 | ${pkgs.gawk}/bin/awk '{print $1}')

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
                  STATUS_SYMBOL="\\033[38;2;251;73;52m✗\\033[0m"
                  STATUS_COLOR="\\033[38;2;251;73;52m"
                elif [[ $DIFF_SECONDS -gt 86400 ]]; then
                  # 24-48h - yellow
                  STATUS_SYMBOL="\\033[38;2;250;189;47m⚠\\033[0m"
                  STATUS_COLOR="\\033[38;2;250;189;47m"
                fi
              else
                TIME_AGO="Unknown"
              fi

              # Extract container counts from summary
              UPDATED_COUNT=$(echo "$CONTAINER_LOG" | ${pkgs.gnugrep}/bin/grep -oP "✅ Updated \(\K[0-9]+" | tail -1)
              FAILED_COUNT=$(echo "$CONTAINER_LOG" | ${pkgs.gnugrep}/bin/grep -oP "❌ Failed \(\K[0-9]+" | tail -1)
              SKIPPED_COUNT=$(echo "$CONTAINER_LOG" | ${pkgs.gnugrep}/bin/grep -oP "⏭️ No updates \(\K[0-9]+" | tail -1)

              # Build summary text
              SUMMARY_PARTS=()
              [[ -n "$UPDATED_COUNT" && "$UPDATED_COUNT" != "0" ]] && SUMMARY_PARTS+=("$UPDATED_COUNT updated")
              [[ -n "$FAILED_COUNT" && "$FAILED_COUNT" != "0" ]] && SUMMARY_PARTS+=("$FAILED_COUNT failed")
              [[ -n "$SKIPPED_COUNT" && "$SKIPPED_COUNT" != "0" ]] && SUMMARY_PARTS+=("$SKIPPED_COUNT skipped")

              SUMMARY=$(IFS=", "; echo "''${SUMMARY_PARTS[*]}")
              [[ -z "$SUMMARY" ]] && SUMMARY="No containers"

              # Display main status line
              printf "  %b \\033[2mLast update\\033[0m  %b%s\\033[0m  \\033[2m%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_COLOR" "$TIME_AGO" "$SUMMARY"

              # Extract and display updated containers (only those actually updated, not skipped)
              if [[ -n "$UPDATED_COUNT" && "$UPDATED_COUNT" != "0" ]]; then
                UPDATED_LIST=$(echo "$CONTAINER_LOG" | ${pkgs.gawk}/bin/awk '/✅ Updated \([0-9]+\):/,/^(❌|⏭️|=|$)/ {if ($0 ~ /^  • / && $0 !~ /\(no update\)/) {gsub(/^  • /, ""); print}}' | tr '\n' ', ' | sed 's/, $//')
                if [[ -n "$UPDATED_LIST" ]]; then
                  printf "  \\033[2m  Updated: %s\\033[0m\n" "$UPDATED_LIST"
                fi
              fi

              # Extract and display failed containers
              if [[ -n "$FAILED_COUNT" && "$FAILED_COUNT" != "0" ]]; then
                FAILED_LIST=$(echo "$CONTAINER_LOG" | ${pkgs.gawk}/bin/awk '/❌ Failed \([0-9]+\):/,/^(✅|⏭️|=|$)/ {if ($0 ~ /^  • /) {gsub(/^  • /, ""); print}}' | tr '\n' ', ' | sed 's/, $//')
                if [[ -n "$FAILED_LIST" ]]; then
                  printf "  \\033[38;2;251;73;52m  Failed: %s\\033[0m\n" "$FAILED_LIST"
                fi
              fi

            elif echo "$CONTAINER_LOG" | ${pkgs.gnugrep}/bin/grep -q "ERROR: Some containers failed to update"; then
              # Update ran but had failures
              STATUS_SYMBOL="\\033[38;2;251;73;52m✗\\033[0m"
              STATUS_COLOR="\\033[38;2;251;73;52m"

              # Get timestamp
              LAST_TIMESTAMP=$(journalctl -u container-updater.service --output=short-iso -n 150 --no-pager 2>/dev/null | ${pkgs.gnugrep}/bin/grep "ERROR: Some containers failed to update" | tail -1 | ${pkgs.gawk}/bin/awk '{print $1}')

              if [[ -n "$LAST_TIMESTAMP" ]]; then
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
              else
                TIME_AGO="Unknown"
              fi

              # Extract counts
              UPDATED_COUNT=$(echo "$CONTAINER_LOG" | ${pkgs.gnugrep}/bin/grep -oP "✅ Updated \(\K[0-9]+" | tail -1)
              FAILED_COUNT=$(echo "$CONTAINER_LOG" | ${pkgs.gnugrep}/bin/grep -oP "❌ Failed \(\K[0-9]+" | tail -1)

              SUMMARY_PARTS=()
              [[ -n "$FAILED_COUNT" && "$FAILED_COUNT" != "0" ]] && SUMMARY_PARTS+=("$FAILED_COUNT failed")
              [[ -n "$UPDATED_COUNT" && "$UPDATED_COUNT" != "0" ]] && SUMMARY_PARTS+=("$UPDATED_COUNT updated")

              SUMMARY=$(IFS=", "; echo "''${SUMMARY_PARTS[*]}")

              printf "  %b \\033[2mLast update\\033[0m  %b%s\\033[0m  \\033[38;2;251;73;52m%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_COLOR" "$TIME_AGO" "$SUMMARY"

              # Show updated containers
              if [[ -n "$UPDATED_COUNT" && "$UPDATED_COUNT" != "0" ]]; then
                UPDATED_LIST=$(echo "$CONTAINER_LOG" | ${pkgs.gawk}/bin/awk '/✅ Updated \([0-9]+\):/,/^(❌|⏭️|=|$)/ {if ($0 ~ /^  • / && $0 !~ /\(no update\)/) {gsub(/^  • /, ""); print}}' | tr '\n' ', ' | sed 's/, $//')
                if [[ -n "$UPDATED_LIST" ]]; then
                  printf "  \\033[2m  Updated: %s\\033[0m\n" "$UPDATED_LIST"
                fi
              fi

              # Show failed containers
              if [[ -n "$FAILED_COUNT" && "$FAILED_COUNT" != "0" ]]; then
                FAILED_LIST=$(echo "$CONTAINER_LOG" | ${pkgs.gawk}/bin/awk '/❌ Failed \([0-9]+\):/,/^(✅|⏭️|=|$)/ {if ($0 ~ /^  • /) {gsub(/^  • /, ""); print}}' | tr '\n' ', ' | sed 's/, $//')
                if [[ -n "$FAILED_LIST" ]]; then
                  printf "  \\033[38;2;251;73;52m  Failed: %s\\033[0m\n" "$FAILED_LIST"
                fi
              fi

            else
              # Unknown or no completion message
              STATUS_SYMBOL="\\033[38;2;250;189;47m⚠\\033[0m"
              STATUS_TEXT="Unknown"
              printf "  %b \\033[2mLast update\\033[0m  \\033[38;2;250;189;47m%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_TEXT"
            fi
          fi
        '';

        # Build borg backup status display
        borgStatusCode = optionalString cfg.showBorgStatus ''
          # Query journalctl for borg-backup.service
          BORG_LOG=$(journalctl -u borg-backup.service -n 100 --no-pager --output=cat 2>/dev/null || echo "")

          if [[ -z "$BORG_LOG" ]]; then
            # Service never ran
            printf "  \\033[38;2;250;189;47m⚠\\033[0m \\033[2mNever run\\033[0m\n"
          else
            # Check if last backup succeeded
            if echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -q "Backup process completed successfully"; then
              STATUS_SYMBOL="\\033[38;2;184;187;38m✓\\033[0m"
              STATUS_COLOR="\\033[38;2;184;187;38m"

              # Get timestamp of last successful backup
              LAST_TIMESTAMP=$(journalctl -u borg-backup.service --output=short-iso -n 100 --no-pager 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Backup process completed successfully" | tail -1 | ${pkgs.gawk}/bin/awk '{print $1}')

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
                  STATUS_SYMBOL="\\033[38;2;251;73;52m✗\\033[0m"
                  STATUS_COLOR="\\033[38;2;251;73;52m"
                elif [[ $DIFF_SECONDS -gt 86400 ]]; then
                  # 24-48h - yellow
                  STATUS_SYMBOL="\\033[38;2;250;189;47m⚠\\033[0m"
                  STATUS_COLOR="\\033[38;2;250;189;47m"
                fi
              else
                TIME_AGO="Unknown"
              fi

              # Extract archive statistics from borg output
              # Look for lines like: "Archive name: ..." and "This archive: X.XX GB"
              ARCHIVE_NAME=$(echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -oP "Archive name: \K.*" | tail -1)
              ARCHIVE_SIZE=$(echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -oP "(Original size|This archive):\s+\K[0-9.]+ [KMGT]?B" | tail -1)
              COMPRESSED_SIZE=$(echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -oP "Compressed size:\s+\K[0-9.]+ [KMGT]?B" | tail -1)
              DEDUPLICATED_SIZE=$(echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -oP "Deduplicated size:\s+\K[0-9.]+ [KMGT]?B" | tail -1)
              FILES_COUNT=$(echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -oP "Number of files:\s+\K[0-9]+" | tail -1)

              # Display main status line
              printf "  %b \\033[2mLast backup\\033[0m  %b%s\\033[0m" "$STATUS_SYMBOL" "$STATUS_COLOR" "$TIME_AGO"

              # Add archive size if available
              if [[ -n "$DEDUPLICATED_SIZE" ]]; then
                printf "  \\033[2m%s\\033[0m" "$DEDUPLICATED_SIZE"
              elif [[ -n "$ARCHIVE_SIZE" ]]; then
                printf "  \\033[2m%s\\033[0m" "$ARCHIVE_SIZE"
              fi
              printf "\n"

              # Display additional details if available
              if [[ -n "$ARCHIVE_SIZE" ]] && [[ -n "$COMPRESSED_SIZE" ]] && [[ -n "$DEDUPLICATED_SIZE" ]]; then
                printf "  \\033[2m  Original: %s  Compressed: %s  Dedup: %s\\033[0m\n" "$ARCHIVE_SIZE" "$COMPRESSED_SIZE" "$DEDUPLICATED_SIZE"
              fi

              if [[ -n "$FILES_COUNT" ]]; then
                printf "  \\033[2m  Files: %s\\033[0m\n" "$FILES_COUNT"
              fi

            else
              # Check for errors
              if echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep -q "ERROR"; then
                STATUS_SYMBOL="\\033[38;2;251;73;52m✗\\033[0m"
                STATUS_TEXT="FAILED"
                ERROR_MSG=$(echo "$BORG_LOG" | ${pkgs.gnugrep}/bin/grep "ERROR" | tail -1 | ${pkgs.gawk}/bin/awk '{print substr($0, index($0,$2))}' | cut -c1-60)
                printf "  %b \\033[2mLast backup\\033[0m  \\033[38;2;251;73;52m%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_TEXT"
                if [[ -n "$ERROR_MSG" ]]; then
                  printf "  \\033[2m  %s\\033[0m\n" "$ERROR_MSG"
                fi
              else
                STATUS_SYMBOL="\\033[38;2;250;189;47m⚠\\033[0m"
                STATUS_TEXT="Unknown"
                printf "  %b \\033[2mLast backup\\033[0m  \\033[38;2;250;189;47m%s\\033[0m\n" "$STATUS_SYMBOL" "$STATUS_TEXT"
              fi
            fi
          fi
        '';

        # Combine all sections
        hasDisks = cfg.showSmartStatus && (builtins.length (builtins.attrNames cfg.smartDrives) > 0);
        hasStorage = cfg.showDiskUsage && (builtins.length cfg.diskUsagePaths > 0);

      in ''
        if ([[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_TTY" ]]) && [[ -z "$TMUX" ]]; then
          echo ""
          printf "\\033[38;2;142;192;124m━━ System ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
          ${systemInfoCode}
          ${optionalString hasDisks ''
            printf "\\033[38;2;131;165;152m━━ Disks ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
            ${smartStatusCode}
          ''}
          ${optionalString hasStorage ''
            printf "\\033[38;2;131;165;152m━━ Storage ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
            ${diskUsageCode}
          ''}
          ${optionalString cfg.showSnapraidStatus ''
            printf "\\033[38;2;131;165;152m━━ SnapRAID ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
            ${snapraidStatusCode}
          ''}
          ${optionalString cfg.showContainerUpdater ''
            printf "\\033[38;2;131;165;152m━━ Containers ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
            ${containerUpdaterStatusCode}
          ''}
          ${optionalString cfg.showBorgStatus ''
            printf "\\033[38;2;131;165;152m━━ Backup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\n"
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
