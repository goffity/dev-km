---
description: Create atomic commits from staged/unstaged changes
---

# Atomic Commit

Invoke the `commit` skill (`~/.claude/skills/commit/SKILL.md`) — the single source of truth for the atomic-commit workflow. Do not duplicate its steps here.

```
/commit
```

It is self-contained (no plugin dependency) and TDD-aware:

- If a `/tdd` red/green cycle is in progress on the branch, it follows the loop's commit convention (`test(red):`, `feat(green):`) instead of batch-grouping
- Otherwise: analyze changes → detect mixed concerns → group by purpose → confirm → per group: stage → review → test → commit → verify
- Conventional Commits, no footers, and posts an Implementation Update comment on the related issue when one is found
