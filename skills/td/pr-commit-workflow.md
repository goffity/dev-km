# PR Status Check & Commit Workflow

Step 7 detail from the `/td` command — handles committing docs based on PR status.

> **Language:** Follow the project's language setting (CLAUDE.md, fallback `DEVKM_LANG`, then `en` — see `references/bash-helpers.md` → Language Detection) as described in the parent `/td` skill. If Thai, generate PR descriptions and status text in Thai per `references/language-guide.md`. Commit messages remain in English.

## Step 7.1: Check Branch and PR Status

```bash
export TZ='Asia/Bangkok'

CURRENT_BRANCH=$(git branch --show-current)
ISSUE="<confirmed ticket from /td Step 0, e.g. 123>"   # literal — do not re-resolve

echo "=== Current State ==="
echo "Branch: $CURRENT_BRANCH"
echo "Issue: #$ISSUE"

# ตรวจสอบว่าอยู่บน main/master หรือไม่
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  echo "On protected branch - need to create docs branch"
  PR_STATUS="NO_BRANCH"
else
  # ตรวจสอบ PR status สำหรับ branch ปัจจุบัน
  PR_INFO=$(gh pr list --head "$CURRENT_BRANCH" --state all --json number,state,url --jq '.[0]')

  if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "null" ]; then
    echo "No PR found for branch $CURRENT_BRANCH"
    PR_STATUS="NO_PR"
  else
    PR_STATE=$(echo "$PR_INFO" | jq -r '.state')
    PR_NUMBER=$(echo "$PR_INFO" | jq -r '.number')
    echo "PR #$PR_NUMBER state: $PR_STATE"

    if [ "$PR_STATE" = "OPEN" ]; then
      PR_STATUS="OPEN"
    else
      PR_STATUS="CLOSED"  # MERGED or CLOSED
    fi
  fi
fi

echo "PR_STATUS: $PR_STATUS"
```

## Step 7.2: Handle by PR Status

### Case A: PR is OPEN

> **Note:** ต้องรัน section 7.1 ก่อนเพื่อให้ตัวแปร `PR_NUMBER` ถูกกำหนด

```bash
if [ -z "$PR_NUMBER" ]; then
  echo "ERROR: PR_NUMBER variable is not set. Run section 7.1 first."
  exit 1
fi

echo "PR #$PR_NUMBER is open - committing to existing PR"

echo "=== Docs Changes ==="
git status --short docs/

git add docs/

if git diff --cached --quiet; then
  echo "No changes to commit"
  exit 0
fi

git commit -m "$(cat <<'EOF'
docs: retrospective and session update for [TASK]

- Added activity log entry
- Created retrospective: [retrospective-file-path]

Related: #[issue-number]
EOF
)"

CURRENT_BRANCH=$(git branch --show-current)
git push -u origin "$CURRENT_BRANCH"

echo "Docs committed and pushed to PR #$PR_NUMBER"
```

### Case B: No PR or PR merged/closed (NO_PR, CLOSED, NO_BRANCH)

> **Note:** ต้องรัน section 7.1 ก่อนเพื่อให้ตัวแปร `ISSUE` ถูกกำหนด

```bash
echo "No open PR - creating new docs branch and PR"

if [ -z "$ISSUE" ]; then
  echo "ERROR: ISSUE variable is not set. Run section 7.1 first."
  exit 1
fi

# 1. Stash uncommitted docs changes
git stash push -m "docs-temp-$ISSUE" -- docs/
echo "Stashed docs changes"

# 2. Checkout main and pull latest
git checkout main
git pull origin main

# 3. Create docs branch
DOCS_BRANCH="docs/$ISSUE-retrospective"
git checkout -b "$DOCS_BRANCH"
echo "Created branch: $DOCS_BRANCH"

# 4. Pop stash
git stash pop
echo "Restored docs changes"

# 5. Stage docs
git add docs/

# 6. Check for changes
if git diff --cached --quiet; then
  echo "No changes to commit"
  exit 0
fi

# 7. Commit docs
git commit -m "$(cat <<'EOF'
docs: retrospective and session update for [TASK]

- Added activity log entry
- Created retrospective: [retrospective-file-path]

Related: #[issue-number]
EOF
)"

# 8. Push new branch
git push -u origin "$DOCS_BRANCH"

# 9. Detect base branch
if git branch -r | grep -q "origin/develop"; then
  BASE_BRANCH="develop"
else
  BASE_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d: -f2 | xargs)
fi
echo "Base branch: $BASE_BRANCH"

# 10. Create docs PR
gh pr create \
  --base "$BASE_BRANCH" \
  --title "docs: retrospective for #$ISSUE" \
  --body "$(cat <<'EOF'
## Summary

Session documentation update for issue #[issue-number]

## Changes

- Added activity log entry
- Created retrospective document

## Related

- Issue: #[issue-number]
- Original PR: #[original-pr-number] (merged)
EOF
)"

echo "Docs PR created"
```

## Step 7.3: Verify Commit

```bash
git log -1 --oneline
echo "Current branch: $(git branch --show-current)"
```
