#!/bin/bash

# Research workflow template - code + separate paper directory + optional remote server
# Usage: research.sh SESSION_NAME CODE_PATH PAPER_PATH [SERVER] [REMOTE_DIR]

SESSION_NAME="$1"
CODE_PATH="$2"
PAPER_PATH="$3"
SERVER="$4"
REMOTE_DIR="$5"

if [ -z "$SESSION_NAME" ] || [ -z "$CODE_PATH" ] || [ -z "$PAPER_PATH" ]; then
    echo "Usage: $0 SESSION_NAME CODE_PATH PAPER_PATH [SERVER] [REMOTE_DIR]"
    exit 1
fi

# Create windows for code
tmux new-session -d -s $SESSION_NAME -c "$CODE_PATH"
tmux rename-window -t $SESSION_NAME:1 "code"
tmux send-keys -t $SESSION_NAME:1 "nvim" C-m
tmux new-window -t $SESSION_NAME:2 -n "code-ai" -c "$CODE_PATH"
tmux send-keys -t $SESSION_NAME:2 "claude -c" C-m
tmux split-window -t $SESSION_NAME:2 -h -c "$CODE_PATH"
tmux split-window -t $SESSION_NAME:2.2 -v -c "$CODE_PATH"
tmux select-pane -t $SESSION_NAME:2.1
tmux new-window -t $SESSION_NAME:3 -n "code-git" -c "$CODE_PATH"
tmux send-keys -t $SESSION_NAME:3 "lazygit" C-m

# Create windows for paper
tmux new-window -t $SESSION_NAME:4 -n "paper" -c "$PAPER_PATH"
tmux select-window -t $SESSION_NAME:4
tmux send-keys -t $SESSION_NAME:4 "nvim" C-m
tmux new-window -t $SESSION_NAME:5 -n "paper-ai" -c "$PAPER_PATH"
tmux send-keys -t $SESSION_NAME:5 "claude -c" C-m
tmux split-window -t $SESSION_NAME:5 -h -c "$PAPER_PATH"
tmux split-window -t $SESSION_NAME:5.2 -v -c "$PAPER_PATH"
tmux select-pane -t $SESSION_NAME:5.1
tmux new-window -t $SESSION_NAME:6 -n "paper-git" -c "$PAPER_PATH"
tmux send-keys -t $SESSION_NAME:6 "lazygit" C-m

# Create remote server window if server details are provided
if [ -n "$SERVER" ] && [ -n "$REMOTE_DIR" ]; then
    tmux new-window -t $SESSION_NAME:7 -n "remote" -c "$CODE_PATH"
    tmux send-keys -t $SESSION_NAME:7 "alias r='ssh $SERVER -t \"cd $REMOTE_DIR && exec \\\$SHELL\"'" C-m
    tmux send-keys -t $SESSION_NAME:7 "ssh $SERVER -t 'cd $REMOTE_DIR && exec \$SHELL'" C-m
    tmux split-window -t $SESSION_NAME:7 -v -c "$CODE_PATH"
    tmux send-keys -t $SESSION_NAME:7.2 "alias r='ssh $SERVER -t \"cd $REMOTE_DIR && exec \\\$SHELL\"'" C-m
    tmux send-keys -t $SESSION_NAME:7.2 "ssh $SERVER -t 'cd $REMOTE_DIR && exec \$SHELL'" C-m
    tmux select-pane -t $SESSION_NAME:7.1
fi

tmux select-window -t $SESSION_NAME:1

tmux attach-session -t $SESSION_NAME