---
description: Fresh start context - get caught up at the start of a new session
---

# Session Recap

เริ่ม session ใหม่โดยโหลด context ที่จำเป็น

## Usage

```
/recap             # ticket resolve จากชื่อ branch
/recap RUAYS-1234  # ระบุ ticket เอง (หรือ #123 สำหรับ GitHub issue)
```

## Instructions

> `docs/current.md` เลิกใช้แล้ว (shared file ที่ session อื่นเขียนทับ) — ticket ของ session resolve จาก argument → ชื่อ branch, status มาจาก Jira/GitHub

### Step 1: Resolve Ticket + Tracker Status

```bash
export TZ='Asia/Bangkok'
if ISSUE=$(~/.claude/skills/dev-km/scripts/current-ticket.sh "$ARGUMENTS"); then
  echo "ticket: $ISSUE"
  case "$ISSUE" in
    \#*) gh issue view "${ISSUE#\#}" --json title,state,url ;;
    *)   ./scripts/jira-client.sh get "$ISSUE" ;;   # summary/status
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

## Output Format

```markdown
## Session Recap

### Current Focus
TICKET: [ISSUE หรือ "unknown — ถาม user"]
TASK: [summary/title จาก Jira/GitHub]
STATUS: [status จาก Jira/GitHub]
BRANCH: [branch] ([ตรง/ไม่ตรงกับ ticket])

### Working Note
[สรุปจาก kb/00-inbox/*<ISSUE>*.md หรือ "ไม่มี"]

### Recent Activity
[last 5 entries]

### Git Status
Branch: [branch]
Changes: [count]

### Action Required
[ทำต่อ / ถามเลือก ticket / แนะนำ /focus]
```

## Status Reference

| Status (Jira/GitHub) | Action |
|----------------------|--------|
| ไม่รู้ ticket | แสดง candidates → ถาม user หรือแนะนำ `/focus` |
| To Do / open | แนะนำ `/focus` (เลือก Jira existing) เพื่อ transition + สร้าง branch |
| In Progress | ทำต่อ — แสดง working note |
| Blocked | ถามสถานะ/สิ่งที่ติด |
| Done / closed | งานเสร็จแล้ว → แนะนำ `/focus` |

## Related Commands

| Command | Purpose |
|---------|---------|
| `/focus` | ตั้ง focus ใหม่ |
| `/recap` | ดู context (คุณอยู่ที่นี่) |
| `/td` | จบ session + retrospective |
| `/mem` | บันทึก knowledge |
