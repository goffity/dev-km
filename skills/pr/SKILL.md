---
name: pr
description: Runs tests, build, code review and creates pull requests with issue tracking.
user-invocable: true
---

# Create Pull Request

รัน tests, build, code review และสร้าง PR พร้อม update issue ทุกขั้นตอน

## Usage

```
/pr
```

## Flow

```
make test → make build → Code Review → Create PR
    ↓           ↓            ↓
  (fail)     (fail)       (fail)
    ↓           ↓            ↓
   Fix        Fix       Agent Fix
    ↓           ↓            ↓
  Retry      Retry       Re-review
```

## Instructions

### Step 0: Read Current Focus

```bash
export TZ='Asia/Bangkok'
echo "=== Current Focus ==="
cat docs/current.md

ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
TASK=$(grep "^TASK:" docs/current.md | cut -d: -f2-)
echo "Issue: #$ISSUE"
echo "Task: $TASK"
```

เก็บค่า ISSUE และ TASK ไว้ใช้ตลอด flow

### Step 1: Run Tests

**Comment issue ว่าเริ่ม test:**

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Running Tests

**Started:** $(date '+%Y-%m-%d %H:%M')
**Status:** In Progress

Running `make test`...
EOF
)"
```

**รัน tests:**

```bash
echo "=== Running Tests ==="
make test 2>&1
TEST_EXIT_CODE=$?
echo "Exit code: $TEST_EXIT_CODE"
```

**ถ้า test fail:**

1. Comment issue ว่า test fail พร้อม error message
2. แจ้ง user และหยุด ให้แก้ไข
3. เมื่อแก้เสร็จ user จะรัน `/pr` อีกครั้ง

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Tests Failed

**Time:** $(date '+%Y-%m-%d %H:%M')

### Error Output
```
[test error output]
```

### Action Required
แก้ไข test errors และรัน `/pr` อีกครั้ง
EOF
)"
```

**ถ้า test pass → ไป Step 2**

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Tests Passed

**Time:** $(date '+%Y-%m-%d %H:%M')
**Status:** All tests passed

Proceeding to build...
EOF
)"
```

### Step 2: Run Build

**รัน build:**

```bash
echo "=== Building ==="
make build 2>&1
BUILD_EXIT_CODE=$?
echo "Exit code: $BUILD_EXIT_CODE"
```

**ถ้า build fail:**

1. Comment issue ว่า build fail พร้อม error message
2. แจ้ง user และหยุด ให้แก้ไข
3. เมื่อแก้เสร็จ user จะรัน `/pr` อีกครั้ง

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Build Failed

**Time:** $(date '+%Y-%m-%d %H:%M')

### Error Output
```
[build error output]
```

### Action Required
แก้ไข build errors และรัน `/pr` อีกครั้ง
EOF
)"
```

**ถ้า build pass → ไป Step 3**

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Build Passed

**Time:** $(date '+%Y-%m-%d %H:%M')
**Status:** Build successful

Proceeding to code review...
EOF
)"
```

### Step 3: Code Review (Subagent)

**Comment issue ว่าเริ่ม code review:**

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Code Review Started

**Time:** $(date '+%Y-%m-%d %H:%M')
**Status:** Reviewing...

Running automated code review...
EOF
)"
```

**ใช้ Task tool สร้าง code-review subagent:**

```
ใช้ Task tool กับ subagent_type="general-purpose" เพื่อ review code:

Prompt:
"Review the code changes in this branch compared to main.

Check for:
1. **Code Quality**: Best practices, clean code, naming conventions
2. **Bugs**: Potential bugs, logic errors, edge cases
3. **Security**: SQL injection, XSS, command injection, secrets exposure
4. **Performance**: N+1 queries, memory leaks, inefficient algorithms
5. **Tests**: Test coverage, missing tests, test quality

For each finding, provide:
- Severity: CRITICAL / WARNING / INFO
- File and line number
- Description of the issue
- Suggested fix

Output format:
## Review Summary

### Critical Issues (must fix)
- [ ] Issue description

### Warnings (should fix)
- [ ] Issue description

### Info (nice to have)
- [ ] Issue description

### Overall Assessment
Pass / Fail with reason"
```

**ถ้า code review มี CRITICAL issues:**

1. Comment issue ว่า review fail พร้อม issues list
2. ใช้ Task tool ส่งให้ agent แก้ไข
3. หลังแก้ไข ส่งกลับไป review ใหม่ (loop จนกว่าจะผ่าน)

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Code Review Failed

**Time:** $(date '+%Y-%m-%d %H:%M')

### Critical Issues Found

[list of critical issues from review]

### Action
Sending to agent for auto-fix...
EOF
)"
```

**ใช้ Task tool ให้ agent แก้ไข:**

```
ใช้ Task tool กับ subagent_type="general-purpose" เพื่อแก้ไข:

Prompt:
"Fix the following critical issues from code review:

[list of critical issues]

For each issue:
1. Locate the file and line
2. Apply the suggested fix
3. Verify the fix is correct
4. Report what was changed

After fixing, output a summary of changes made."
```

**หลังจาก agent แก้ไข:**

1. Comment issue ว่า agent แก้ไขแล้ว
2. กลับไป Step 3 (re-review)

**ถ้า code review ผ่าน (ไม่มี CRITICAL) → ไป Step 4**

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')

gh issue comment $ISSUE --body "$(cat <<'EOF'
## Code Review Passed

**Time:** $(date '+%Y-%m-%d %H:%M')

### Summary
- Critical: 0
- Warnings: [count]
- Info: [count]

### Warnings (if any)
[list of warnings]

Proceeding to create PR...
EOF
)"
```

### Step 4: Push Code

**Push code ไปยัง remote:**

```bash
git push -u origin $(git branch --show-current)
```

### Step 5: Create Pull Request

**สร้าง PR เชื่อมโยงกับ issue:**

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
TASK=$(grep "^TASK:" docs/current.md | cut -d: -f2- | xargs)
BRANCH=$(git branch --show-current)

# Determine PR type from task or branch
TYPE="feat"
if echo "$TASK" | grep -qi "fix\|bug"; then
  TYPE="fix"
elif echo "$TASK" | grep -qi "refactor"; then
  TYPE="refactor"
elif echo "$TASK" | grep -qi "doc"; then
  TYPE="docs"
fi

# Detect base branch (prefer develop, fallback to default)
if git branch -r | grep -q "origin/develop"; then
  BASE_BRANCH="develop"
else
  BASE_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d: -f2 | xargs)
fi
echo "Base branch: $BASE_BRANCH"

gh pr create \
  --base "$BASE_BRANCH" \
  --title "$TYPE: $TASK" \
  --body "$(cat <<EOF
## Summary

$TASK

## Changes Made

$(git diff main...HEAD --name-only | sed 's/^/- /')

## Testing

| Test | Status |
|------|--------|
| Unit Tests (\`make test\`) | Passed |
| Build (\`make build\`) | Passed |
| Code Review | Passed |

## Related Issues

Fixes #$ISSUE
EOF
)"
```

**Comment issue ว่าสร้าง PR แล้ว:**

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
PR_URL=$(gh pr view --json url -q .url)

gh issue comment $ISSUE --body "$(cat <<EOF
## Pull Request Created

**Time:** $(date '+%Y-%m-%d %H:%M')
**PR:** $PR_URL

### All Checks Passed
- Tests
- Build
- Code Review

### Next Steps
- Wait for reviewer approval
- Address feedback if any
- PR will auto-close this issue when merged
EOF
)"
```

For post-PR-creation steps (auto-polling, confirmation, flow diagram), see [pr-post-create.md](pr-post-create.md).

## Related Commands

| Command | Purpose |
|---------|---------|
| `/focus` | ตั้ง focus และสร้าง issue |
| `/td` | สร้าง retrospective |
| `/pr` | รัน tests, build, review และสร้าง PR (คุณอยู่ที่นี่) |
| `/pr-review` | ตอบ PR feedback |
| `/commit` | Atomic commits |
