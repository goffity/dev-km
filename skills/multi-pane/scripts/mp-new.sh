#!/usr/bin/env bash
# mp-new.sh "<label>" [cwd] [session] — start a Claude worker pane in the tmux session, register its label, print the pane id.
# Label convention: "<n> <ROLE> · <scope>", e.g. "2 FRONTEND · huayplus69" / "5 QA · dev". Runs claude with inherited
# CLAUDE_CODE_* env removed so it is an independent session (not a child of the main session).
set -euo pipefail
label=$1; cwd=${2:-$PWD}; S=${3:-${MP_SESSION:-mp}}
tmux has-session -t "$S" 2>/dev/null || { echo "no tmux session '$S' — run mp-init.sh first" >&2; exit 1; }
first=$(tmux list-panes -t "$S:workers" -F '#{pane_id} #{pane_title}' | awk '$2=="(empty)"{print $1; exit}')
if [ -n "$first" ]; then
  pid=$first; tmux send-keys -t "$pid" "cd $(printf %q "$cwd")" C-m
else
  pid=$(tmux split-window -t "$S:workers" -c "$cwd" -P -F '#{pane_id}')
  tmux select-layout -t "$S:workers" tiled >/dev/null
fi
tmux select-pane -t "$pid" -T "$label"
tmux set-option -p -t "$pid" @label "$label"   # Claude overwrites pane_title; the border shows @label
grep -v "^$pid " "$HOME/.claude/pane-labels" > "$HOME/.claude/pane-labels.tmp" 2>/dev/null || true
echo "$pid $label" >> "$HOME/.claude/pane-labels.tmp"; mv "$HOME/.claude/pane-labels.tmp" "$HOME/.claude/pane-labels"
tmux send-keys -t "$pid" "clear; env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN -u CLAUDE_CODE_SESSION_ATTENDED -u CLAUDE_PID -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_VERSION -u CLAUDE_EFFORT claude" C-m
# wait until the Claude prompt is up (status line), but stop on the folder-trust dialog — never auto-accept it
for _ in $(seq 1 40); do
  scr=$(tmux capture-pane -p -t "$pid")
  if printf '%s' "$scr" | grep -q 'trust this folder'; then
    echo "$pid"; echo "WARN: $pid is waiting on the folder-trust dialog for $cwd — ask the user to confirm in the tmux window (or use a trusted repo dir)" >&2; exit 3
  fi
  printf '%s' "$scr" | grep -q 'shift+tab\|auto mode\|? for shortcuts' && { echo "$pid"; exit 0; }
  sleep 1
done
echo "$pid"; echo "WARN: $pid not ready after 40s (check mp-peek.sh $pid)" >&2; exit 2
