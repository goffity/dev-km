---
name: mem
description: Captures quick knowledge insights during work sessions into structured learning files.
argument-hint: "[topic]"
user-invocable: true
---

# Memory - Quick Knowledge Capture

จับความรู้แบบรวดเร็วระหว่างทำงาน (Layer 1)

## Usage

```
/mem [descriptive title]
```

**Output:** `$PROJECT_ROOT/kb/05-ai-reviewed/learnings/YYYY-MM/DD/HH.MM_[slug].md`

## Instructions

### Language Setting

> **Language:** follow the project's CLAUDE.md (fallback `DEVKM_LANG`, then `en`) — see `references/bash-helpers.md` → Language Detection. If Thai, translate output per `references/language-guide.md`.

1. **Process title** → slug (lowercase, hyphens)
2. **Gather context**: timestamp, branch, recent commits
3. **Create directory**: `kb/05-ai-reviewed/learnings/YYYY-MM/DD/`
4. **Generate file** with template below
5. **Commit**: `git commit -m "learn: [title]"`

## Template

```markdown
# [Title]

| Field | Value |
|-------|-------|
| **Captured** | YYYY-MM-DD HH:MM (Asia/Bangkok) |
| **Branch** | current-branch |
| **Context** | what were you working on |

---

## Key Insight

> One-sentence summary

## What We Learned

- Discovery 1
- Discovery 2

## Gotchas & Warnings

- Pitfall to avoid

## Related

- Commits: `abc1234`
- Files: `path/to/file.go`

## Tags

`tag1` `tag2`
```

## Rules

| Rule | Description |
|------|-------------|
| **FAST** | Complete in < 20 seconds |
| **KNOWLEDGE-FOCUSED** | Insights, not task logs |
| **SEARCHABLE** | Clear titles and tags |
