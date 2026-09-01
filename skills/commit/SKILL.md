---
name: commit
description: Creates atomic commits by analyzing changes, detecting mixed concerns, and commenting on related GitHub issues. TDD-aware — defers to the /tdd loop's commit convention when a red/green cycle is in progress.
user-invocable: true
---

# Atomic Commit

Analyze changes and create clean, atomic commits. Self-contained — no plugin dependency.

## Instructions

### Language Setting

> Check `LANGUAGE` in `docs/current.md`. If `th`, translate output per `references/language-guide.md`. See `references/bash-helpers.md` for detection snippet.

### Step 0: TDD Loop Check

If the branch is mid TDD cycle, commits belong to the loop — not to after-the-fact grouping:

```bash
bash ~/.claude/skills/tdd/scripts/tdd-phase.sh
```

- **`red` or `green`**: a `/tdd` cycle is in progress. Do NOT batch-commit — follow the `/tdd` skill's commit convention for the current phase (`test(red):`, `feat(green):`/`fix(green):`, `refactor:`) and commit only the current slice's files. Then stop.
- **`unknown` or `refactor`** (or the script is missing): no cycle in progress — proceed with the atomic workflow below.

### Step 1: Analyze Changes

```bash
git branch --show-current && git status && git diff && git diff --staged
```

An **atomic commit**: does exactly one thing, leaves the codebase in a working state (build + tests pass), can be reverted independently, mixes no unrelated concerns.

### Step 2: Detect Mixed Concerns

Look for changes mixing: multiple features · bug fix + feature · refactoring + new functionality · unrelated bug fixes · code + unrelated docs · tests for multiple features.

### Step 3: Group Commits

Group files by shared purpose and present the grouping to the user for confirmation:

```
Group 1: "Add slip-only flag" → user-api/handler/account.go, user-repository/account.go, user-api/handler/account_test.go
Group 2: "Fix maintenance window check" → user-api/service/maintenance.go, user-api/service/maintenance_test.go
```

### Step 4: Create Each Commit

For each group:

1. Stage explicitly: `git add <file1> <file2>` — **never `git add .` or `-a`**
2. Review: `git diff --cached`
3. Test + build: `make test && make build` — must pass before committing
4. Commit with Conventional Commit format: `feat|fix|refactor|docs|test|chore|perf|style`
5. Verify: `git log -1 --oneline`

### Step 5: Final Review

```bash
git log --oneline -n <N>
```

## Commit Message Rules

- Conventional commit format; include ticket ref when known: `feat: <desc> (RUAYS-XXXX)` or `(#42)`
- **NO footer** — no "Generated with...", "Co-Authored-By...", or similar
- Concise and descriptive; no vague messages, no debug code

## Post-Commit: Issue Comment

After commits are created, automatically comment on the related GitHub issue:

1. **Find Issue Number** - Check `docs/current.md` for `ISSUE: #N` or extract from branch name/commits
2. **If issue found**, comment with:

```bash
gh issue comment <issue-number> --body "$(cat <<'EOF'
## Implementation Update

### Changes Made
[List files changed and what was modified]

### Commits
[List commit hashes and messages]

### Status
- Branch: `<branch-name>`
- Ready for: review / merge / testing
EOF
)"
```

3. **If no issue found**, skip commenting silently
