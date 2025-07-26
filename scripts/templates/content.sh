#!/bin/bash

# Content workflow template - code + separate content directory
# Usage: content.sh SESSION_NAME CODE_PATH CONTENT_PATH

SESSION_NAME="$1"
CODE_PATH="$2"
CONTENT_PATH="$3"

if [ -z "$SESSION_NAME" ] || [ -z "$CODE_PATH" ] || [ -z "$CONTENT_PATH" ]; then
    echo "Usage: $0 SESSION_NAME CODE_PATH CONTENT_PATH"
    exit 1
fi

if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

# Create windows for code
tmux new-session -d -s $SESSION_NAME -c "$CODE_PATH"
tmux rename-window -t $SESSION_NAME:1 "code"
tmux send-keys -t $SESSION_NAME:1 "nvim" C-m
tmux new-window -t $SESSION_NAME:2 -n "code-ai" -c "$CODE_PATH"
tmux send-keys -t $SESSION_NAME:2 "claude -r" C-m
tmux split-window -t $SESSION_NAME:2 -h -c "$CODE_PATH"
tmux split-window -t $SESSION_NAME:2.2 -v -c "$CODE_PATH"
tmux select-pane -t $SESSION_NAME:2.1
tmux new-window -t $SESSION_NAME:3 -n "git" -c "$CODE_PATH"
tmux send-keys -t $SESSION_NAME:3 "gitui" C-m

# Create windows for content
tmux new-window -t $SESSION_NAME:4 -n "content-ai" -c "$CONTENT_PATH"
tmux send-keys -t $SESSION_NAME:4 "claude -r" C-m
tmux split-window -t $SESSION_NAME:4 -h -c "$CONTENT_PATH"
tmux split-window -t $SESSION_NAME:4.2 -v -c "$CONTENT_PATH"
tmux select-pane -t $SESSION_NAME:4.1

tmux select-window -t $SESSION_NAME:1

tmux attach-session -t $SESSION_NAME