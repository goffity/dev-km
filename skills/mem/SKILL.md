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

**Output:** `$PROJECT_ROOT/docs/learnings/YYYY-MM/DD/HH.MM_[slug].md`

## Instructions

### Language Setting

Before generating any output, check the language setting:

```bash
LANG=$(grep "^LANGUAGE:" docs/current.md 2>/dev/null | cut -d: -f2 | xargs)
```

If `LANG` is `th`, generate learning file headings in Thai. Refer to `references/language-guide.md` for standard translations. Commit messages and file slugs always remain in English.

1. **Process title** → slug (lowercase, hyphens)
2. **Gather context**: timestamp, branch, recent commits
3. **Create directory**: `docs/learnings/YYYY-MM/DD/`
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
