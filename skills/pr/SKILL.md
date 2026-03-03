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

### Language Setting

> Check `LANGUAGE` in `docs/current.md`. If `th`, translate output per `references/language-guide.md`. See `references/bash-helpers.md` for detection snippet.

### Issue Comment Pattern

ทุก step จะ comment ไปที่ issue ตาม pattern นี้ (ดู templates เต็มที่ [issue-comments.md](issue-comments.md)):

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
gh issue comment $ISSUE --body "[template from issue-comments.md]"
```

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

1. Comment issue: "Running Tests"
2. รัน `make test`
3. **ถ้า fail:** Comment "Tests Failed" พร้อม error → แจ้ง user หยุด → รัน `/pr` อีกครั้ง
4. **ถ้า pass:** Comment "Tests Passed" → ไป Step 2

```bash
echo "=== Running Tests ==="
make test 2>&1
TEST_EXIT_CODE=$?
echo "Exit code: $TEST_EXIT_CODE"
```

### Step 2: Run Build

1. รัน `make build`
2. **ถ้า fail:** Comment "Build Failed" พร้อม error → แจ้ง user หยุด → รัน `/pr` อีกครั้ง
3. **ถ้า pass:** Comment "Build Passed" → ไป Step 3

```bash
echo "=== Building ==="
make build 2>&1
BUILD_EXIT_CODE=$?
echo "Exit code: $BUILD_EXIT_CODE"
```

### Step 3: Code Review (Subagent)

1. Comment issue: "Code Review Started"
2. ใช้ Agent tool กับ subagent_type="general-purpose" เพื่อ review:

```
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

3. **ถ้ามี CRITICAL:** Comment "Code Review Failed" → Agent auto-fix → re-review (loop)
4. **ถ้า pass:** Comment "Code Review Passed" → ไป Step 4

**Agent auto-fix prompt:**

```
"Fix the following critical issues from code review:

[list of critical issues]

For each issue:
1. Locate the file and line
2. Apply the suggested fix
3. Verify the fix is correct
4. Report what was changed"
```

### Step 4: Push Code

```bash
git push -u origin $(git branch --show-current)
```

### Step 5: Create Pull Request

```bash
export TZ='Asia/Bangkok'
ISSUE=$(grep "^ISSUE:" docs/current.md | cut -d: -f2 | tr -d ' #')
TASK=$(grep "^TASK:" docs/current.md | cut -d: -f2- | xargs)

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

Comment issue: "Pull Request Created" พร้อม PR URL (see [issue-comments.md](issue-comments.md))

For post-PR-creation steps (auto-polling, confirmation, flow diagram), see [pr-post-create.md](pr-post-create.md).

## Related Commands

| Command | Purpose |
|---------|---------|
| `/focus` | ตั้ง focus และสร้าง issue |
| `/td` | สร้าง retrospective |
| `/pr` | รัน tests, build, review และสร้าง PR (คุณอยู่ที่นี่) |
| `/pr-review` | ตอบ PR feedback |
| `/commit` | Atomic commits |
