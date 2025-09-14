# SMART daemon alert script for Gotify notifications
# Called by smartd when SMART issues are detected
# Usage: disk-health-smartd-alert.sh <gotify_token> <drive_name>
# Uses SMARTD_DEVICE environment variable for device info

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOTIFY_SCRIPT="${SCRIPT_DIR}/gotify-notify.sh"
LOG_FILE="/var/log/smartd-alerts.log"

# Get parameters
GOTIFY_TOKEN="${1:-}"
DRIVE_NAME="${2:-}"

# Validate parameters
if [[ -z "$GOTIFY_TOKEN" ]]; then
    echo "Error: Gotify token not provided"
    echo "Usage: $0 <gotify_token> <drive_name>"
    exit 1
fi

# If drive name not provided, use device path
if [[ -z "$DRIVE_NAME" ]]; then
    DRIVE_NAME="${SMARTD_DEVICE:-Unknown Drive}"
fi

# Gotify configuration
GOTIFY_URL="https://notify.yanlincs.com"

log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

send_smartd_alert() {
    # smartd provides these environment variables:
    local device="${SMARTD_DEVICE:-unknown}"
    local failtype="${SMARTD_FAILTYPE:-unknown}"
    local message="${SMARTD_MESSAGE:-No details provided}"
    
    log_message "SMART alert for $DRIVE_NAME ($device): $failtype - $message"
    
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
    local notification_title="SMART Alert: $DRIVE_NAME"
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
