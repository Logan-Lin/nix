#!/bin/bash

# Research workflow template - code + separate paper directory
# Usage: research.sh SESSION_NAME CODE_PATH PAPER_PATH

SESSION_NAME="$1"
CODE_PATH="$2"
PAPER_PATH="$3"

if [ -z "$SESSION_NAME" ] || [ -z "$CODE_PATH" ] || [ -z "$PAPER_PATH" ]; then
    echo "Usage: $0 SESSION_NAME CODE_PATH PAPER_PATH"
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
tmux new-window -t $SESSION_NAME:3 -n "code-git" -c "$CODE_PATH"
tmux send-keys -t $SESSION_NAME:3 "gitui" C-m

# Create windows for paper
tmux new-window -t $SESSION_NAME:4 -n "paper" -c "$PAPER_PATH"
tmux select-window -t $SESSION_NAME:4
tmux send-keys -t $SESSION_NAME:4 "nvim" C-m
tmux new-window -t $SESSION_NAME:5 -n "paper-ai" -c "$PAPER_PATH"
tmux send-keys -t $SESSION_NAME:5 "claude -r" C-m
tmux split-window -t $SESSION_NAME:5 -h -c "$PAPER_PATH"
tmux split-window -t $SESSION_NAME:5.2 -v -c "$PAPER_PATH"
tmux select-pane -t $SESSION_NAME:5.1
tmux new-window -t $SESSION_NAME:6 -n "paper-git" -c "$PAPER_PATH"
tmux send-keys -t $SESSION_NAME:6 "gitui" C-m

tmux select-window -t $SESSION_NAME:1

tmux attach-session -t $SESSION_NAME