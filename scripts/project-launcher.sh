#!/bin/bash

# Universal project launcher - reads project config and launches dynamic windows
# Usage: project-launcher.sh PROJECT_NAME

PROJECT_NAME="$1"
CONFIG_DIR="$(dirname "$0")/../config"
PROJECTS_JSON="$CONFIG_DIR/projects.json"

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
        jq -r '.projects | to_entries[] | "\(.key)|\(.value.description)|\(.value.session)"' "$PROJECTS_JSON" 2>/dev/null | \
        while IFS='|' read -r name desc session_name; do
            # Check if session is running and format accordingly
            if is_session_running "$session_name"; then
                printf "  \033[1;32m%-12s\033[0m %s\033[1;32m • Running\033[0m\n" \
                    "$name" "$desc"
            else
                printf "  \033[1;32m%-12s\033[0m %s\n" \
                    "$name" "$desc"
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

SESSION_NAME=$(echo "$PROJECT_CONFIG" | jq -r '.session')
DESCRIPTION=$(echo "$PROJECT_CONFIG" | jq -r '.description // empty')

# Check if session already exists and attach if it does
if is_session_running "$SESSION_NAME"; then
    printf "\033[1;32mAttaching to existing session: %s\033[0m\n" "$SESSION_NAME"
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

# Update papis cache
papis cache reset > /dev/null 2>&1

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

# Initialize git repository if it doesn't exist
init_git_if_needed() {
    local dir_path="$1"
    local window_name="$2"
    
    if [ -n "$dir_path" ] && [ "$dir_path" != "null" ] && [ -d "$dir_path" ]; then
        if [ ! -d "$dir_path/.git" ]; then
            if git -C "$dir_path" init >/dev/null 2>&1; then
                printf "\033[2mInitialized git repository for %s: %s\033[0m\n" "$window_name" "$dir_path"
            else
                echo "Warning: Could not initialize git repository in: $dir_path"
            fi
        fi
    fi
}

# Get windows configuration
WINDOWS=$(echo "$PROJECT_CONFIG" | jq -c '.windows[]' 2>/dev/null)

if [ -z "$WINDOWS" ]; then
    echo "Error: No windows configured for project '$PROJECT_NAME'"
    exit 1
fi

# Get the first window configuration to create the session
FIRST_WINDOW=$(echo "$WINDOWS" | head -n 1)
FIRST_WINDOW_NAME=$(echo "$FIRST_WINDOW" | jq -r '.name')
FIRST_WINDOW_PATH=$(echo "$FIRST_WINDOW" | jq -r '.path')

# Create directory for first window
create_directory "$FIRST_WINDOW_PATH" "$FIRST_WINDOW_NAME"

# Record directory in zoxide for smart navigation
[ -n "$FIRST_WINDOW_PATH" ] && [ "$FIRST_WINDOW_PATH" != "null" ] && [ -d "$FIRST_WINDOW_PATH" ] && zoxide add "$FIRST_WINDOW_PATH" 2>/dev/null || true

# Create session with first window
tmux new-session -d -s "$SESSION_NAME" -c "$FIRST_WINDOW_PATH"

# Initialize window counter
WINDOW_INDEX=1

# Process each window configuration
while IFS= read -r window_config; do
    WINDOW_NAME=$(echo "$window_config" | jq -r '.name')
    WINDOW_PATH=$(echo "$window_config" | jq -r '.path')
    
    # Create directory if it doesn't exist (for all window entries)
    create_directory "$WINDOW_PATH" "$WINDOW_NAME"
    # Record directory in zoxide for smart navigation
    [ -n "$WINDOW_PATH" ] && [ "$WINDOW_PATH" != "null" ] && [ -d "$WINDOW_PATH" ] && zoxide add "$WINDOW_PATH" 2>/dev/null || true
    
    # Check window options
    NVIM_ENABLED=$(echo "$window_config" | jq -r '.nvim // true')
    AI_ENABLED=$(echo "$window_config" | jq -r '.ai // false')
    GIT_ENABLED=$(echo "$window_config" | jq -r '.git // false')
    SHELL_ENABLED=$(echo "$window_config" | jq -r '.shell // false')
    
    # Initialize git repository if git is enabled and repo doesn't exist
    if [ "$GIT_ENABLED" = "true" ]; then
        init_git_if_needed "$WINDOW_PATH" "$WINDOW_NAME"
    fi
    
    # Create nvim window (default behavior unless explicitly disabled)
    if [ "$NVIM_ENABLED" != "false" ]; then
        if [ "$WINDOW_INDEX" = 1 ]; then
            # First window - rename the existing session window
            tmux rename-window -t "$SESSION_NAME:$WINDOW_INDEX" "${WINDOW_NAME}-nvim"
        else
            # Subsequent windows - create new window
            tmux new-window -t "$SESSION_NAME:$WINDOW_INDEX" -n "${WINDOW_NAME}-nvim" -c "$WINDOW_PATH"
        fi
        tmux send-keys -t "$SESSION_NAME:$WINDOW_INDEX" "nvim" C-m
        sleep 0.5  # Brief delay to ensure nvim loads
        tmux send-keys -t "$SESSION_NAME:$WINDOW_INDEX" " e"
        WINDOW_INDEX=$((WINDOW_INDEX + 1))
    fi
    
    # Create AI window if enabled
    if [ "$AI_ENABLED" = "true" ]; then
        tmux new-window -t "$SESSION_NAME:$WINDOW_INDEX" -n "${WINDOW_NAME}-ai" -c "$WINDOW_PATH"
        tmux send-keys -t "$SESSION_NAME:$WINDOW_INDEX" "claude -c" C-m
        tmux split-window -t "$SESSION_NAME:$WINDOW_INDEX" -h -c "$WINDOW_PATH"
        tmux split-window -t "$SESSION_NAME:$WINDOW_INDEX.2" -v -c "$WINDOW_PATH"
        tmux select-pane -t "$SESSION_NAME:$WINDOW_INDEX.1"
        WINDOW_INDEX=$((WINDOW_INDEX + 1))
    fi
    
    # Create git window if enabled
    if [ "$GIT_ENABLED" = "true" ]; then
        tmux new-window -t "$SESSION_NAME:$WINDOW_INDEX" -n "${WINDOW_NAME}-git" -c "$WINDOW_PATH"
        tmux send-keys -t "$SESSION_NAME:$WINDOW_INDEX" "lazygit" C-m
        tmux setw -t "$SESSION_NAME:$WINDOW_INDEX" monitor-activity off
        WINDOW_INDEX=$((WINDOW_INDEX + 1))
    fi
    
    # Create shell window if enabled
    if [ "$SHELL_ENABLED" = "true" ]; then
        tmux new-window -t "$SESSION_NAME:$WINDOW_INDEX" -n "${WINDOW_NAME}-shell" -c "$WINDOW_PATH"
        WINDOW_INDEX=$((WINDOW_INDEX + 1))
    fi
    
done <<< "$WINDOWS"

# Select the first window
tmux select-window -t "$SESSION_NAME:1"

# Attach to session
tmux attach-session -t "$SESSION_NAME"