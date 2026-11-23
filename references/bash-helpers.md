# Common Bash Helpers

Shared snippets used across multiple skills. Reference this file instead of duplicating inline.

## Language Detection

Language is a **project setting**, not session state — `docs/current.md` is no longer read.

1. The project's `CLAUDE.md` / user instructions (e.g. kol: "Respond in Thai") → follow it
2. else env `DEVKM_LANG` (`th` | `en`)
3. else `en`

```bash
LANG_SETTING="${DEVKM_LANG:-en}"   # only when CLAUDE.md says nothing about language
```

If the language is Thai, translate user-visible output per `references/language-guide.md`.

**Always English (regardless of language setting):**
- Commit messages (conventional commits format)
- Branch names
- YAML frontmatter keys
- File names and slugs
- Mermaid diagram labels
- Code metadata comments (Title, Tags)

## Timezone

```bash
export TZ='Asia/Bangkok'
```

Use before any `date` command or timestamp generation:

```bash
export TZ='Asia/Bangkok'
date '+%Y-%m-%d %H:%M'           # 2026-03-03 14:30
date '+%Y-%m-%d %H:%M:%S'        # 2026-03-03 14:30:00
date '+%H.%M'                    # 14.30 (for file names)
```

## Focus Context (which ticket is this session on?)

`docs/current.md` is **retired as a source of truth** — it is one shared file that parallel sessions overwrite
(→ wrong ticket on /pr, /td comments). Resolve per session instead:

```bash
# 1) explicit argument  2) current branch name  3) ask the user — never guess
if ISSUE=$(~/.claude/skills/dev-km/scripts/current-ticket.sh "$ARGUMENTS"); then
  echo "ticket: $ISSUE"   # + tracker lookup here
else
  echo "STOP: ask the user which ticket (exit 1 = none found, 2 = argument ambiguous)"
fi
```

Helper contract (`scripts/current-ticket.sh`):

| Exit | Meaning | Caller |
|------|---------|--------|
| 0 | one ticket printed: `RUAYS-1234` (Jira) or `#123` (GitHub) | continue |
| 1 | no argument and nothing in the branch name | **stop and ask the user** |
| 2 | argument given but none / several tickets in it (no branch fallback), or several keys in the branch | **stop and ask the user** |

- Jira keys match only `DEVKM_TICKET_PREFIX` — an ERE alternation of project keys (default `RUAYS`, case-insensitive; e.g. `export DEVKM_TICKET_PREFIX='RUAYS|OPS'`). Status words (`done`, `pending`, `blocked`, `completed`, `working`) in the argument are ignored.
- GitHub issues resolve only from a bare `#123` / `123` argument or a `<type>/<n>-slug` branch (e.g. `feat/123-dark-mode`).
- Never pipe the helper (`| tr -d '#'`) — that hides the exit code. Strip `#` with `${ISSUE#\#}` inside the `then` branch.
- **Bash variables do not persist between tool calls.** Resolve once (Step 0), then write the confirmed ticket literally (e.g. `RUAYS-1741`, or `123` for GitHub) into every later snippet — do not re-resolve and do not rely on `$ISSUE`.
- `RUAYS-1234` style → Jira: title/status from `jira-client.sh get "$ISSUE"` (source of truth for TASK/STATE)
- `#123` style → GitHub: `gh issue view "${ISSUE#\#}" --json title,state`
- Context/notes for the ticket → kb working note, Jira keys only, bounded glob `kb/00-inbox/*"$KEY"[!0-9]*.md` (`RUAYS-12` must not match `RUAYS-123`). Guard any `rm`/`mv`/`cat` on kb paths with `case "$KEY" in RUAYS-[0-9]*) ;; *) exit 1;; esac`.
- Do **not** write `docs/current.md`. `docs/logs/activity.log` is unchanged for now.

## Date Paths

```bash
export TZ='Asia/Bangkok'
DATE_PATH=$(date '+%Y-%m/%d')          # 2026-03/03 (for learnings)
RETRO_DIR=$(date '+%Y-%m')             # 2026-03 (for retrospective)
TIMESTAMP=$(date '+%H.%M')             # 14.30 (for file prefix)
RETRO_TS=$(date '+%Y-%m-%d_%H%M%S')   # 2026-03-03_143000 (for retrospective files)
```
