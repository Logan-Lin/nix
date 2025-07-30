#!/bin/bash

# Basic development template - single directory with nvim, ai, git, shell
# Usage: basic.sh SESSION_NAME CODE_PATH

SESSION_NAME="$1"
CODE_PATH="$2"

if [ -z "$SESSION_NAME" ] || [ -z "$CODE_PATH" ]; then
    echo "Usage: $0 SESSION_NAME CODE_PATH"
    exit 1
fi

tmux new-session -d -s $SESSION_NAME -c "$CODE_PATH"

# Record directory in zoxide for smart navigation
zoxide add "$CODE_PATH" 2>/dev/null || true
tmux rename-window -t $SESSION_NAME:1 "nvim"
tmux send-keys -t $SESSION_NAME:1 "nvim" C-m
sleep 0.5  # Brief delay to ensure nvim loads
tmux send-keys -t $SESSION_NAME:1 " e"
tmux new-window -t $SESSION_NAME:2 -n "ai" -c "$CODE_PATH"
tmux send-keys -t $SESSION_NAME:2 "claude -c" C-m
tmux split-window -t $SESSION_NAME:2 -h -c "$CODE_PATH"
tmux split-window -t $SESSION_NAME:2.2 -v -c "$CODE_PATH"
tmux select-pane -t $SESSION_NAME:2.1
tmux new-window -t $SESSION_NAME:3 -n "git" -c "$CODE_PATH"
tmux send-keys -t $SESSION_NAME:3 "lazygit" C-m
tmux new-window -t $SESSION_NAME:4 -n "shell" -c "$CODE_PATH"

tmux select-window -t $SESSION_NAME:1

tmux attach-session -t $SESSION_NAME