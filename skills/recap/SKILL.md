---
name: recap
description: Loads session context and pending work status for fresh session starts.
user-invocable: true
---

# Session Recap

เริ่ม session ใหม่โดยโหลด context ที่จำเป็น

## Usage

```
/recap                 # resolve ticket from the current branch
/recap RUAYS-1234      # or pass the ticket explicitly (Jira key or #123)
```

> `docs/current.md` is no longer read or written — the ticket is resolved per session
> (argument → branch name → ask). See `references/bash-helpers.md` → Focus Context.

## Instructions

### Language Setting

> **Language:** follow the project's CLAUDE.md (fallback `DEVKM_LANG`, then `en`) — see `references/bash-helpers.md` → Language Detection. If Thai, translate output per `references/language-guide.md`. Display current LANGUAGE as part of context.

### Step 1: Resolve Ticket + Tracker Status

```bash
export TZ='Asia/Bangkok'
if ISSUE=$(~/.claude/skills/dev-km/scripts/current-ticket.sh "$ARGUMENTS"); then
  echo "ticket: $ISSUE"
  case "$ISSUE" in
    \#*) gh issue view "${ISSUE#\#}" --json title,state,url ;;
    *)   ~/.claude/skills/dev-km/scripts/jira-client.sh get "$ISSUE" ;;   # summary/status
  esac
else
  echo "STOP: ask the user which ticket (exit 1 = none found, 2 = argument ambiguous)"
  echo "=== Branches with tickets ==="
  git branch --list '*RUAYS-*' --sort=-committerdate | head -10
  echo "=== kb working notes ==="
  ls -t kb/00-inbox/*RUAYS-*.md 2>/dev/null | head -10
fi
```

**exit ≠ 0 → หยุด** แสดง candidate ด้านบนแล้วใช้ AskUserQuestion ให้ user เลือก ticket (หรือแนะนำ `/focus` ถ้าเป็นงานใหม่) — ห้ามเดา, ห้ามทำ Step 2–3 ด้วย ticket ว่าง

> **Bash variables ไม่ persist ข้าม tool call** — Step 2–3 ให้เขียน ticket ที่ยืนยันแล้วแบบ literal (เช่น `RUAYS-1741` หรือ `123`) ลงใน snippet — ห้าม resolve ซ้ำ

### Step 2: Branch Check (ticket confirmed only)

```bash
KEY="<confirmed ticket from Step 1, e.g. RUAYS-1741 or 123>"
[ -n "$KEY" ] || { echo "no ticket — skip"; exit 1; }
CURRENT_BRANCH=$(git branch --show-current)
echo "Branch: $CURRENT_BRANCH"
if echo "$CURRENT_BRANCH" | grep -qE "${KEY}([^0-9]|$)"; then
  echo "branch matches $KEY"
else
  echo "branch does not match $KEY — candidate branches:"
  git branch --list | grep -E "${KEY}([^0-9]|$)"
fi
```

- ถ้า current branch มี ticket อยู่แล้ว → OK
- ถ้าไม่มี แต่มี branch อื่นที่มี ticket → ถาม user ว่าจะ switch ไหม (`git stash push -m "<name>"` ก่อน `git checkout` ถ้ามี uncommitted changes)
- ถ้าไม่มี branch เลย → แนะนำ `/focus` เพื่อสร้าง branch

### Step 3: Context

kb working note — เฉพาะ Jira key (เลข GitHub ไม่ใช้กับ kb glob):

```bash
KEY="<confirmed Jira key from Step 1, e.g. RUAYS-1741>"
case "$KEY" in RUAYS-[0-9]*) ;; *) echo "no Jira ticket — skip kb note"; exit 0;; esac
for f in kb/00-inbox/*"$KEY"[!0-9]*.md; do [ -f "$f" ] && { echo "=== $f ==="; cat "$f"; }; done
```

```bash
export TZ='Asia/Bangkok'
echo "=== Recent Activity (last 5) ==="
tail -5 docs/logs/activity.log

echo ""
echo "=== Git Status ==="
echo "Date: $(date '+%Y-%m-%d %H:%M')"
git status -sb
echo ""
echo "=== Recent Commits ==="
git log --oneline -5
```

### Step 4: Check WIP.md (Optional)

ถ้ามี WIP.md (งานที่พักไว้จากเวอร์ชันก่อน) แสดง:

```bash
if [ -f docs/WIP.md ]; then
  echo "=== งานที่พักไว้ ==="
  grep "^## " docs/WIP.md | head -5
fi
```

## Output Format

```markdown
## Session Recap

### Current Focus
ISSUE: [ticket]
TITLE: [summary from tracker]
STATUS: [status from tracker]
BRANCH: [branch] ([matches ticket | mismatch → expected ...])
LANGUAGE: [th|en]

### Working Note
[kb/00-inbox note summary, if any]

### Recent Activity
[last 5 entries]

### Git Status
[git status -sb]

### Action Required
[continue / switch branch / ถามเลือก ticket / แนะนำ /focus]
```

## Related Commands

| Command | Purpose |
|---------|---------|
| `/focus` | ตั้ง focus ใหม่ |
| `/recap` | ดู context (คุณอยู่ที่นี่) |
| `/td` | จบ session + retrospective |
| `/mem` | บันทึก knowledge |
