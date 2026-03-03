---
name: pr-review
description: Reviews and responds to PR feedback from reviewers with automatic thread resolution.
argument-hint: "[pr-number]"
user-invocable: true
---

# PR Review Handler

ตรวจสอบ PR ที่ได้รับ review และจัดการ feedback อัตโนมัติ

## Usage

```
/pr-review              # ตรวจสอบ PR ของ current branch
/pr-review [pr-number]  # ตรวจสอบ PR เฉพาะเจาะจง
```

## Instructions

### Language Setting

> Check `LANGUAGE` in `docs/current.md`. If `th`, translate output per `references/language-guide.md`. See `references/bash-helpers.md` for detection snippet.

### Step 1: Find Open PRs with Reviews

```bash
# Get current branch name
BRANCH=$(git branch --show-current)

# List open PRs authored by current user
echo "=== Open PRs ==="
gh pr list --author "@me" --state open --json number,title,url,headRefName,reviews,reviewDecision

# If specific PR number provided, use that instead
# gh pr view [pr-number] --json number,title,url,headRefName,reviews,reviewDecision,comments
```

### Step 2: Check Review Status

```bash
# Get PR reviews for the branch or specified PR
gh pr view --json reviews,reviewDecision,reviewRequests

# Check if PR has been reviewed
# reviewDecision: APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, or null
```

**ถ้าไม่มี review:** แจ้งผู้ใช้ว่ายังไม่มี review และจบการทำงาน

**ถ้ามี review:** ดำเนินการต่อ Step 3

### Step 3: Display PR Details

แสดงข้อมูล PR ในรูปแบบที่อ่านง่าย:

```markdown
## PR #[number]: [title]

**URL**: [url]
**Branch**: [headRefName]
**Review Status**: [reviewDecision]

### Reviews
| Reviewer | State | Comment |
|----------|-------|---------|
| [author] | [state] | [body preview] |
```

### Step 4: Fetch and Analyze Review Comments

```bash
# Get PR comments (review comments)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --jq '.[] | {id, path, line, body, user: .user.login}'

# Get PR review comments
gh pr view --json reviews --jq '.reviews[] | {author: .author.login, state: .state, body: .body}'

# Get general PR comments (conversation)
gh api repos/{owner}/{repo}/issues/{pr_number}/comments --jq '.[] | {id, body, user: .user.login}'
```

### Step 5: Summarize Review Feedback

สรุป feedback ในรูปแบบ:

```markdown
## Review Summary

### Action Required (ต้องแก้ไข)
- [ ] [file:line] [description] - by @[reviewer]

### Suggestions (พิจารณา)
- [ ] [file:line] [description] - by @[reviewer]

### Deferred (สร้าง issue แล้วทำทีหลัง)
- [ ] [file:line] [description] - by @[reviewer] → #[issue-number]

### Praise/Acknowledgments (รับทราบ)
- [x] [description] - by @[reviewer]

### Questions (ตอบคำถาม)
- [ ] [question] - by @[reviewer]
```

### Step 6: Handle Each Comment

**IMPORTANT: Reply แยกแต่ละ comment โดยตรง**
- ห้ามรวม reply หลาย comments ไว้ใน comment เดียว
- ห้ามสร้าง comment ใหม่แยกต่างหาก
- ต้อง reply ไปที่ comment นั้นๆ โดยตรงเท่านั้น

**Thread Resolution:** ใช้ helper functions จาก [thread-resolution.md](thread-resolution.md) — `get_thread_id_for_comment(owner, repo, pr_number, comment_id)` และ `resolve_thread(thread_id)`

สำหรับ **แต่ละ comment** ให้ทำแยกกัน:

#### 6.1 Comment ที่ต้องแก้ไข

```bash
# 1. แก้โค้ดตาม review comment แล้ว commit
git add .
git commit -m "fix: [short description of fix]"

# 2. เก็บ hash ของ commit ที่เพิ่ง commit
COMMIT_HASH=$(git rev-parse --short HEAD)

# 3. Reply ไปที่ comment_id นั้นโดยตรง (ห้ามรวมกับ comment อื่น)
# IMPORTANT: ใส่ commit hash เพื่อให้ reviewer trace ได้
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="Fixed in ${COMMIT_HASH}! [description of what was changed]"
```

**หมายเหตุ:**
- ถ้าแก้หลาย comments ใน commit เดียว ทุก reply จะใช้ hash เดียวกัน
- สำหรับ reply ที่มี user content หรือ special characters ใช้ `-F` flag กับ temp file แทน:

```bash
# สำหรับ content ที่มี special chars (เช่น quotes, backticks)
REPLY_BODY="Fixed in ${COMMIT_HASH}!

$(echo "$USER_DESCRIPTION" | sed 's/[`$"\\]/\\&/g')"

echo "$REPLY_BODY" > /tmp/reply.txt
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -F body=@/tmp/reply.txt
rm /tmp/reply.txt
```

```bash
# Resolve thread
THREAD_ID=$(get_thread_id_for_comment "$owner" "$repo" "$pr_number" "$comment_id")
[[ -n "$THREAD_ID" ]] && resolve_thread "$THREAD_ID"
```

#### 6.2 Comment ที่ไม่ต้องแก้ไข

```bash
# Reply ไปที่ comment_id นั้นโดยตรง (ห้ามรวมกับ comment อื่น)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="Thanks for the suggestion!

[explanation why not changing]

[alternative approach if applicable]"
```

```bash
# Resolve thread
THREAD_ID=$(get_thread_id_for_comment "$owner" "$repo" "$pr_number" "$comment_id")
[[ -n "$THREAD_ID" ]] && resolve_thread "$THREAD_ID"
```

#### 6.3 Comment ที่เป็นคำถาม

```bash
# Reply ไปที่ comment_id นั้นโดยตรง (ห้ามรวมกับ comment อื่น)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="[answer to question]"
```

```bash
# Resolve thread
THREAD_ID=$(get_thread_id_for_comment "$owner" "$repo" "$pr_number" "$comment_id")
[[ -n "$THREAD_ID" ]] && resolve_thread "$THREAD_ID"
```

#### 6.4 Comment ที่เป็นคำชม

```bash
# Reply ไปที่ comment_id นั้นโดยตรง
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="Thank you! [brief acknowledgment]"
```

```bash
# Resolve thread
THREAD_ID=$(get_thread_id_for_comment "$owner" "$repo" "$pr_number" "$comment_id")
[[ -n "$THREAD_ID" ]] && resolve_thread "$THREAD_ID"
```

#### 6.5 Comment ที่ต้อง Defer (งานที่จะทำภายหลัง)

**IMPORTANT:** ห้ามตอบลอยๆ เช่น "will do later", "added to backlog" โดยไม่มี tracking

เมื่อ review comment ต้องการงานที่ไม่สามารถทำใน PR นี้ได้:

```bash
# 1. สร้าง issue ก่อน
# IMPORTANT: ใช้ <<'EOF' (quoted) เพื่อป้องกัน shell expansion จาก reviewer comment
DEFER_ISSUE=$(gh issue create \
  --title "[type]: [descriptive title from comment]" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Overview

From PR review comment by @[reviewer]

## Original Comment

> [quote the reviewer's comment]

## Context

- **PR:** #[pr_number]
- **File:** [file_path]
- **Line:** [line_number]

## Proposed Work

[description of what needs to be done]

## Acceptance Criteria

- [ ] [criteria based on reviewer's request]

---

*Created from PR review: [pr_url]*
EOF
)" --json number -q .number)

# 2. Reply พร้อม issue reference
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="Thanks for the feedback! Created #$DEFER_ISSUE to track this work."

# 3. Resolve thread
THREAD_ID=$(get_thread_id_for_comment "$owner" "$repo" "$pr_number" "$comment_id")
[[ -n "$THREAD_ID" ]] && resolve_thread "$THREAD_ID"
```

**ตัวอย่าง Defer Cases:**

| Review Comment | Issue Title | Label |
|----------------|-------------|-------|
| "Missing tests for this feature" | `test: add unit tests for [feature]` | `enhancement` |
| "Consider adding error handling" | `fix: improve error handling in [component]` | `enhancement` |
| "Documentation could be improved" | `docs: improve documentation for [feature]` | `enhancement` |
| "Performance could be better" | `perf: optimize [operation]` | `enhancement` |

#### 6.6 Verify All Threads Resolved

หลังจาก reply + resolve ทุก comment แล้ว ตรวจสอบว่าไม่มี unresolved threads เหลืออยู่:

```bash
# Check for any remaining unresolved threads
UNRESOLVED=$(gh api graphql -f query='
    query($owner: String!, $repo: String!, $pr: Int!) {
        repository(owner: $owner, name: $repo) {
            pullRequest(number: $pr) {
                reviewThreads(first: 100) {
                    nodes { isResolved }
                }
            }
        }
    }
' -f owner="$owner" -f repo="$repo" -F pr="$pr_number" \
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)] | length')

if [[ "$UNRESOLVED" -gt 0 ]]; then
    echo "Warning: $UNRESOLVED unresolved threads remaining"
    # See thread-resolution.md for batch resolution helpers
fi
```

### Step 7: Update Related Issues

```bash
# Get linked issues from PR
ISSUES=$(gh pr view --json closingIssuesReferences --jq '.closingIssuesReferences[].number')

# For each issue, add progress comment
for ISSUE in $ISSUES; do
  gh issue comment $ISSUE --body "## PR Review Progress

### Review Status: [status]

### Changes Made from Review
- [list of changes made]

### Pending Items
- [if any]

### Next Steps
- [what happens next]"
done
```

### Step 8: Create Learning Document

สร้าง learning document จาก review feedback ใช้ template จาก [review-learning-template.md](review-learning-template.md)

### Step 9: Push Changes

```bash
# Stage any remaining changes (learning docs, etc.)
git add -A

# Commit remaining changes if any
if ! git diff --cached --quiet; then
  git commit -m "docs: add learning from PR review

Responds to review by @[reviewer]"
fi

# Push all commits to update PR
git push
```

**หมายเหตุ:** Code fixes ถูก commit ไปแล้วใน Step 6.1 พร้อม hash ที่ใช้ใน reply

### Step 10: Final Summary

แสดงสรุปการทำงาน:

```markdown
## PR Review Complete

### PR: #[number] - [title]
**Reviewer**: @[reviewer] ([reviewer_type: human/copilot])

### Actions Taken
| Comment | Action | Status | Thread |
|---------|--------|--------|--------|
| [comment 1] | Fixed (commit hash) | Done | Resolved |
| [comment 2] | Replied | Done | Resolved |
| [comment 3] | Deferred → #[issue] | Done | Resolved |

### Stats
Total: [N] | Fixed: [N] | Replied: [N] | Deferred: [N] | Threads: [N]/[N]

### Next Steps
- [ ] Wait for re-review → `/pr-review` if new comments
- [ ] Work on deferred issues: #[number]
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No PRs found | Check `gh auth status` and repo access |
| Can't reply to comment | Check write permissions on repo |
| API rate limit | Wait or use `gh auth refresh` |

## Related Commands

| Command | Purpose |
|---------|---------|
| `/td` | Create PR after task completion |
| `/commit` | Atomic commits |
| `/mem` | Quick knowledge capture |
| `/review` | Local code review before push |
| `/pr-poll` | Start PR review polling daemon |
