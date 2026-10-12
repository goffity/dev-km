#!/usr/bin/env bash
# mp-peek.sh <pane_id> [lines] — show the last lines of a pane (joined, blank lines removed). The Claude TUI keeps no
# scrollback: for long reports ask the worker to write a file instead.
pid=$1; n=${2:-25}
tmux capture-pane -p -J -t "$pid" | grep -v '^\s*$' | tail -n "$n"
