#!/usr/bin/env bash
# mp-close.sh <pane_id>... — kill worker panes and unregister their labels (check they are idle first with mp-peek.sh).
for pid in "$@"; do
  tmux kill-pane -t "$pid" 2>/dev/null && echo "closed $pid"
  grep -v "^$pid " "$HOME/.claude/pane-labels" > "$HOME/.claude/pane-labels.tmp" 2>/dev/null; mv "$HOME/.claude/pane-labels.tmp" "$HOME/.claude/pane-labels"
done
