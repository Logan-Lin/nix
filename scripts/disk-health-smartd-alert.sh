#!/usr/bin/env bash

# SMART daemon alert script for Gotify notifications
# Called by smartd when SMART issues are detected
# No arguments needed - uses SMARTD_DEVICE environment variable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOTIFY_SCRIPT="${SCRIPT_DIR}/gotify-notify.sh"
LOG_FILE="/var/log/smartd-alerts.log"

# Host-specific Gotify configuration
GOTIFY_URL="https://notify.yanlincs.com"
GOTIFY_TOKEN="Ac9qKFH5cA.7Yly"

# Drive name mapping based on device path
get_drive_name() {
    local device="$1"
    case "$device" in
        *"ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R"*)
            echo "ZFS Mirror 1 (System)"
            ;;
        *"ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG"*)
            echo "ZFS Mirror 2 (System)"
            ;;
        *"ata-HGST_HUH721212ALE604_5PK2N4GB"*)
            echo "Data Drive 1 (12TB)"
            ;;
        *"ata-HGST_HUH721212ALE604_5PJ7Z3LE"*)
            echo "Data Drive 2 (12TB)"
            ;;
        *"ata-ST16000NM000J-2TW103_WRS0F8BE"*)
            echo "Parity Drive (16TB)"
            ;;
        *)
            echo "Unknown Drive ($device)"
            ;;
    esac
}

log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

send_smartd_alert() {
    # smartd provides these environment variables:
    local device="${SMARTD_DEVICE:-unknown}"
    local failtype="${SMARTD_FAILTYPE:-unknown}"
    local message="${SMARTD_MESSAGE:-No details provided}"
    
    local drive_name
    drive_name=$(get_drive_name "$device")
    
    log_message "SMART alert for $drive_name ($device): $failtype - $message"
    
    # Determine priority based on failure type
    local priority="high"
    case "$failtype" in
        *"FAILURE"*|*"failure"*|*"CRITICAL"*|*"critical"*)
            priority="critical"
            ;;
        *"WARNING"*|*"warning"*|*"Temperature"*)
            priority="high"
            ;;
        *)
            priority="high"
            ;;
    esac
    
    # Create notification message
    local notification_title="SMART Alert: $drive_name"
    local notification_message="Device: $device
Failure Type: $failtype
Details: $message

This alert was triggered by smartd monitoring."
    
    # Send Gotify notification
    if [[ -x "$GOTIFY_SCRIPT" ]]; then
        "$GOTIFY_SCRIPT" "$GOTIFY_URL" "$GOTIFY_TOKEN" "$priority" "$notification_title" "$notification_message" || \
            log_message "Failed to send Gotify notification"
    else
        log_message "Gotify script not found or not executable: $GOTIFY_SCRIPT"
    fi
}

# Ensure log file exists
touch "$LOG_FILE" 2>/dev/null || {
    LOG_FILE="/tmp/smartd-alerts.log"
    touch "$LOG_FILE"
}

# Main execution
send_smartd_alert