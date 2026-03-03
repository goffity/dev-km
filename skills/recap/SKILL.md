---
name: recap
description: Loads session context and pending work status for fresh session starts.
user-invocable: true
---

# Session Recap

เริ่ม session ใหม่โดยโหลด context ที่จำเป็น

## Usage

```
/recap
```

## Instructions

### Language Setting

> Check `LANGUAGE` in `docs/current.md`. If `th`, translate output per `references/language-guide.md`. Display current LANGUAGE as part of context. See `references/bash-helpers.md` for detection snippet.

### Step 1: Load Current Focus

```bash
export TZ='Asia/Bangkok'
echo "=== Current Focus ==="
cat docs/current.md
```

### Step 2: Show Context

```bash
export TZ='Asia/Bangkok'
echo "=== Recent Activity (last 5) ==="
tail -5 docs/logs/activity.log

echo ""
echo "=== Git Status ==="
echo "Date: $(date '+%Y-%m-%d %H:%M')"
echo "Branch: $(git branch --show-current)"
git status --short
echo ""
echo "=== Recent Commits ==="
git log --oneline -5
```

### Step 3: Check for Pending Work

**ถ้า STATE = `working` หรือ `pending`:**

ใช้ AskUserQuestion เพื่อถามผู้ใช้:

```
งานค้างอยู่: [TASK from current.md]
ตั้งแต่: [SINCE from current.md]

ต้องการทำอะไร?
```

Options:
1. **ทำต่องานเดิม** - Continue working on current task
2. **เริ่มงานใหม่** - Start new task (old task moves to WIP.md)

### Step 4: Handle User Choice

**ถ้าเลือก "ทำต่องานเดิม":**

```bash
export TZ='Asia/Bangkok'

EXPECTED_BRANCH=$(grep "^BRANCH:" docs/current.md | cut -d: -f2- | xargs)
CURRENT_BRANCH=$(git branch --show-current)

if [ -n "$EXPECTED_BRANCH" ] && [ "$EXPECTED_BRANCH" != "-" ] && [ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]; then
  echo "Switching to branch: $EXPECTED_BRANCH"
  git checkout "$EXPECTED_BRANCH"
fi

sed -i '' 's/STATE: pending/STATE: working/' docs/current.md
echo "$(date '+%Y-%m-%d %H:%M') | working | [TASK] (resumed)" >> docs/logs/activity.log
```

แสดง:
```
พร้อมทำต่อ: [TASK]
Branch: [BRANCH]
```

**ถ้าเลือก "เริ่มงานใหม่":**

1. ย้ายงานเก่าไป WIP.md:

```bash
export TZ='Asia/Bangkok'

if [ ! -f docs/WIP.md ]; then
  echo "# Work In Progress" > docs/WIP.md
  echo "" >> docs/WIP.md
  echo "งานที่ยังไม่เสร็จ พักไว้ก่อน" >> docs/WIP.md
  echo "" >> docs/WIP.md
fi

TASK=$(grep "^TASK:" docs/current.md | cut -d: -f2- | xargs)
SINCE=$(grep "^SINCE:" docs/current.md | cut -d: -f2- | xargs)
BRANCH=$(grep "^BRANCH:" docs/current.md | cut -d: -f2- | xargs)
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2- | xargs)

echo "## $TASK" >> docs/WIP.md
echo "" >> docs/WIP.md
echo "- **Started:** $SINCE" >> docs/WIP.md
echo "- **Paused:** $(date '+%Y-%m-%d %H:%M')" >> docs/WIP.md
echo "- **Branch:** $BRANCH" >> docs/WIP.md
echo "- **Issue:** $ISSUE" >> docs/WIP.md
echo "- **Status:** Incomplete" >> docs/WIP.md
echo "" >> docs/WIP.md
```

2. Log activity:

```bash
export TZ='Asia/Bangkok'
echo "$(date '+%Y-%m-%d %H:%M') | pending | [TASK] (moved to WIP.md)" >> docs/logs/activity.log
```

3. Reset current.md:

```bash
export TZ='Asia/Bangkok'
cat > docs/current.md << 'EOF'
STATE: ready
TASK: -
SINCE: -
ISSUE: -
BRANCH: -
EOF
```

4. แสดง:
```
งานเก่าถูกย้ายไป docs/WIP.md แล้ว
ใช้ /focus เพื่อตั้งงานใหม่
```

**ถ้า STATE = `ready` หรือ `completed`:**

```
ไม่มีงานค้าง
ใช้ /focus เพื่อตั้งงานใหม่
```

### Step 5: Check WIP.md (Optional)

ถ้ามี WIP.md และมีงานค้างอยู่ แสดง:

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
STATE: [state]
TASK: [task]
SINCE: [since]
ISSUE: [issue]
BRANCH: [branch]

### Recent Activity
[last 5 entries]

### Git Status
Branch: [branch]
Changes: [count]

### Action Required
[ถาม continue/new หรือ แนะนำ /focus]
```

## State Reference

| STATE | Action |
|-------|--------|
| `ready` | ไม่มี focus → แนะนำ `/focus` |
| `working` | มีงานค้าง → ถาม continue/new |
| `pending` | งานถูกพักไว้ → ถาม continue/new |
| `blocked` | ติดปัญหา → ถามสถานะ |
| `completed` | งานเสร็จแล้ว → แนะนำ `/focus` |

## Related Commands

| Command | Purpose |
|---------|---------|
| `/focus` | ตั้ง focus ใหม่ |
| `/recap` | ดู context (คุณอยู่ที่นี่) |
| `/td` | จบ session + retrospective |
| `/mem` | บันทึก knowledge |
