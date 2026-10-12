#!/usr/bin/env bash
# mp-watch.sh [pane_id ...] — block until a worker pane shows a NEW marker, print "label :: marker" lines, exit 0.
# With pane ids, only those panes are watched (use this when another Claude session also has panes registered).
# Markers: OWNER-DONE <repo>#<PR> …, OWNER-FIXING …, QA-RESULT <repo>#<PR> PASS|FAIL …, NEED-INPUT <text>.
# A bare "QA-RESULT <repo>#<PR>" without PASS/FAIL (e.g. inside a plan) is ignored. Also wakes when a watched pane
# raises a real Notification (permission / question) — the plain idle "waiting for your input" is ignored.
# Run with run_in_background; re-arm after each wake-up. Seen markers are kept in ~/.claude/mp-seen.txt.
SEEN="$HOME/.claude/mp-seen.txt"; LABELS="$HOME/.claude/pane-labels"; LOG="$HOME/.claude/pane-status.log"
touch "$SEEN" "$LOG"
only=" $* "
last=$(wc -l < "$LOG")
while true; do
  found=""; labels_re=""
  while read -r pid label; do
    [ -n "$pid" ] || continue
    [ $# -gt 0 ] && [[ "$only" != *" $pid "* ]] && continue
    tmux has-session -t "$pid" 2>/dev/null || continue
    labels_re="${labels_re}|${label}"
    lines=$(tmux capture-pane -p -J -S -200 -t "$pid" 2>/dev/null \
      | grep -oE '(QA-RESULT|OWNER-DONE|OWNER-FIXING|NEED-INPUT) [^│]*' | sed 's/ *$//' \
      | grep -v '<repo>\|<PR>\|PASS หรือ\|PASS/FAIL\|PASS|FAIL' \
      | grep -vE '^QA-RESULT [^ ]+#[0-9]+$' | cut -c1-240)
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      key="$pid|$(printf '%s' "$m" | cut -c1-80)"
      grep -qxF "$key" "$SEEN" || { echo "$key" >> "$SEEN"; found="${found}${label} :: ${m}"$'\n'; }
    done <<< "$lines"
  done < "$LABELS"
  now=$(wc -l < "$LOG")
  if [ "$now" -gt "$last" ]; then
    q=$(tail -n $((now-last)) "$LOG" | grep '| Notification |' | grep -v 'waiting for your input' \
        | while IFS= read -r l; do lb=$(printf '%s' "$l" | cut -d'|' -f2 | sed 's/^ *//;s/ *$//'); [[ "$labels_re|" == *"|$lb|"* ]] && echo "$l"; done || true)
    last=$now
    [ -n "$q" ] && found="${found}$(printf '%s' "$q" | sed 's/^/[ASK] /')"$'\n'
  fi
  [ -n "$found" ] && { printf '%s' "$found"; exit 0; }
  sleep 20
done
