# Container update script with Gotify notifications
# Updates all podman containers to latest images

set -euo pipefail

# Configuration from environment (set by systemd service)
GOTIFY_URL="${GOTIFY_URL:-}"
GOTIFY_TOKEN="${GOTIFY_TOKEN:-}"
EXCLUDE_CONTAINERS="${EXCLUDE_CONTAINERS:-}"

# Convert excluded containers to array
IFS=',' read -ra EXCLUDED <<< "$EXCLUDE_CONTAINERS"

# Function to send Gotify notification
send_notification() {
    local priority="$1"
    local title="$2"
    local message="$3"
    
    if [[ -n "$GOTIFY_URL" ]] && [[ -n "$GOTIFY_TOKEN" ]]; then
        /home/yanlin/.config/nix/scripts/gotify-notify.sh \
            "$GOTIFY_URL" \
            "$GOTIFY_TOKEN" \
            "$priority" \
            "$title" \
            "$message" 2>&1 || echo "Failed to send notification"
    fi
}

# Get all running containers
echo "Getting list of running containers..."
containers=$(podman ps --format "{{.Names}}")

if [[ -z "$containers" ]]; then
    echo "No running containers found"
    exit 0
fi

# Arrays to track updates
updated_containers=()
failed_containers=()
skipped_containers=()

# Update each container
for container in $containers; do
    # Check if container is in exclude list
    skip=false
    for excluded in "${EXCLUDED[@]}"; do
        if [[ "$container" == "$excluded" ]]; then
            echo "Skipping excluded container: $container"
            skipped_containers+=("$container")
            skip=true
            break
        fi
    done
    
    if [[ "$skip" == true ]]; then
        continue
    fi
    
    echo "Processing container: $container"
    
    # Get current image
    image=$(podman inspect "$container" --format '{{.ImageName}}')
    
    if [[ -z "$image" ]]; then
        echo "ERROR: Could not get image for container $container"
        failed_containers+=("$container (no image)")
        continue
    fi
    
    echo "  Current image: $image"
    
    # Get current image ID before pull
    old_image_id=$(podman inspect "$container" --format '{{.Image}}')
    
    # Pull latest image
    echo "  Pulling latest image..."
    if podman pull "$image" 2>&1; then
        echo "  Image pulled successfully"
        
        # Get new image ID after pull
        new_image_id=$(podman inspect "$image" --format '{{.Id}}')
        
        # Check if image actually changed
        if [[ "$old_image_id" != "$new_image_id" ]]; then
            echo "  New image detected, restarting container..."
            
            # Restart container
            if podman restart "$container" 2>&1; then
                echo "  Container updated successfully"
                updated_containers+=("$container")
            else
                echo "  ERROR: Failed to restart container"
                failed_containers+=("$container (restart failed)")
            fi
        else
            echo "  Image unchanged, skipping restart"
            skipped_containers+=("$container (no update)")
        fi
    else
        echo "  ERROR: Failed to pull image"
        failed_containers+=("$container (pull failed)")
    fi
    
    echo ""
done

# Prepare notification message
notification_lines=()
notification_priority="normal"

if [[ ${#updated_containers[@]} -gt 0 ]]; then
    notification_lines+=("✅ Updated (${#updated_containers[@]}):")
    for container in "${updated_containers[@]}"; do
        notification_lines+=("  • $container")
    done
fi

if [[ ${#failed_containers[@]} -gt 0 ]]; then
    notification_priority="high"
    notification_lines+=("")
    notification_lines+=("❌ Failed (${#failed_containers[@]}):")
    for container in "${failed_containers[@]}"; do
        notification_lines+=("  • $container")
    done
fi

if [[ ${#skipped_containers[@]} -gt 0 ]]; then
    notification_lines+=("")
    notification_lines+=("⏭️ No updates (${#skipped_containers[@]}):")
    for container in "${skipped_containers[@]}"; do
        notification_lines+=("  • $container")
    done
fi

# Send notification if there were any updates or failures
if [[ ${#notification_lines[@]} -gt 0 ]]; then
    # Build multi-line message similar to borg-client
    message=""
    for line in "${notification_lines[@]}"; do
        if [[ -n "$message" ]]; then
            message="${message}\n${line}"
        else
            message="$line"
        fi
    done
    
    send_notification "$notification_priority" "Container Update" "$message"
fi

# Exit with error if any containers failed
if [[ ${#failed_containers[@]} -gt 0 ]]; then
    echo "ERROR: Some containers failed to update"
    exit 1
fi

echo "Container update completed successfully"
