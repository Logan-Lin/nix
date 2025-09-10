# Borg backup integrity check script with notifications
# Usage: borg-integrity-check.sh <repo_url> <check_depth> <last_archives> <enable_notifications> <gotify_url> <gotify_token> <hostname>

set -euo pipefail

# Validate arguments
if [[ $# -ne 7 ]]; then
    echo "Usage: $0 <repo_url> <check_depth> <last_archives> <enable_notifications> <gotify_url> <gotify_token> <hostname>"
    exit 1
fi

# Get parameters
REPO_URL="$1"
CHECK_DEPTH="$2"
LAST_ARCHIVES="$3"
ENABLE_NOTIFICATIONS="$4"
GOTIFY_URL="$5"
GOTIFY_TOKEN="$6"
HOSTNAME="$7"

# Start time for tracking duration
CHECK_START=$(date +%s)
CHECK_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Initialize result variables
CHECK_RESULT="SUCCESS"
CHECK_DETAILS=""
ERRORS_FOUND=""

# Function to send notifications
send_notification() {
    local priority="$1"
    local title="$2"
    local message="$3"
    
    if [ "$ENABLE_NOTIFICATIONS" = "1" ] && [ -n "$GOTIFY_URL" ] && [ -n "$GOTIFY_TOKEN" ]; then
        /home/yanlin/.config/nix/scripts/gotify-notify.sh \
            "$GOTIFY_URL" \
            "$GOTIFY_TOKEN" \
            "$priority" \
            "$title" \
            "$message" || echo "Failed to send notification (non-critical)" >&2
    fi
}

# Function to run borg check with error handling
run_borg_check() {
    local check_args="$1"
    local check_type="$2"
    local output
    local exit_code
    
    echo "Running $check_type check..."
    
    # Run the check and capture output
    if output=$(borg check $check_args 2>&1); then
        echo "$check_type check completed successfully"
        CHECK_DETAILS="${CHECK_DETAILS}✓ $check_type check passed\n"
        return 0
    else
        exit_code=$?
        echo "ERROR: $check_type check failed with exit code $exit_code" >&2
        echo "Output: $output" >&2
        CHECK_RESULT="FAILED"
        ERRORS_FOUND="${ERRORS_FOUND}✗ $check_type check failed (exit code: $exit_code)\n"
        
        # Extract specific error details if available
        if echo "$output" | grep -q "corrupted"; then
            ERRORS_FOUND="${ERRORS_FOUND}  - Corruption detected\n"
        fi
        if echo "$output" | grep -q "missing"; then
            ERRORS_FOUND="${ERRORS_FOUND}  - Missing data detected\n"
        fi
        
        return $exit_code
    fi
}

# Main check logic
echo "Starting Borg integrity check for $HOSTNAME at $CHECK_DATE"
echo "Repository: $REPO_URL"
echo "Check depth: $CHECK_DEPTH"

# Repository consistency check (always performed)
if ! run_borg_check "--repository-only" "Repository consistency"; then
    # Repository check failure is critical - stop here
    CHECK_END=$(date +%s)
    CHECK_DURATION=$((CHECK_END - CHECK_START))
    
    send_notification "critical" \
        "[$HOSTNAME] Borg Check Failed" \
        "Repository consistency check failed!\n\nRepository: $REPO_URL\nDuration: ${CHECK_DURATION}s\n\nErrors:\n$ERRORS_FOUND\n\nImmediate attention required!"
    
    exit 1
fi

# Archive metadata check (if depth is archives or data)
if [ "$CHECK_DEPTH" = "archives" ] || [ "$CHECK_DEPTH" = "data" ]; then
    if ! run_borg_check "--archives-only" "Archive metadata"; then
        # Archive check failure is serious but not necessarily critical
        echo "WARNING: Archive metadata check failed, but repository is consistent"
    fi
fi

# Full data verification (if depth is data)
if [ "$CHECK_DEPTH" = "data" ]; then
    echo "Performing full data verification on last $LAST_ARCHIVES archives..."
    
    # Get the list of archives and select the last N
    if ARCHIVE_LIST=$(borg list --short 2>/dev/null | tail -n "$LAST_ARCHIVES"); then
        if [ -n "$ARCHIVE_LIST" ]; then
            # Build the check command with specific archives
            ARCHIVE_ARGS=""
            while IFS= read -r archive; do
                ARCHIVE_ARGS="$ARCHIVE_ARGS --glob-archives '$archive'"
            done <<< "$ARCHIVE_LIST"
            
            # Run data verification on selected archives
            if ! run_borg_check "$ARCHIVE_ARGS" "Data verification ($LAST_ARCHIVES archives)"; then
                echo "WARNING: Data verification failed for some archives"
            fi
        else
            echo "No archives found for data verification"
            CHECK_DETAILS="${CHECK_DETAILS}⚠ No archives available for data verification\n"
        fi
    else
        echo "Failed to list archives for data verification"
        CHECK_DETAILS="${CHECK_DETAILS}⚠ Could not list archives for data verification\n"
    fi
fi

# Calculate total duration
CHECK_END=$(date +%s)
CHECK_DURATION=$((CHECK_END - CHECK_START))

# Format duration for display
if [ $CHECK_DURATION -ge 3600 ]; then
    DURATION_STR="$(($CHECK_DURATION / 3600))h $(($CHECK_DURATION % 3600 / 60))m"
elif [ $CHECK_DURATION -ge 60 ]; then
    DURATION_STR="$(($CHECK_DURATION / 60))m $(($CHECK_DURATION % 60))s"
else
    DURATION_STR="${CHECK_DURATION}s"
fi

# Get repository statistics for the notification
REPO_STATS=""
if REPO_INFO=$(borg info --json 2>/dev/null); then
    # Try to extract useful stats (this is a simplified version)
    if command -v jq >/dev/null 2>&1; then
        TOTAL_SIZE=$(echo "$REPO_INFO" | jq -r '.cache.stats.total_size // 0' 2>/dev/null || echo "0")
        TOTAL_CHUNKS=$(echo "$REPO_INFO" | jq -r '.cache.stats.total_chunks // 0' 2>/dev/null || echo "0")
        
        if [ "$TOTAL_SIZE" != "0" ]; then
            # Convert bytes to human-readable format
            TOTAL_SIZE_MB=$((TOTAL_SIZE / 1024 / 1024))
            if [ $TOTAL_SIZE_MB -ge 1024 ]; then
                TOTAL_SIZE_GB=$((TOTAL_SIZE_MB / 1024))
                REPO_STATS="\n\nRepository Stats:\n• Total size: ${TOTAL_SIZE_GB}GB\n• Total chunks: $TOTAL_CHUNKS"
            else
                REPO_STATS="\n\nRepository Stats:\n• Total size: ${TOTAL_SIZE_MB}MB\n• Total chunks: $TOTAL_CHUNKS"
            fi
        fi
    fi
fi

# Prepare final message
if [ "$CHECK_RESULT" = "SUCCESS" ]; then
    SUCCESS_MSG="Integrity check completed successfully for $HOSTNAME\n\n"
    SUCCESS_MSG="${SUCCESS_MSG}Repository: $REPO_URL\n"
    SUCCESS_MSG="${SUCCESS_MSG}Check depth: $CHECK_DEPTH\n"
    SUCCESS_MSG="${SUCCESS_MSG}Duration: $DURATION_STR\n\n"
    SUCCESS_MSG="${SUCCESS_MSG}Results:\n$CHECK_DETAILS"
    SUCCESS_MSG="${SUCCESS_MSG}$REPO_STATS"
    
    echo "Integrity check completed successfully"
    echo -e "$SUCCESS_MSG"
    
    send_notification "normal" \
        "[$HOSTNAME] Borg Check Passed" \
        "$SUCCESS_MSG"
else
    FAILURE_MSG="Integrity check found issues for $HOSTNAME\n\n"
    FAILURE_MSG="${FAILURE_MSG}Repository: $REPO_URL\n"
    FAILURE_MSG="${FAILURE_MSG}Check depth: $CHECK_DEPTH\n"
    FAILURE_MSG="${FAILURE_MSG}Duration: $DURATION_STR\n\n"
    FAILURE_MSG="${FAILURE_MSG}Issues found:\n$ERRORS_FOUND\n"
    FAILURE_MSG="${FAILURE_MSG}Successful checks:\n$CHECK_DETAILS"
    FAILURE_MSG="${FAILURE_MSG}$REPO_STATS"
    
    echo "Integrity check completed with errors"
    echo -e "$FAILURE_MSG"
    
    send_notification "high" \
        "[$HOSTNAME] Borg Check Issues" \
        "$FAILURE_MSG"
    
    # Exit with error code to indicate failure
    exit 1
fi

echo "Integrity check process completed"
