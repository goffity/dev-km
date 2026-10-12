#!/usr/bin/env bash
# mp-watch.sh — block until any registered worker pane shows a NEW marker, print "label :: marker" lines, exit 0.
# Markers: OWNER-DONE <repo>#<PR> …, OWNER-FIXING …, QA-RESULT <repo>#<PR> PASS|FAIL …, NEED-INPUT <text>.
# Run it with run_in_background so the main session is woken when something happens. Also wakes on a pane that is
# waiting for input (Notification hook) so questions are not missed. Seen markers are kept in ~/.claude/mp-seen.txt.
SEEN="$HOME/.claude/mp-seen.txt"; LABELS="$HOME/.claude/pane-labels"; LOG="$HOME/.claude/pane-status.log"
touch "$SEEN" "$LOG"
last=$(wc -l < "$LOG")
while true; do
  found=""
  while read -r pid label; do
    [ -n "$pid" ] || continue
    tmux has-session -t "$pid" 2>/dev/null || continue
    lines=$(tmux capture-pane -p -J -S -200 -t "$pid" 2>/dev/null \
      | grep -oE '(QA-RESULT|OWNER-DONE|OWNER-FIXING|NEED-INPUT) [^│]*' | grep -v '<repo>\|<PR>\|PASS หรือ\|PASS/FAIL\|PASS|FAIL' | sed 's/ *$//' | cut -c1-240)
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      key="$pid|$(printf '%s' "$m" | cut -c1-80)"
      grep -qxF "$key" "$SEEN" || { echo "$key" >> "$SEEN"; found="${found}${label} :: ${m}"$'\n'; }
    done <<< "$lines"
  done < "$LABELS"
  now=$(wc -l < "$LOG")
  if [ "$now" -gt "$last" ]; then
    q=$(tail -n $((now-last)) "$LOG" | grep '| Notification |' || true); last=$now
    [ -n "$q" ] && found="${found}$(printf '%s' "$q" | sed 's/^/[ASK] /')"$'\n'
  fi
  [ -n "$found" ] && { printf '%s' "$found"; exit 0; }
  sleep 20
done
