---
description: Post-task review and retrospective with auto-capture and session memory
---

# Post-Task Review & Retrospective

สร้าง retrospective พร้อม Before/After context, ทดสอบ, review code, และสร้าง PR

## Usage

```
/td           # ถามว่างานเสร็จหรือยัง
/td done      # งานเสร็จแล้ว
/td pending   # ยังไม่เสร็จ รอทำต่อ
/td blocked   # ติดปัญหา
```

## Output

`$PROJECT_ROOT/docs/retrospective/YYYY-MM/retrospective_YYYY-MM-DD_hhmmss.md`

## Instructions

### Step 0: Read Current Focus

```bash
export TZ='Asia/Bangkok'
echo "=== Current Focus ==="
cat docs/current.md
```

เก็บค่า TASK และ ISSUE ไว้ใช้ใน steps ถัดไป

### Step 1: Determine Completion Status

**ถ้าไม่มี argument (`/td`):**

```
งานเสร็จหรือยัง?

1. เสร็จแล้ว (done)      → STATE = completed
2. ยังไม่เสร็จ (pending)  → STATE = pending
3. ติดปัญหา (blocked)    → STATE = blocked
```

**ถ้ามี argument:**
- `/td done` → STATE = completed
- `/td pending` → STATE = pending
- `/td blocked` → STATE = blocked

### Step 2: Run Tests (CRITICAL)

**ต้องรัน tests ก่อน push:**

```bash
echo "=== Running Tests ==="
make test
```

- ถ้า tests fail → แจ้ง user และหยุด ให้แก้ไขก่อน
- ถ้า tests pass → ดำเนินการต่อ

### Step 3: Run Build (CRITICAL)

**ต้อง build สำเร็จก่อน push:**

```bash
echo "=== Building ==="
make build
```

- ถ้า build fail → แจ้ง user และหยุด ให้แก้ไขก่อน
- ถ้า build pass → ดำเนินการต่อ

### Step 4: Code Review (CRITICAL)

**ใช้ Task tool สร้าง code-review subagent:**

```
ใช้ Task tool กับ subagent_type="general-purpose" เพื่อ review code:

Prompt:
"Review the code changes in this branch. Check for:
1. Code quality and best practices
2. Potential bugs or issues
3. Security vulnerabilities
4. Performance concerns
5. Test coverage

Provide a summary of findings with severity levels (critical/warning/info)."
```

**ถ้ามี critical issues:**
- แจ้ง user และหยุด ให้แก้ไขก่อน

**ถ้าไม่มี critical issues:**
- ดำเนินการต่อ

### Step 5: Auto-capture Git Context

```bash
export TZ='Asia/Bangkok'
echo "Date: $(date '+%Y-%m-%d')"
echo "Time: $(date '+%H:%M:%S')"
echo "Branch: $(git branch --show-current)"

echo "=== Changed Files ==="
git diff --name-only HEAD

echo "=== Staged Files ==="
git diff --cached --name-only

echo "=== Recent Commits (last 4 hours) ==="
git log --oneline -10 --since="4 hours ago"

echo "=== Status ==="
git status --short
```

### Step 6: Gather Test Results from User

ใช้ AskUserQuestion เพื่อรวบรวมข้อมูล:

1. **Tasks Done**: รายละเอียดงานที่ทำไป
2. **Test Status**: ผ่าน/ไม่ผ่าน
3. **Test Details**: รายละเอียดการทดสอบ
4. **Errors**: ข้อผิดพลาด (ถ้ามี)
5. **Additional Notes**: ข้อมูลเพิ่มเติม

### Step 7: Add Comment to Issue

**อ่าน issue number จาก `docs/current.md`:**

```bash
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
echo "Issue: #$ISSUE"
```

**เพิ่ม comment ใน issue:**

```bash
export TZ='Asia/Bangkok'

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Work Completed

### Tasks Done

[user input - รายละเอียดงานที่ทำ]

### Test Results

| Test | Status |
|------|--------|
| Unit Tests (`make test`) | ✅ Passed |
| Build (`make build`) | ✅ Passed |
| Code Review | ✅ Passed |
| Acceptance Criteria | [user input] |

### Test Details

[user input - รายละเอียดการทดสอบ]

### Errors (if any)

[user input - ข้อผิดพลาด หรือ "None"]

### Additional Notes

[user input - ข้อมูลเพิ่มเติม]

---

*Completed: $(date '+%Y-%m-%d %H:%M')*
EOF
)"
```

### Step 8: Create Retrospective File

สร้างไฟล์ `docs/retrospective/YYYY-MM/retrospective_YYYY-MM-DD_hhmmss.md`

(ใช้ template เดิม)

### Step 9: Update Focus & Activity Log

**Update `docs/current.md`:**

```bash
export TZ='Asia/Bangkok'

# For completed
cat > docs/current.md << 'EOF'
STATE: completed
TASK: [task from original focus]
SINCE: $(date '+%Y-%m-%d %H:%M')
ISSUE: #[issue-number]
EOF
```

**Append to `docs/logs/activity.log`:**

```bash
export TZ='Asia/Bangkok'
echo "$(date '+%Y-%m-%d %H:%M') | completed | [task]" >> docs/logs/activity.log
```

### Step 10: Commit All Docs (CRITICAL)

**Commit ทุกไฟล์ใน docs/ ก่อน push:**

```bash
export TZ='Asia/Bangkok'

# Check for docs changes
echo "=== Docs Changes ==="
git status --short docs/

# Stage all docs
git add docs/

# Commit docs with retrospective reference
git commit -m "$(cat <<EOF
docs: retrospective and session update for [TASK]

- Updated docs/current.md status
- Added activity log entry
- Created retrospective: [retrospective-file-path]

Related: #[issue-number]
EOF
)"

# Verify commit
git log -1 --oneline
```

**หมายเหตุ:** ต้อง commit docs ก่อน push เสมอ เพื่อให้ retrospective และ session state ถูกบันทึกไว้ใน git

### Step 11: Push Code

**Push code ไปยัง remote:**

```bash
git push -u origin $(git branch --show-current)
```

### Step 12: Create Pull Request (CRITICAL)

**สร้าง PR เชื่อมโยงกับ issue:**

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
BRANCH=$(git branch --show-current)

gh pr create \
  --title "[type]: [descriptive title]" \
  --body "$(cat <<EOF
## Summary

[auto-generated summary from commits]

## Changes Made

$(git diff main...HEAD --name-only | sed 's/^/- /')

## Testing

| Test | Status |
|------|--------|
| Unit Tests | ✅ Passed |
| Build | ✅ Passed |
| Code Review | ✅ Passed |

### Test Details

[user input - รายละเอียดการทดสอบ]

## Related Issues

- #$ISSUE

## Additional Notes

[user input - ข้อมูลเพิ่มเติม]

Fixes #$ISSUE
EOF
)"
```

### Step 13: Confirm & Remind

```markdown
## Session Complete ✓

### Summary
- Issue: #[issue-number] - Comment added
- PR: #[pr-number] - Created and linked to issue
- Retrospective: docs/retrospective/[path]

### Test Results
- Unit Tests: ✅ Passed
- Build: ✅ Passed
- Code Review: ✅ Passed

### Important Reminders
⚠️ **ห้ามทำ:**
- ห้าม merge PR เอง - รอ reviewer approve
- ห้ามปิด issue เอง - จะปิดอัตโนมัติเมื่อ PR ถูก merge

### Next Steps
1. รอ reviewer approve PR
2. แก้ไขตาม feedback (ถ้ามี)
3. ใช้ `/focus` เพื่อเริ่มงานใหม่
```

## Pre-Push Checklist

| Check | Command | Required |
|-------|---------|----------|
| Tests | `make test` | ✅ Must pass |
| Build | `make build` | ✅ Must pass |
| Code Review | subagent | ✅ No critical issues |

## Forbidden Actions

| Action | Reason |
|--------|--------|
| ❌ Merge PR | ต้องรอ reviewer approve |
| ❌ Close Issue | จะปิดอัตโนมัติเมื่อ PR merge |
| ❌ Force Push | อันตราย ห้ามใช้ |

## Template (Retrospective)

```markdown
---
date: YYYY-MM-DDTHH:MM:SS+07:00
type: feature|bugfix|refactor|decision|discovery|config|docs
status: completed|pending|blocked
tags: [tag1, tag2]
branch: branch-name
issue: "#123"
pr: "#456"
duration: ~2h
files_changed:
  - path/to/file.go
---

# [Task Title]

## Session Metadata

| Field | Value |
|-------|-------|
| Date | YYYY-MM-DD |
| Time | HH:MM:SS (Asia/Bangkok) |
| Duration | estimated |
| Type | type |
| Status | completed/pending/blocked |
| Branch | branch |
| Issue | #123 |
| PR | #456 |

---

## Context: Before

- **Problem**: ปัญหาที่เจอ
- **Existing Behavior**: พฤติกรรมเดิม
- **Why Change**: ทำไมต้องเปลี่ยน
- **Metrics**: ตัวเลขก่อนแก้

---

## Context: After

- **Solution**: วิธีแก้
- **New Behavior**: พฤติกรรมใหม่
- **Improvements**: สิ่งที่ดีขึ้น
- **Metrics**: ตัวเลขหลังแก้

---

## Test Results

| Test | Status | Details |
|------|--------|---------|
| Unit Tests | ✅/❌ | |
| Build | ✅/❌ | |
| Code Review | ✅/❌ | |
| Acceptance Criteria | ✅/❌ | |

---

## Decisions & Rationale

| Decision | Options Considered | Chosen | Rationale |
|----------|-------------------|--------|-----------|
| | | | |

---

## Session Summary

### Task Description
อธิบาย task

### Outcome
ผลลัพธ์

---

## Technical Details

### Files Modified

| File | Changes |
|------|---------|
| `file.go` | changes |

### Recent Commits

```
# commits from auto-capture
```

---

## Honest Feedback

### What Went Well
-

### What Could Be Improved
-

---

## Lessons Learned

- Technical insights
- Process improvements

---

## Validation Checklist

- [ ] Tests pass (`make test`)
- [ ] Build succeeds (`make build`)
- [ ] Code review passed
- [ ] Acceptance criteria met
- [ ] PR created and linked to issue
- [ ] Comment added to issue
```

## Related Commands

| Command | Purpose |
|---------|---------|
| `/focus` | ตั้ง focus ใหม่ |
| `/recap` | ดู context |
| `/td` | จบ session (คุณอยู่ที่นี่) |
| `/mem` | บันทึก knowledge |
| `/commit` | Atomic commits |
