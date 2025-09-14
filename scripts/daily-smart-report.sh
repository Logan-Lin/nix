# Simple daily SMART report script - plain text version
# Only checks SMART attributes and sends report via Gotify
# Usage: daily-smart-report.sh <gotify_token>
# Drive list should be passed via SMART_DRIVES environment variable as "device:name" pairs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOTIFY_SCRIPT="${SCRIPT_DIR}/gotify-notify.sh"
LOG_FILE="/var/log/daily-smart-report.log"

# Get parameters
GOTIFY_TOKEN="${1:-}"

# Validate parameters
if [[ -z "$GOTIFY_TOKEN" ]]; then
    echo "Error: Gotify token not provided"
    echo "Usage: $0 <gotify_token>"
    echo "Drives should be in SMART_DRIVES environment variable"
    exit 1
fi

# Gotify configuration
GOTIFY_URL="https://notify.yanlincs.com"

# Parse drive configurations from environment variable
# SMART_DRIVES format: "device1:name1;device2:name2;..."
declare -A DRIVES=()

if [[ -n "${SMART_DRIVES:-}" ]]; then
    IFS=';' read -ra DRIVE_PAIRS <<< "$SMART_DRIVES"
    for pair in "${DRIVE_PAIRS[@]}"; do
        IFS=':' read -r device name <<< "$pair"
        if [[ -n "$device" && -n "$name" ]]; then
            DRIVES["$device"]="$name"
        fi
    done
else
    echo "Warning: No drives specified in SMART_DRIVES environment variable"
    echo "Format: SMART_DRIVES='device1:name1;device2:name2'"
    exit 1
fi

main() {
    local report=""
    local healthy_drives=0
    local total_drives=0
    
    echo "Starting daily SMART report"
    
    report="Daily SMART Report - $(date '+%Y-%m-%d')\n\n"
    report+="Drive SMART Status:\n"
    
    # Check each drive
    for device in "${!DRIVES[@]}"; do
        local device_name="${DRIVES[$device]}"
        total_drives=$((total_drives + 1))
        
        echo "Checking $device_name"
        
        # Quick device existence check
        if [[ ! -e "$device" ]]; then
            report+="[FAIL] $device_name: Device not found\n"
            continue
        fi
        
        # Get SMART health
        local health="UNKNOWN"
        if health=$(smartctl -H "$device" 2>/dev/null | grep -o "PASSED\|FAILED" | head -1); then
            echo "  Health: $health"
        else
            health="UNKNOWN"
            echo "  Health: $health"
        fi
        
        # Get temperature
        local temp="N/A"
        if [[ "$health" == "PASSED" ]]; then
            if temp=$(smartctl -A "$device" 2>/dev/null | awk '/Temperature_Celsius/ {print $10}' | head -1); then
                if [[ "$temp" -gt 0 ]] 2>/dev/null; then
                    temp="${temp}C"
                    echo "  Temperature: $temp"
                else
                    temp="N/A"
                    echo "  Temperature: $temp"
                fi
            else
                temp="N/A" 
                echo "  Temperature: $temp"
            fi
        fi
        
        # Format output
        if [[ "$health" == "PASSED" ]]; then
            report+="[OK] $device_name: $health (Temp: $temp)\n"
            healthy_drives=$((healthy_drives + 1))
        else
            report+="[FAIL] $device_name: $health (Temp: $temp)\n"
        fi
    done
    
    # Add summary
    report+="\nSummary:\n"
    if [[ $healthy_drives -eq $total_drives ]]; then
        report+="Status: All $total_drives drives healthy\n"
        report+="Next check: $(date -d 'tomorrow 08:00' '+%Y-%m-%d 08:00')"
        
        echo "Result: All drives healthy ($healthy_drives/$total_drives)"
        
        # Send notification
        if [[ -x "$GOTIFY_SCRIPT" ]]; then
            "$GOTIFY_SCRIPT" "$GOTIFY_URL" "$GOTIFY_TOKEN" "normal" "Daily SMART Report" "$report"
        fi
    else
        local issues=$((total_drives - healthy_drives))
        report+="Status: $issues of $total_drives drives have issues"
        
        echo "Result: Issues detected ($healthy_drives/$total_drives drives healthy)"
        
        # Send high priority notification for issues
        if [[ -x "$GOTIFY_SCRIPT" ]]; then
            "$GOTIFY_SCRIPT" "$GOTIFY_URL" "$GOTIFY_TOKEN" "high" "Daily SMART Report - Issues Detected" "$report"
        fi
    fi
    
    # Simple logging
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Daily SMART report: $healthy_drives/$total_drives drives healthy" >> "$LOG_FILE" 2>/dev/null || true
    
    echo "Daily SMART report completed"
}

main "$@"
