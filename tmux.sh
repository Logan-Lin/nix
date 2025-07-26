#!/bin/bash

SESSION_NAME="nix"
WORK_DIR="/Users/yanlin/.config/nix"

if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

tmux new-session -d -s $SESSION_NAME -c "$WORK_DIR"
tmux rename-window -t $SESSION_NAME:1 "nvim"
tmux send-keys -t $SESSION_NAME:1 "nvim" C-m
tmux new-window -t $SESSION_NAME:2 -n "ai"
tmux send-keys -t $SESSION_NAME:2 "claude -r" C-m
tmux split-window -t $SESSION_NAME:2 -h
tmux split-window -t $SESSION_NAME:2.2 -v
tmux select-pane -t $SESSION_NAME:2.1
tmux new-window -t $SESSION_NAME:3 -n "git"
tmux send-keys -t $SESSION_NAME:3 "gitui" C-m
tmux new-window -t $SESSION_NAME:4 -n "shell"

tmux select-window -t $SESSION_NAME:1

tmux attach-session -t $SESSION_NAME
