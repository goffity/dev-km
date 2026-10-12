#!/usr/bin/env bash
# mp-init.sh [session] — create the detached tmux session for worker panes (main session stays a normal terminal).
# Opens a new iTerm/Terminal window attached to it so the user can watch. Safe to run twice.
set -euo pipefail
S=${1:-${MP_SESSION:-mp}}
if ! tmux has-session -t "$S" 2>/dev/null; then
  tmux new-session -d -s "$S" -n workers -x 240 -y 60 -c "$PWD"
  tmux set-option -t "$S" pane-border-status top
  tmux set-option -t "$S" pane-border-format ' #{?#{@label},#{@label},#{pane_title}} '
  # first pane is a placeholder shell; mp-new.sh reuses it for the first worker
  tmux select-pane -t "$(tmux list-panes -t "$S:workers" -F '#{pane_id}' | head -1)" -T "(empty)"
  echo "created tmux session '$S'"
else
  echo "tmux session '$S' already exists"
fi
touch "$HOME/.claude/pane-labels" "$HOME/.claude/pane-status.log"
if [ "${MP_NO_WINDOW:-0}" != 1 ]; then
  if [ -d /Applications/iTerm.app ]; then
    osascript -e "tell application \"iTerm\" to create window with default profile command \"tmux attach -t $S\"" >/dev/null 2>&1 || true
  else
    osascript -e "tell application \"Terminal\" to do script \"tmux attach -t $S\"" >/dev/null 2>&1 || true
  fi
fi
echo "watch with: tmux attach -t $S"
