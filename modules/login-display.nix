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
  };

  config = mkIf cfg.enable {
    # Add smartmontools if SMART status is enabled
    environment.systemPackages = mkIf cfg.showSmartStatus [ pkgs.smartmontools ];

    # Configure shell login initialization
    programs.zsh.loginShellInit = mkIf config.programs.zsh.enable (
      let
        # Build SMART status display
        smartStatusCode = optionalString cfg.showSmartStatus ''
          # Only show on SSH sessions
          if [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_TTY" ]]; then
            echo ""
            echo "=== Disk Health Status ==="

            ${concatStringsSep "\n" (mapAttrsToList (device: name: ''
              if [[ -e "${device}" ]]; then
                # Determine if NVMe
                SMART_OPTS=""
                if [[ "${device}" == *"nvme"* ]]; then
                  SMART_OPTS="-d nvme"
                fi

                # Get health status (using sudo for disk access)
                HEALTH_OUTPUT=$(sudo ${pkgs.smartmontools}/bin/smartctl $SMART_OPTS -H "${device}" 2>/dev/null)
                if HEALTH=$(echo "$HEALTH_OUTPUT" | ${pkgs.gnugrep}/bin/grep -o "PASSED\|FAILED" | head -1); then
                  : # HEALTH is set
                else
                  HEALTH="UNKNOWN"
                fi

                # Get temperature
                TEMP="N/A"
                if [[ "$HEALTH" == "PASSED" ]]; then
                  SMART_DATA=$(sudo ${pkgs.smartmontools}/bin/smartctl $SMART_OPTS -A "${device}" 2>/dev/null)
                  if [[ "${device}" == *"nvme"* ]]; then
                    TEMP=$(echo "$SMART_DATA" | ${pkgs.gawk}/bin/awk '/^Temperature:/ {print $2}' | head -1)
                    [[ -n "$TEMP" && "$TEMP" =~ ^[0-9]+$ ]] && TEMP="''${TEMP}°C" || TEMP="N/A"
                  else
                    TEMP=$(echo "$SMART_DATA" | ${pkgs.gawk}/bin/awk '/Temperature_Celsius/ {print $10}' | head -1)
                    [[ -n "$TEMP" && "$TEMP" =~ ^[0-9]+$ ]] && TEMP="''${TEMP}°C" || TEMP="N/A"
                  fi
                fi

                # Display status with color
                if [[ "$HEALTH" == "PASSED" ]]; then
                  echo "  ✓ ${name}: $HEALTH (Temp: $TEMP)"
                else
                  echo "  ✗ ${name}: $HEALTH"
                fi
              else
                echo "  ⚠ ${name}: Device not found"
              fi
            '') cfg.smartDrives)}
          fi
        '';

        # Build system info display
        systemInfoCode = optionalString cfg.showSystemInfo ''
          # Only show on SSH sessions
          if [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_TTY" ]]; then
            echo ""
            echo "=== System Information ==="
            echo "  Hostname: $(hostname)"
            # Parse uptime output to get readable format
            UPTIME_STR=$(uptime | ${pkgs.gawk}/bin/awk '{
              # Extract the uptime part (between "up" and "user" or "load")
              match($0, /up\s+(.+?),\s+[0-9]+\s+user/, arr)
              if (arr[1] != "") {
                print arr[1]
              }
            }')
            echo "  Uptime: $UPTIME_STR"
            echo "  Load: $(uptime | ${pkgs.gawk}/bin/awk -F'load average:' '{print $2}')"
          fi
        '';

        # Build disk usage display
        diskUsageCode = optionalString cfg.showDiskUsage ''
          # Only show on SSH sessions
          if [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_TTY" ]]; then
            echo ""
            echo "=== Disk Usage ==="
            ${concatMapStringsSep "\n" (path: ''
              df -h "${path}" | ${pkgs.gawk}/bin/awk 'NR==2 {printf "  ${path}: %s / %s (%s used)\n", $3, $2, $5}'
            '') cfg.diskUsagePaths}
          fi
        '';

      in ''
        ${systemInfoCode}
        ${smartStatusCode}
        ${diskUsageCode}

        # Add blank line after all info
        if [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_TTY" ]]; then
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
