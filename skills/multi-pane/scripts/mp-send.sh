#!/usr/bin/env bash
# mp-send.sh <pane_id> <file|-> — paste a (multi-line) instruction into a worker pane and make sure it was submitted.
# Pasting via tmux often leaves the text unsubmitted in the input box → press Enter until the pane shows
# "esc to interrupt" (busy) or the input box (between the last two ──── rules) is empty. Never presses Enter on the
# folder-trust dialog. Long briefs scroll the screen, so checking for the first line of the text is NOT reliable.
set -euo pipefail
pid=$1; src=${2:--}
if tmux capture-pane -p -t "$pid" | grep -q 'trust this folder'; then
  echo "ABORT: $pid is on the folder-trust dialog (Enter would pick \"No, exit\")" >&2; exit 3; fi
tmp=$(mktemp); if [ "$src" = - ]; then cat > "$tmp"; else cat "$src" > "$tmp"; fi
tmux send-keys -t "$pid" C-u
tmux load-buffer -b mp-send "$tmp" && tmux paste-buffer -d -b mp-send -t "$pid"
rm -f "$tmp"
input_box_empty() {  # text between the last two ──── rules (the input box) is only the prompt "❯"
  tmux capture-pane -p -t "$pid" | awk '
    { line[NR]=$0 } /^─{10,}/ { r1=r2; r2=NR }
    END { if (!r1) exit 1; c=""; for (i=r1+1; i<r2; i++) c=c line[i]; gsub(/[ \t❯]/, "", c); exit (c=="" ? 0 : 1) }'
}
for _ in 1 2 3 4 5; do
  sleep 2; tmux send-keys -t "$pid" C-m; sleep 3
  if tmux capture-pane -p -t "$pid" | grep -q 'esc to interrupt'; then echo "sent → $pid (running)"; exit 0; fi
  if input_box_empty; then echo "sent → $pid"; exit 0; fi
done
echo "WARN: $pid still has text in its input box — check with mp-peek.sh $pid" >&2; exit 2
