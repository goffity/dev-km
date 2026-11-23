# PR Issue Comment Templates

Templates for `gh issue comment` during the `/pr` flow. The ticket is resolved once in `/pr` Step 0 (see `references/bash-helpers.md` → Focus Context) and written literally into each snippet.

**Base pattern:**
```bash
export TZ='Asia/Bangkok'
ISSUE="<confirmed ticket from /pr Step 0, e.g. 123>"   # literal — do not re-resolve
gh issue comment $ISSUE --body "$(cat <<'EOF'
[template body]
EOF
)"
```

---

## Step 1: Tests

### Running Tests
```markdown
## Running Tests

**Started:** $(date '+%Y-%m-%d %H:%M')
**Status:** In Progress

Running `make test`...
```

### Tests Failed
```markdown
## Tests Failed

**Time:** $(date '+%Y-%m-%d %H:%M')

### Error Output
```
[test error output]
```

### Action Required
แก้ไข test errors และรัน `/pr` อีกครั้ง
```

### Tests Passed
```markdown
## Tests Passed

**Time:** $(date '+%Y-%m-%d %H:%M')
**Status:** All tests passed

Proceeding to build...
```

---

## Step 2: Build

### Build Failed
```markdown
## Build Failed

**Time:** $(date '+%Y-%m-%d %H:%M')

### Error Output
```
[build error output]
```

### Action Required
แก้ไข build errors และรัน `/pr` อีกครั้ง
```

### Build Passed
```markdown
## Build Passed

**Time:** $(date '+%Y-%m-%d %H:%M')
**Status:** Build successful

Proceeding to code review...
```

---

## Step 3: Code Review

### Code Review Started
```markdown
## Code Review Started

**Time:** $(date '+%Y-%m-%d %H:%M')
**Status:** Reviewing...

Running automated code review...
```

### Code Review Failed
```markdown
## Code Review Failed

**Time:** $(date '+%Y-%m-%d %H:%M')

### Critical Issues Found

[list of critical issues from review]

### Action
Sending to agent for auto-fix...
```

### Code Review Passed
```markdown
## Code Review Passed

**Time:** $(date '+%Y-%m-%d %H:%M')

### Summary
- Critical: 0
- Warnings: [count]
- Info: [count]

### Warnings (if any)
[list of warnings]

Proceeding to create PR...
```

---

## Step 5: PR Created

```markdown
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
```
