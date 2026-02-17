---
name: td
description: Creates post-task retrospectives with Before/After context and session documentation.
argument-hint: "[done|pending|blocked]"
---

# Post-Task Review & Retrospective

สร้าง retrospective พร้อม Before/After context และบันทึก session

## Usage

```
/td           # ถามว่างานเสร็จหรือยัง
/td done      # งานเสร็จแล้ว
/td pending   # ยังไม่เสร็จ รอทำต่อ
/td blocked   # ติดปัญหา
```

## Output

`$PROJECT_ROOT/docs/retrospective/YYYY-MM/retrospective_YYYY-MM-DD_hhmmss.md`

## Flow

```
/td → Determine Status → Auto-capture → Gather Info → Comment Issue → Create Retrospective → Update Focus → Commit Docs → Confirm
```

**Note:** สำหรับ tests, build, code review และสร้าง PR ให้ใช้ `/pr` ก่อนรัน `/td`

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

### Step 2: Auto-capture Git Context

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

### Step 3: Gather Session Info from User

ใช้ AskUserQuestion เพื่อรวบรวมข้อมูล:

1. **Tasks Done**: รายละเอียดงานที่ทำไป
2. **Test Status**: ผ่าน/ไม่ผ่าน (หรือใช้ `/pr` แล้วหรือยัง)
3. **Test Details**: รายละเอียดการทดสอบ
4. **Errors**: ข้อผิดพลาด (ถ้ามี)
5. **Additional Notes**: ข้อมูลเพิ่มเติม

### Step 4: Add Comment to Issue

**อ่าน issue number จาก `docs/current.md`:**

```bash
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
echo "Issue: #$ISSUE"
```

**Auto-assign issue (ensure user is assigned):**

```bash
gh issue edit "$ISSUE" --add-assignee @me 2>/dev/null || true
```

**เพิ่ม comment ใน issue:**

```bash
export TZ='Asia/Bangkok'

gh issue comment $ISSUE --body "$(cat <<EOF
## Session Summary

### Tasks Done

[user input - รายละเอียดงานที่ทำ]

### Test Results

| Test | Status |
|------|--------|
| Acceptance Criteria | [user input] |

### Test Details

[user input - รายละเอียดการทดสอบ]

### Errors (if any)

[user input - ข้อผิดพลาด หรือ "None"]

### Additional Notes

[user input - ข้อมูลเพิ่มเติม]

---

*Session: $(date '+%Y-%m-%d %H:%M')*
EOF
)"
```

### Step 5: Create Retrospective File

สร้างไฟล์ `docs/retrospective/YYYY-MM/retrospective_YYYY-MM-DD_hhmmss.md`

(ใช้ template ด้านล่าง)

### Step 6: Update Focus & Activity Log

**Update `docs/current.md`:**

```bash
export TZ='Asia/Bangkok'

cat > docs/current.md << EOF
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

### Step 7: Check PR Status & Commit Docs

For the full PR status checking and commit workflow, see `pr-commit-workflow.md`.

### Step 8: Check Documentation Updates

**ตรวจสอบว่าต้อง update เอกสารหรือไม่:**

| File | Check When |
|------|------------|
| `README.md` | เพิ่ม feature ใหม่, เปลี่ยน API, เปลี่ยน structure |
| `SETUP.md` | เปลี่ยนขั้นตอนการติดตั้ง |
| `SKILL.md` | เปลี่ยน skill definition |
| `CLAUDE.md` | เปลี่ยน rules หรือ conventions |
| `assets/commands/*.md` | เปลี่ยน command behavior |

**ถ้าพบว่าต้อง update:**

```markdown
Documentation Check

การเปลี่ยนแปลงนี้อาจต้อง update เอกสาร:

| File | Reason |
|------|--------|
| `README.md` | [reason] |

ต้องการให้ update เอกสารเลยไหม?
```

### Step 9: Confirm & Remind

```markdown
## Session Complete

### Summary
- Issue: #[issue-number] - Comment added
- Retrospective: docs/retrospective/[path]

### Next Steps
1. ใช้ `/pr` เพื่อรัน tests, build, review และสร้าง PR
2. รอ reviewer approve PR
3. แก้ไขตาม feedback (ถ้ามี)
4. ใช้ `/focus` เพื่อเริ่มงานใหม่
```

## Template (Retrospective)

```markdown
---
date: YYYY-MM-DDTHH:MM:SS+07:00
type: feature|bugfix|refactor|decision|discovery|config|docs
status: completed|pending|blocked
tags: [tag1, tag2]
branch: branch-name
issue: "#123"
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
| Acceptance Criteria | pass/fail | |

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

- [ ] Acceptance criteria met
- [ ] Documentation updated (if needed)
- [ ] Used `/pr` for tests, build, review and PR creation
```

## Workflow Integration

```
/focus  -->  Work  -->  /commit  -->  /pr  -->  /td
  |                        |          |         |
Create                  Atomic     Tests/     Session
Issue                   Commits    Build/     Summary
                                   Review/
                                   PR
```

## Related Commands

| Command | Purpose |
|---------|---------|
| `/focus` | ตั้ง focus และสร้าง issue |
| `/commit` | Atomic commits |
| `/pr` | รัน tests, build, review และสร้าง PR |
| `/td` | สร้าง retrospective (คุณอยู่ที่นี่) |
| `/recap` | ดู context |
| `/mem` | บันทึก knowledge |
