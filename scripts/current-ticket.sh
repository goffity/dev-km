#!/usr/bin/env bash
# current-ticket.sh — resolve the ticket this session is working on.
#
# Replaces reading ISSUE from docs/current.md (a single shared file that
# parallel sessions overwrite). Never guesses:
#   1. explicit argument  e.g. RUAYS-1741, ruays-1741, #123, "done RUAYS-1741"
#      - status words (done|pending|blocked|completed|working) are ignored
#      - argument given but no / several tickets in it -> exit 2 (ask the user)
#        (it does NOT fall back to the branch — the user named something else)
#   2. current git branch  e.g. fix/RUAYS-1741-slug -> RUAYS-1741
#                               feat/123-slug       -> #123
#   3. nothing -> exit 1 (ask the user)
#
# Jira keys only match the configured project prefixes, so UTF-8, HTTP-2,
# SHA-256 or dates are never mistaken for tickets.
#   DEVKM_TICKET_PREFIX  ERE alternation of Jira project keys (default: RUAYS)
#
# Usage:  current-ticket.sh [--hint] [arg...] [--dir <repo>]
#   --hint  argument is free text: if it has no ticket-like token, fall back to the branch
#           (a ticket-like token that is ambiguous still exits 2)
# Output: one line — RUAYS-1741 (Jira) or #123 (GitHub issue)
# Exit:   0 found · 1 nothing to go on · 2 argument given but ambiguous/unparseable
set -euo pipefail

PREFIX="${DEVKM_TICKET_PREFIX:-RUAYS}"
ARGS="" DIR="." HINT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="${2:?--dir needs a path}"; shift 2 ;;
    --hint) HINT=1; shift ;;
    *) ARGS="$ARGS $1"; shift ;;
  esac
done

# Jira keys in text: bounded on both sides, case-insensitive, upper-cased, unique.
jira_keys() {
  # lookarounds don't consume separators, so "RUAYS-1 RUAYS-2" yields both keys
  printf '%s\n' "$1" \
    | PREFIX="$PREFIX" perl -nle 'print uc $1 while /(?<![A-Za-z0-9])((?:$ENV{PREFIX})-\d+)(?!\d)/gi' \
    | sort -u || true
}

# 1) explicit argument
ARGS=$(printf '%s' "$ARGS" | sed -E 's/(^|[[:space:]])(done|pending|blocked|completed|working)([[:space:]]|$)/ /Ig; s/^[[:space:]]+//; s/[[:space:]]+$//')
set -f   # no glob expansion of user text below
if [ -n "$ARGS" ]; then
  keys=$(jira_keys "$ARGS")
  nums=$(printf '%s\n' $ARGS | grep -E '^#?[0-9]{1,6}$' | tr -d '#' | sort -u || true)
  count=$( { [ -n "$keys" ] && printf '%s\n' "$keys"; [ -n "$nums" ] && printf '#%s\n' $nums; } | grep -c . || true)
  if [ "$count" -eq 1 ]; then
    if [ -n "$keys" ]; then echo "$keys"; else echo "#$nums"; fi
    exit 0
  fi
  # --hint: the argument is free text (e.g. /commit "split into two"); if it
  # contains nothing ticket-like at all, resolve from the branch instead.
  if [ "$HINT" = 1 ] && [ "$count" -eq 0 ]; then
    :
  else
    echo "current-ticket: cannot resolve one ticket from argument '$ARGS' — ask the user" >&2
    exit 2
  fi
fi
set +f

# 2) branch name
BR=$(git -C "$DIR" branch --show-current 2>/dev/null || true)
if [ -n "$BR" ]; then
  keys=$(jira_keys "$BR")
  if [ -n "$keys" ]; then
    [ "$(printf '%s\n' "$keys" | grep -c .)" -eq 1 ] && { echo "$keys"; exit 0; }
    echo "current-ticket: several tickets in branch '$BR' — ask the user" >&2
    exit 2
  fi
  # <type>/<issue-number>-slug (GitHub convention from /focus); reject dates like 2026-11-24
  n=$(printf '%s' "$BR" \
      | sed -nE 's#^(feat|fix|chore|docs|refactor|test|perf|hotfix)/([0-9]{1,5})-.*$#\2#p')
  if [ -n "$n" ] && ! printf '%s' "$BR" | grep -qE '/[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
    echo "#$n"; exit 0
  fi
fi

exit 1
