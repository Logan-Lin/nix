#!/usr/bin/env bash

# Simple daily SMART report script - plain text version
# Only checks SMART attributes and sends report via Gotify

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOTIFY_SCRIPT="${SCRIPT_DIR}/gotify-notify.sh"
LOG_FILE="/var/log/daily-smart-report.log"

# Host-specific Gotify configuration
GOTIFY_URL="https://notify.yanlincs.com"
GOTIFY_TOKEN="Ac9qKFH5cA.7Yly"

# Drive configurations
declare -A DRIVES=(
    ["/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R"]="ZFS Mirror 1"
    ["/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG"]="ZFS Mirror 2"
    ["/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PK2N4GB"]="Data Drive 1 (12TB)"
    ["/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PJ7Z3LE"]="Data Drive 2 (12TB)"
    ["/dev/disk/by-id/ata-ST16000NM000J-2TW103_WRS0F8BE"]="Parity Drive (16TB)"
)

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