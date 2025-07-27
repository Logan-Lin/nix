#!/bin/bash

# Universal project launcher - reads project config and launches appropriate template
# Usage: project-launcher.sh PROJECT_NAME

PROJECT_NAME="$1"
CONFIG_DIR="$(dirname "$0")/../config"
PROJECTS_JSON="$CONFIG_DIR/projects.json"
TEMPLATES_DIR="$(dirname "$0")/templates"

if [ -z "$PROJECT_NAME" ]; then
    printf "\033[1;36mAvailable Projects:\033[0m\n\n"
    
    if [ -f "$PROJECTS_JSON" ]; then
        # Check if jq is available and JSON is valid
        if ! command -v jq >/dev/null 2>&1; then
            echo "Error: jq not found. Please install jq or run 'home-manager switch'."
            exit 1
        fi
        
        # Parse and display projects with descriptions
        jq -r '.projects | to_entries[] | "\(.key)|\(.value.description)|\(.value.template)"' "$PROJECTS_JSON" 2>/dev/null | \
        while IFS='|' read -r name desc template; do
            # Format with consistent spacing
            printf "  \033[1;32m%-12s\033[0m \033[2m[%-8s]\033[0m %s\n" \
                "$name" "$template" "$desc"
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