#!/bin/bash

# Universal project launcher - reads project config and launches appropriate template
# Usage: project-launcher.sh PROJECT_NAME

PROJECT_NAME="$1"
CONFIG_DIR="$(dirname "$0")/../config"
PROJECTS_JSON="$CONFIG_DIR/projects.json"
TEMPLATES_DIR="$(dirname "$0")/templates"

# Check if tmux session is running
is_session_running() {
    local session_name="$1"
    tmux has-session -t "$session_name" 2>/dev/null
}

if [ -z "$PROJECT_NAME" ]; then
    printf "\033[1;36mAvailable Projects:\033[0m\n\n"
    
    if [ -f "$PROJECTS_JSON" ]; then
        # Check if jq is available and JSON is valid
        if ! command -v jq >/dev/null 2>&1; then
            echo "Error: jq not found. Please install jq or run 'home-manager switch'."
            exit 1
        fi
        
        # Parse and display projects with descriptions
        jq -r '.projects | to_entries[] | "\(.key)|\(.value.description)|\(.value.template)|\(.value.name)"' "$PROJECTS_JSON" 2>/dev/null | \
        while IFS='|' read -r name desc template session_name; do
            # Check if session is running and format accordingly
            if is_session_running "$session_name"; then
                printf "  \033[1;32m%-12s\033[0m \033[2m[%-8s]\033[0m %s\033[1;32m • Running\033[0m\n" \
                    "$name" "$template" "$desc"
            else
                printf "  \033[1;32m%-12s\033[0m \033[2m[%-8s]\033[0m %s\n" \
                    "$name" "$template" "$desc"
            fi
        done
        
        if [ $? -ne 0 ]; then
            echo "No projects configured"
        else
            printf "\n\033[2mUsage: proj <name> or just type the project name directly\033[0m\n"
        fi
    else
        echo "No projects configured - run 'home-manager switch' to generate config"
    fi
    exit 1
fi

if [ ! -f "$PROJECTS_JSON" ]; then
    echo "Error: Projects configuration not found. Run 'home-manager switch' to generate config."
    exit 1
fi

# Extract project configuration
PROJECT_CONFIG=$(jq -r ".projects.\"$PROJECT_NAME\"" "$PROJECTS_JSON" 2>/dev/null)
if [ "$PROJECT_CONFIG" = "null" ]; then
    echo "Error: Project '$PROJECT_NAME' not found."
    echo "Available projects:"
    jq -r '.projects | keys[]' "$PROJECTS_JSON" 2>/dev/null
    exit 1
fi

TEMPLATE=$(echo "$PROJECT_CONFIG" | jq -r '.template')
SESSION_NAME=$(echo "$PROJECT_CONFIG" | jq -r '.name')
CODE_PATH=$(echo "$PROJECT_CONFIG" | jq -r '.codePath')
CONTENT_PATH=$(echo "$PROJECT_CONFIG" | jq -r '.contentPath // empty')
PAPER_PATH=$(echo "$PROJECT_CONFIG" | jq -r '.paperPath // empty')
SERVER=$(echo "$PROJECT_CONFIG" | jq -r '.server // empty')
REMOTE_DIR=$(echo "$PROJECT_CONFIG" | jq -r '.remoteDir // empty')

# Create directories if they don't exist
create_directory() {
    local dir_path="$1"
    local dir_name="$2"
    
    if [ -n "$dir_path" ] && [ "$dir_path" != "null" ]; then
        if [ ! -d "$dir_path" ]; then
            if mkdir -p "$dir_path" 2>/dev/null; then
                printf "\033[2mCreated %s directory: %s\033[0m\n" "$dir_name" "$dir_path"
            else
                echo "Warning: Could not create $dir_name directory: $dir_path"
                echo "Please check permissions or create it manually."
            fi
        fi
    fi
}

# Ensure required directories exist
create_directory "$CODE_PATH" "code"
create_directory "$CONTENT_PATH" "content"
create_directory "$PAPER_PATH" "paper"

# Create remote directory if server connection is configured
if [ -n "$SERVER" ] && [ -n "$REMOTE_DIR" ]; then
    printf "\033[2mEnsuring remote directory exists: %s:%s\033[0m\n" "$SERVER" "$REMOTE_DIR"
    if ssh "$SERVER" "mkdir -p \"$REMOTE_DIR\"" 2>/dev/null; then
        printf "\033[2mRemote directory ready: %s:%s\033[0m\n" "$SERVER" "$REMOTE_DIR"
    else
        echo "Warning: Could not create or verify remote directory: $SERVER:$REMOTE_DIR"
        echo "Please check SSH connection and permissions."
    fi
fi

# Launch appropriate template
case "$TEMPLATE" in
    "basic")
        exec "$TEMPLATES_DIR/basic.sh" "$SESSION_NAME" "$CODE_PATH"
        ;;
    "content")
        if [ -z "$CONTENT_PATH" ]; then
            echo "Error: Content template requires contentPath"
            exit 1
        fi
        exec "$TEMPLATES_DIR/content.sh" "$SESSION_NAME" "$CODE_PATH" "$CONTENT_PATH"
        ;;
    "research")
        if [ -z "$PAPER_PATH" ]; then
            echo "Error: Research template requires paperPath"
            exit 1
        fi
        if [ -n "$SERVER" ] && [ -n "$REMOTE_DIR" ]; then
            exec "$TEMPLATES_DIR/research.sh" "$SESSION_NAME" "$CODE_PATH" "$PAPER_PATH" "$SERVER" "$REMOTE_DIR"
        else
            exec "$TEMPLATES_DIR/research.sh" "$SESSION_NAME" "$CODE_PATH" "$PAPER_PATH"
        fi
        ;;
    *)
        echo "Error: Unknown template '$TEMPLATE'"
        exit 1
        ;;
esac