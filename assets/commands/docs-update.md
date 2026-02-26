---
description: Update feature documentation and changelog after push
---

# Documentation Update

อัพเดท feature documentation และ changelog หลัง push ไป main หรือ develop

## Usage

```
/docs-update
```

## Instructions

### Step 1: Detect Current Branch and Context

```bash
export TZ='Asia/Bangkok'
echo "=== Branch Info ==="
BRANCH=$(git branch --show-current)
echo "Current branch: $BRANCH"
echo ""

echo "=== Recent Commits (since last tag or last 20) ==="
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
    echo "Since tag: $LAST_TAG"
    git log "$LAST_TAG"..HEAD --oneline --no-merges
else
    git log --oneline --no-merges -20
fi
echo ""

echo "=== Merged PRs (recent) ==="
gh pr list --state merged --limit 10 --json number,title,mergedAt,headRefName,labels --jq '.[] | "\(.number) | \(.title) | \(.mergedAt) | \(.headRefName)"' 2>/dev/null || echo "(gh not available or no PRs)"
```

### Step 2: Analyze Changes

Read the current documentation files:

1. Read `docs/features/README.md` — current feature index
2. Read `docs/features/changelog.md` — current changelog
3. Scan `docs/features/` for existing per-feature docs

From the commits and PRs gathered in Step 1, categorize each change:
- **Added** — new features (look for `feat/` branches, "add", "implement" in commits)
- **Changed** — modifications to existing features (look for "update", "refactor", "improve")
- **Fixed** — bug fixes (look for `fix/` branches, "fix", "bug" in commits)
- **Removed** — removed features (look for "remove", "delete", "deprecate")

Extract JIRA ticket IDs from branch names and commit messages (pattern: `[A-Z]+-\d+`).

### Step 3: Update Changelog

**If on `develop` or feature branch:**
- Add new entries to the `[Unreleased]` section in `docs/features/changelog.md`
- Do NOT create a dated release section
- Keep existing entries, only add new ones that aren't already listed

**If on `main`:**
- Move all entries from `[Unreleased]` to a new dated section: `## [YYYY-MM-DD]`
- Add a descriptive title if there's a clear theme
- Leave `[Unreleased]` section empty (with subsection headers)
- Then add any new entries found in recent main commits

**Changelog entry format:**
```markdown
- **JIRA-ID**: Short description
  - Detail about the change
  - PRs: repo #number, repo #number
```

### Step 4: Create/Update Per-Feature Docs

For each JIRA ticket found in changes:
1. Check if `docs/features/[JIRA-ID].md` exists
2. If not, create it with available information from PRs and commits
3. If it exists, update with any new information (new PRs, status changes)

Per-feature doc template:
```markdown
# [JIRA-ID]: [Feature Title]

## Overview
Brief description of the feature.

## Status
Current status (In Development / In Review / Merged / Released)

## Pull Requests
| Service | Branch | PR | Status |
|---------|--------|----|--------|
| service-name | branch-name | #number | status |

## Architecture
(If available from existing docs or PR descriptions)

## Changes Summary
- Key changes in each service
```

### Step 5: Update Feature Index

Update `docs/features/README.md`:
1. Add new features to the appropriate section (Active Features / Bug Fixes / Refactoring)
2. Update status of existing features (In Development → In Review → Merged → Released)
3. Update the "Last updated" date
4. Add links to per-feature docs

**Status flow:**
- Feature branch exists, PRs open → `In Development`
- PRs submitted for review → `In Review`
- PRs merged to develop → `Merged to Develop`
- Merged to main → `Released`

### Step 6: Commit Changes

```bash
export TZ='Asia/Bangkok'
cd "$PROJECT_ROOT"

# Stage only docs/features/ files
git add docs/features/

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "No documentation changes to commit."
else
    git diff --cached --stat
    git commit -m "docs: update feature documentation and changelog"
fi
```

## Output Format

```markdown
## Documentation Updated

### Changelog
- [Unreleased] / [YYYY-MM-DD]: X entries added/moved

### Feature Index
- New: [list new features added]
- Updated: [list features with status changes]

### Per-Feature Docs
- Created: [list new docs]
- Updated: [list updated docs]

### Commit
[commit hash] docs: update feature documentation and changelog
```

## Rules

| Rule | Description |
|------|-------------|
| **IDEMPOTENT** | Running multiple times produces same result |
| **ADDITIVE** | Never removes existing entries, only adds |
| **BRANCH-AWARE** | Behavior differs on main vs develop vs feature |
| **PR-LINKED** | Always links to PRs when available |
| **JIRA-TRACKED** | Extracts JIRA IDs from branches/commits |

## Related Commands

| Command | Purpose |
|---------|---------|
| `/docs-update` | Update docs (you are here) |
| `/commit` | Atomic commits |
| `/pr` | Create PR |
| `/td` | Session retrospective |
