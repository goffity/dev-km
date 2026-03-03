# Common Bash Helpers

Shared snippets used across multiple skills. Reference this file instead of duplicating inline.

## Language Detection

```bash
LANG=$(grep "^LANGUAGE:" docs/current.md 2>/dev/null | cut -d: -f2 | xargs)
# Returns: "en" (default) or "th"
# If empty/missing, treat as "en"
```

If `LANG` is `th`, translate user-visible output per `references/language-guide.md`.

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

## Focus Context

Read current task context from `docs/current.md`:

```bash
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
TASK=$(grep "^TASK:" docs/current.md | cut -d: -f2- | xargs)
BRANCH=$(grep "^BRANCH:" docs/current.md | cut -d: -f2- | xargs)
STATE=$(grep "^STATE:" docs/current.md | cut -d: -f2- | xargs)
```

## Date Paths

```bash
export TZ='Asia/Bangkok'
DATE_PATH=$(date '+%Y-%m/%d')          # 2026-03/03 (for learnings)
RETRO_DIR=$(date '+%Y-%m')             # 2026-03 (for retrospective)
TIMESTAMP=$(date '+%H.%M')             # 14.30 (for file prefix)
RETRO_TS=$(date '+%Y-%m-%d_%H%M%S')   # 2026-03-03_143000 (for retrospective files)
```
