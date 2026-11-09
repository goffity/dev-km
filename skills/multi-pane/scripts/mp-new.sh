#!/usr/bin/env bash
# mp-new.sh "<label>" [cwd] [session] [--ticket KEY-123 [--base <ref>] [--slug <words>]]
# Start a Claude worker pane in the tmux session, register its label, print the pane id.
# Label convention: "<n> <ROLE> · <scope>", e.g. "2 FRONTEND · huayplus69" / "5 QA · dev". Runs claude with inherited
# CLAUDE_CODE_* env removed so it is an independent session (not a child of the main session).
# --ticket: cwd is a repo; the worker starts in that ticket's own worktree + branch (mp-worktree.sh), never in the shared
#           checkout. Use it for every worker that will change code.
set -euo pipefail
pos=(); ticket=''; wtargs=()
while [ $# -gt 0 ]; do
  case $1 in
    --ticket) ticket=${2:?}; shift 2 ;;
    --base|--slug) wtargs+=("$1" "${2:?}"); shift 2 ;;
    *) pos+=("$1"); shift ;;
  esac
done
label=${pos[0]:?usage: mp-new.sh "<label>" [cwd] [session] [--ticket KEY-123 [--base ref] [--slug words]]}
cwd=${pos[1]:-$PWD}; S=${pos[2]:-${MP_SESSION:-mp}}
tmux has-session -t "$S" 2>/dev/null || { echo "no tmux session '$S' — run mp-init.sh first" >&2; exit 1; }
if [ -n "$ticket" ]; then
  cwd=$("$(dirname "$0")/mp-worktree.sh" "$cwd" "$ticket" ${wtargs[@]+"${wtargs[@]}"})
elif top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) \
  && [ "$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir)" = "$top/.git" ]; then
  # a shared main checkout: fine for read-only / QA panes, wrong for code changes
  echo "WARN: worker opens in the shared checkout $top on branch '$(git -C "$top" branch --show-current)' — pass --ticket KEY-123 if it will change code" >&2
fi
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
