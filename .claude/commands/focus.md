---
description: Set current focus - update docs/current.md and log to activity.log
---

# Set Focus

ตั้ง focus สำหรับงานใหม่ พร้อมสร้าง GitHub issue ด้วย format มาตรฐาน

## Usage

```
/focus [task description]
```

## Instructions

### Step 1: Check Current State

```bash
export TZ='Asia/Bangkok'
echo "=== Current Focus ==="
cat docs/current.md

echo ""
echo "=== Git Status ==="
echo "Branch: $(git branch --show-current)"
git status --short
```

### Step 2: Handle Existing Focus

ถ้า `STATE` ไม่ใช่ `ready` หรือ `completed`:

```
⚠️  มี focus อยู่แล้ว:
TASK: [current task]
STATE: [current state]

ต้องการ:
1. ทำต่องานเดิม (keep)
2. เปลี่ยนไปทำงานใหม่ (switch) - งานเดิมจะถูก mark เป็น pending
```

ถ้า user เลือก switch → เพิ่ม pending entry ใน `docs/logs/activity.log`

### Step 3: Get Task from User

ถ้าไม่มี argument:
```
งานที่จะทำคืออะไร?
```

ถ้ามี argument → ใช้เป็น task description

### Step 4: Gather Issue Details

ใช้ AskUserQuestion เพื่อรวบรวมข้อมูลสำหรับ issue:

**ถามข้อมูลต่อไปนี้:**

1. **Type**: ประเภทของงาน
   - feat (new feature)
   - fix (bug fix)
   - refactor (code restructure)
   - docs (documentation)
   - test (testing)
   - chore (maintenance)

2. **Overview**: อธิบายสั้นๆ ว่างานนี้คืออะไร

3. **Current State**: สถานะปัจจุบันเป็นอย่างไร (ปัญหาที่เจอ, behavior เดิม)

4. **Proposed Solution**: วิธีแก้ไขที่เสนอ

5. **Technical Details**:
   - Components ที่เกี่ยวข้อง
   - Implementation approach

6. **Acceptance Criteria**: เกณฑ์การทดสอบ (อย่างน้อย 3 ข้อ)
   - Specific testable criteria
   - Performance requirements (ถ้ามี)
   - UI/UX requirements (ถ้ามี)

### Step 5: Create GitHub Issue

สร้าง GitHub issue ด้วย format มาตรฐาน:

```bash
export TZ='Asia/Bangkok'

gh issue create \
  --title "[type]: [descriptive title]" \
  --label "session-log" \
  --body "$(cat <<EOF
## Overview

[user input - brief description]

## Current State

[user input - what exists now]

## Proposed Solution

[user input - what should be implemented]

## Technical Details

- **Components affected:** [user input]
- **Implementation approach:** [user input]

## Acceptance Criteria

- [ ] [user input criteria 1]
- [ ] [user input criteria 2]
- [ ] [user input criteria 3]

---

## Session Info

- **Started:** $(date '+%Y-%m-%d %H:%M')
- **Branch:** [type]/[issue-number]-[short-slug]
- **Status:** 🔄 In Progress
EOF
)"
```

เก็บ issue number ที่ได้ (เช่น `#123`) ไว้ใช้ใน Step 6

### Step 5.5: Create Feature Branch (Required)

**ข้อบังคับ:** ถ้าอยู่บน `main`, `master`, หรือ default branch ต้องสร้าง branch ใหม่เสมอ

```bash
export TZ='Asia/Bangkok'

CURRENT_BRANCH=$(git branch --show-current)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

# ถ้าไม่มี default branch ให้ใช้ main หรือ master
if [ -z "$DEFAULT_BRANCH" ]; then
  if git show-ref --verify --quiet refs/heads/main; then
    DEFAULT_BRANCH="main"
  else
    DEFAULT_BRANCH="master"
  fi
fi

# ตรวจสอบว่าอยู่บน main/master/default branch หรือไม่
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ] || [ "$CURRENT_BRANCH" = "$DEFAULT_BRANCH" ]; then
  echo "⚠️  Currently on $CURRENT_BRANCH - creating feature branch..."

  # สร้าง branch name จาก type และ issue number
  # Format: [type]/[issue-number]-[short-description]
  # Example: feat/123-add-user-auth, fix/45-login-timeout

  git checkout -b "[type]/[issue-number]-[short-slug]"
  echo "✓ Created and switched to branch: [type]/[issue-number]-[short-slug]"
else
  echo "✓ Already on feature branch: $CURRENT_BRANCH"
fi
```

**Branch Naming Convention:**

| Type | Branch Prefix | Example |
|------|---------------|---------|
| feat | `feat/` | `feat/123-add-user-auth` |
| fix | `fix/` | `fix/45-login-timeout` |
| refactor | `refactor/` | `refactor/67-simplify-auth` |
| docs | `docs/` | `docs/89-update-readme` |
| test | `test/` | `test/12-add-unit-tests` |
| chore | `chore/` | `chore/34-update-deps` |

**Short slug rules:**
- ใช้ lowercase
- แทนที่ space ด้วย `-`
- ตัดคำที่ไม่จำเป็นออก (a, an, the)
- จำกัดความยาวไม่เกิน 30 ตัวอักษร

### Step 6: Update Files

**Update `docs/current.md`:**

```bash
export TZ='Asia/Bangkok'
cat > docs/current.md << EOF
STATE: working
TASK: [task description from user]
SINCE: $(date '+%Y-%m-%d %H:%M')
ISSUE: #[issue-number]
BRANCH: [type]/[issue-number]-[short-slug]
EOF
```

**Append to `docs/logs/activity.log`:**

```bash
export TZ='Asia/Bangkok'
echo "$(date '+%Y-%m-%d %H:%M') | working | [task description] (#[issue-number])" >> docs/logs/activity.log
```

### Step 7: Confirm

```markdown
## Focus Set ✓

**Issue Created:** #[issue-number]
**Title:** [type]: [title]
**Branch:** [type]/[issue-number]-[short-slug]

STATE: working
TASK: [task]
SINCE: [timestamp]

### Acceptance Criteria
- [ ] [criteria 1]
- [ ] [criteria 2]
- [ ] [criteria 3]

พร้อมเริ่มงาน! ใช้ `/td` เมื่อจบ session
```

## Issue Title Format

| Type | Prefix | Example |
|------|--------|---------|
| feature | `feat:` | `feat: Add user authentication` |
| bug fix | `fix:` | `fix: Resolve login timeout` |
| refactor | `refactor:` | `refactor: Simplify auth middleware` |
| docs | `docs:` | `docs: Update API documentation` |
| test | `test:` | `test: Add unit tests for auth` |
| chore | `chore:` | `chore: Update dependencies` |

## Examples

```bash
# With argument
/focus Implement user authentication

# Without argument (will ask)
/focus
```

## States Reference

| State | Meaning | Next Action |
|-------|---------|-------------|
| `ready` | ว่าง รอ task | `/focus` เพื่อตั้งงาน |
| `working` | กำลังทำ | `/td` เมื่อจบ |
| `pending` | รอทำต่อ | `/recap` แล้ว `/focus` |
| `blocked` | ติดปัญหา | แก้ปัญหาก่อน |
| `completed` | เสร็จแล้ว | `/focus` งานใหม่ |
