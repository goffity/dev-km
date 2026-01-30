# GitHub API Patterns

| Field | Value |
|-------|-------|
| **Created** | 2026-01-14 |
| **Sources** | retrospectives (2026-01-10, 2026-01-14) |
| **Tags** | `github` `api` `graphql` `rest` `gh-cli` |

---

## Key Insight

> GitHub Discussions require GraphQL API (not REST), milestones use REST API, and `jq --arg` should be used for safe JSON construction with dynamic values.

---

## The Problem

| Attempt | Result |
|---------|--------|
| REST API for Discussions comments | 404 Not Found |
| String interpolation in JSON | Shell injection risk |
| `gh pr view --json` with missing scopes | Permission errors |
| Direct status change in Jira | Need workflow transitions |

---

## The Solution

### Pattern: Discussion Management (GraphQL)

GitHub Discussions ใช้ GraphQL API เท่านั้น (REST ไม่รองรับ)

#### List Discussions

```bash
# List all discussions with status
gh api graphql -f query='
query {
  repository(owner: "owner", name: "repo") {
    discussions(first: 20) {
      nodes {
        id
        number
        title
        closed
        isAnswered
        category { name }
      }
    }
  }
}' --jq '.data.repository.discussions.nodes[] |
  "\(.number). \(.title) [\(if .closed then "CLOSED" else "OPEN" end)] \(if .isAnswered then "✓ Answered" else "" end)"'
```

#### Get Discussion ID

```bash
DISCUSSION_ID=$(gh api graphql -f query='
query {
  repository(owner: "owner", name: "repo") {
    discussion(number: 36) {
      id
    }
  }
}' --jq '.data.repository.discussion.id')
```

#### Add Comment to Discussion

```bash
# Escape content for JSON (avoid useless use of cat)
BODY=$(jq -Rs . < content.md)

gh api graphql -f query="
mutation {
  addDiscussionComment(input: {
    discussionId: \"$DISCUSSION_ID\",
    body: $BODY
  }) {
    comment { id url }
  }
}"
```

#### Close Discussion

```bash
# Close with reason: RESOLVED, OUTDATED, or DUPLICATE
gh api graphql -f query='
mutation {
  closeDiscussion(input: {
    discussionId: "D_kwDOxxxxxx",
    reason: RESOLVED
  }) {
    discussion {
      id
      number
      closed
      closedAt
    }
  }
}'
```

**Close Reasons:**

| Reason | When to Use |
|--------|-------------|
| `RESOLVED` | คำถามได้รับคำตอบแล้ว / ปัญหาแก้ไขแล้ว |
| `OUTDATED` | ไม่เกี่ยวข้องแล้ว / เวอร์ชันเก่า |
| `DUPLICATE` | ซ้ำกับ discussion อื่น |

#### Reopen Discussion

```bash
gh api graphql -f query='
mutation {
  reopenDiscussion(input: {
    discussionId: "D_kwDOxxxxxx"
  }) {
    discussion { closed }
  }
}'
```

#### Mark Answer (Q&A category only)

```bash
# Mark a comment as the answer
gh api graphql -f query='
mutation {
  markDiscussionCommentAsAnswer(input: {
    id: "DC_kwDOxxxxxx"
  }) {
    discussion {
      isAnswered
      answer { body }
    }
  }
}'
```

### Pattern: Milestones (REST API)

```bash
# Create milestone
gh api repos/:owner/:repo/milestones \
  --method POST \
  -f title="v1.2 - Feature Name" \
  -f state="open" \
  -f description="Description here"

# List milestones (including closed)
gh api "repos/:owner/:repo/milestones?state=all" \
  --jq '.[] | "\(.number). \(.title) [\(.state)]"'

# Assign issue to milestone
gh issue edit 42 --milestone "v1.2 - Feature Name"
```

### Pattern: Safe JSON Construction

```bash
# WRONG - shell injection risk
gh api endpoint -f body="$USER_INPUT"

# CORRECT - use jq --arg
BODY=$(jq -n --arg content "$USER_INPUT" '{body: $content}')
gh api endpoint --input - <<< "$BODY"

# Or use file-based approach
echo "$USER_INPUT" > /tmp/body.txt
gh api endpoint -F body=@/tmp/body.txt
```

### Pattern: PR Review Comments

```bash
# Get PR comments
gh api repos/{owner}/{repo}/pulls/{pr}/comments \
  --jq '.[] | {id, path, line, body, user: .user.login}'

# Reply to specific comment
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies \
  -f body="Fixed in abc123!"
```

### Pattern: Handle Token Scope Errors

```bash
# Check current scopes
gh auth status

# Refresh with additional scopes
gh auth refresh -s project,read:project,read:org

# Common scope requirements:
# - project: GitHub Projects (ProjectsV2)
# - read:org: Organization data
# - read:discussion: Discussions
```

**Why this works:**
- GraphQL provides unified access to newer GitHub features
- REST API is simpler for established endpoints
- `jq --arg` prevents shell interpretation of values
- File-based approach is safest for arbitrary content

---

## Troubleshooting

### ปัญหาที่พบบ่อยและวิธีแก้ไข

| ปัญหา | สาเหตุ | วิธีแก้ |
|-------|--------|--------|
| `404 Not Found` เมื่อเรียก Discussion API | ใช้ REST แทน GraphQL | ใช้ `gh api graphql` แทน |
| `Resource not accessible` (read) | Token scope ไม่พอสำหรับอ่าน | `gh auth refresh -s read:discussion` |
| `Resource not accessible` (write) | Token scope ไม่พอสำหรับ mutation | `gh auth refresh -s write:discussion` |
| `Could not resolve to a Discussion` | Discussion ID ผิด | ใช้ GraphQL query หา ID ก่อน |
| `null` response จาก mutation | Permission หรือ state ไม่ถูกต้อง | ตรวจสอบว่า discussion ยังเปิดอยู่ |
| Shell injection ใน JSON body | ใช้ string interpolation | ใช้ `jq --arg` หรือ `-F body=@file` |

**Token Scopes for Discussions:**

| Operation | Required Scope |
|-----------|----------------|
| List/Query discussions | `read:discussion` |
| Add comment | `write:discussion` |
| Close/Reopen discussion | `write:discussion` |
| Mark as answer | `write:discussion` |

### วิธีตรวจสอบปัญหา

```bash
# 1. ตรวจสอบ token scopes
gh auth status

# 2. ตรวจสอบ discussion state
gh api graphql -f query='
query {
  repository(owner: "owner", name: "repo") {
    discussion(number: 36) {
      id
      closed
      isAnswered
      locked
    }
  }
}'

# 3. ทดสอบ API access
gh api graphql -f query='query { viewer { login } }'
```

### เมื่อ Close Discussion ไม่ได้

1. **ตรวจสอบว่าเป็น maintainer/owner** - ต้องมี write access
2. **ตรวจสอบว่า discussion ไม่ locked** - locked discussions ต้อง unlock ก่อน
3. **ใช้ Discussion ID ที่ถูกต้อง** - ต้องเป็น node ID (เริ่มด้วย `D_kw...`)

---

## Anti-Patterns

| Don't Do This | Do This Instead |
|---------------|-----------------|
| REST API for Discussions | GraphQL mutation |
| `-f body="$var"` with user content | `-F body=@file` or `jq --arg` |
| Assume token has all scopes | Check `gh auth status` first |
| `gh pr view --json reviews` without scope | Handle scope errors gracefully |
| Leave answered discussions open | Close with `reason: RESOLVED` |

---

## API Comparison

| Feature | API | Method |
|---------|-----|--------|
| Issues | REST | `gh issue` or `gh api` |
| Pull Requests | REST | `gh pr` or `gh api` |
| Discussions | **GraphQL** | `gh api graphql` |
| Projects V2 | **GraphQL** | Requires `project` scope |
| Milestones | REST | `gh api repos/.../milestones` |
| Releases | REST | `gh release` |

---

## When to Apply

### Use GraphQL
- **GitHub Discussions** - ทุก operation (list, comment, close, reopen)
- **PR Review Threads** - resolve/unresolve threads
- GitHub Projects V2
- Complex queries with relationships
- When REST endpoint doesn't exist

### Use REST API
- Issues and PRs (standard operations)
- Milestones
- Releases
- Simple CRUD operations

### Use `gh` CLI Shortcuts
- `gh issue`, `gh pr` - Built-in commands
- `gh api` - Direct REST API access
- `gh api graphql` - GraphQL queries

### Discussion Lifecycle

```
Created → Open → Answered → Closed (RESOLVED)
                    ↓
              Not Answered → Closed (OUTDATED/DUPLICATE)
                    ↓
                 Reopen ←←←←←←←←←←←←←←←←←←←←
```

| State | Action Available |
|-------|------------------|
| Open + Not Answered | Comment, Close, Lock |
| Open + Answered | Close (RESOLVED), Comment |
| Closed | Reopen, Comment |
| Locked | Unlock (admin only) |

---

## Quick Reference

| Task | Command |
|------|---------|
| List discussions | `gh api graphql -f query='query { repository(...) { discussions(...) } }'` |
| Add discussion comment | `gh api graphql -f query='mutation { addDiscussionComment(...) }'` |
| Close discussion | `gh api graphql -f query='mutation { closeDiscussion(input: {discussionId: "...", reason: RESOLVED}) }'` |
| Reopen discussion | `gh api graphql -f query='mutation { reopenDiscussion(...) }'` |
| Mark as answer | `gh api graphql -f query='mutation { markDiscussionCommentAsAnswer(...) }'` |
| Create milestone | `gh api repos/:owner/:repo/milestones --method POST` |
| PR review comments | `gh api repos/.../pulls/.../comments` |
| Reply to PR comment | `gh api .../comments/{id}/replies -f body="..."` |
| Resolve PR thread | `gh api graphql -f query='mutation { resolveReviewThread(...) }'` |
| Check token scopes | `gh auth status` |
| Add scopes | `gh auth refresh -s scope1,scope2` |

---

## Related

### Source Retrospectives
- `docs/retrospective/2026-01/retrospective_2026-01-10_092500.md`
- `docs/retrospective/2026-01/retrospective_2026-01-14_225435.md`

### Code References
- `assets/commands/pr-review.md` - PR comment handling
- `scripts/jira-client.sh` - API client patterns
