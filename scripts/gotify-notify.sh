# Gotify notification script for disk health monitoring
# Usage: gotify-notify.sh <url> <token> <priority> <title> <message>

set -euo pipefail

# Validate arguments
if [[ $# -ne 5 ]]; then
    echo "Usage: $0 <url> <token> <priority> <title> <message>"
    echo "Example: $0 'https://notify.yanlincs.com' 'token123' 'high' 'Disk Alert' 'Drive temperature critical'"
    exit 1
fi

# Get parameters
GOTIFY_URL="$1"
GOTIFY_TOKEN="$2"
priority="$3"
title="$4"
message="$5"
MAX_RETRIES=3
RETRY_DELAY=5

# Priority mapping: 1=low, 5=normal, 8=high, 10=critical
declare -A PRIORITY_MAP=(
    ["low"]="1"
    ["normal"]="5"
    ["high"]="8"
    ["critical"]="10"
)


send_notification() {
    local priority="$1"
    local title="$2"
    local message="$3"
    local attempt=1

    # Map priority to numeric value
    local numeric_priority="${PRIORITY_MAP[$priority]:-5}"

    while [ $attempt -le $MAX_RETRIES ]; do
        if curl -s -o /dev/null -w "%{http_code}" \
            -X POST "${GOTIFY_URL}/message" \
            -H "X-Gotify-Key: ${GOTIFY_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{
                \"title\": \"${title}\",
                \"message\": \"${message}\",
                \"priority\": ${numeric_priority}
            }" | grep -q "200"; then
            echo "Notification sent successfully (attempt $attempt)"
            return 0
        else
            echo "Failed to send notification (attempt $attempt/$MAX_RETRIES)"
            if [ $attempt -lt $MAX_RETRIES ]; then
                sleep $RETRY_DELAY
            fi
            ((attempt++))
        fi
    done

    echo "ERROR: Failed to send notification after $MAX_RETRIES attempts" >&2
    return 1
}

# Validate priority
if [[ ! ${PRIORITY_MAP[$priority]+_} ]]; then
    echo "Error: Invalid priority '$priority'. Use: low, normal, high, critical"
    exit 1
fi

# Send notification
send_notification "$priority" "$title" "$message"
