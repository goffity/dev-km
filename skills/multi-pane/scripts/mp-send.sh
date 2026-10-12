#!/usr/bin/env bash
# mp-send.sh <pane_id> <file|-> — paste a (multi-line) instruction into a worker pane and make sure it was submitted.
# Pasting via tmux often leaves the text unsubmitted in the input box → press Enter until the text has left the input box
# (or the pane shows "esc to interrupt"). Never presses Enter on the folder-trust dialog.
set -euo pipefail
pid=$1; src=${2:--}
if tmux capture-pane -p -t "$pid" | grep -q 'trust this folder'; then
  echo "ABORT: $pid is on the folder-trust dialog (Enter would pick \"No, exit\")" >&2; exit 3; fi
tmp=$(mktemp); if [ "$src" = - ]; then cat > "$tmp"; else cat "$src" > "$tmp"; fi
probe=$(grep -m1 -v '^\s*$' "$tmp" | cut -c1-24)
tmux send-keys -t "$pid" C-u
tmux load-buffer -b mp-send "$tmp" && tmux paste-buffer -d -b mp-send -t "$pid"
rm -f "$tmp"
for _ in 1 2 3 4; do
  sleep 2; tmux send-keys -t "$pid" C-m; sleep 3
  scr=$(tmux capture-pane -p -t "$pid")
  if printf '%s' "$scr" | grep -q 'esc to interrupt'; then echo "sent → $pid (running)"; exit 0; fi
  # input box = last 6 lines; submitted when the probe text is no longer there
  if ! printf '%s' "$scr" | tail -6 | grep -qF -- "$probe"; then echo "sent → $pid"; exit 0; fi
done
echo "WARN: $pid still has the text in its input box (check with mp-peek.sh $pid)" >&2; exit 2
