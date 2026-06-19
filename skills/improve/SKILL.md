---
name: improve
description: Extracts and implements pending improvement items from all knowledge sources.
user-invocable: true
---

# Improve - Work on Pending Items

ดึง actionable items จากทุก sources แล้วทำงาน (Layer 4)

## Instructions

### Language Setting

> Check `LANGUAGE` in `docs/current.md`. If `th`, translate output per `references/language-guide.md`. See `references/bash-helpers.md` for detection snippet.

1. **Scan** knowledge files (prioritized)
2. **Extract** actionable items
3. **Present** to user
4. **Execute** selected items
5. **Update** source files

## Scan Priority

| Priority | Source | Look For |
|----------|--------|----------|
| 1 | `kb/02-patterns/` | "When to Apply", patterns to implement |
| 2 | `kb/04-decisions/` | ADR action items (`- [ ]` in impact) |
| 3 | `kb/03-bugs/` | Postmortem "Action Items" (`- [ ]`) |
| 4 | `kb/05-ai-reviewed/retrospective/` | "Future Improvements" (`- [ ]`) |
| 5 | `kb/05-ai-reviewed/learnings/` | "Gotchas" to fix (skip "Distilled") |

> Note: `kb/` is a symlink to the Obsidian second-brain vault.
> Legacy paths `docs/knowledge-base/` + `docs/retrospective/` + `docs/learnings/` are deprecated — scan `kb/` only.

## Scan Commands

```bash
# Patterns (Priority 1)
find $PROJECT_ROOT/kb/02-patterns -name "*.md" -type f

# ADRs (Priority 2)
find $PROJECT_ROOT/kb/04-decisions -name "*.md" -type f

# Bug postmortems (Priority 3)
find $PROJECT_ROOT/kb/03-bugs -name "*.md" -type f

# Retrospectives (Priority 4)
find $PROJECT_ROOT/kb/05-ai-reviewed/retrospective -name "*.md" -type f

# Learnings (Priority 5, skip distilled)
find $PROJECT_ROOT/kb/05-ai-reviewed/learnings -name "*.md" -type f
```

## Present Format

```markdown
## Pending Improvements

### From Patterns - Priority 1

Kafka Error Handling.md:
1. [ ] Apply retry pattern to all consumers

### From ADRs - Priority 2

ADR-008-otelzap-trace-injection.md:
2. [ ] Migrate remaining services to otelzap

### From Bug Postmortems - Priority 3

2026-04-18 mongo - nil pointer dashboard.md:
3. [ ] Add nil-vs-empty check to report-api

### From Retrospectives - Priority 4

retrospective_2026-04-01_150100.md:
4. [ ] Add consumer mocks to Makefile

### From Learnings - Priority 5

14.30_redis-issue.md:
5. [ ] Document Redis patterns
```

## User Selection

Ask: "เลือก item (หมายเลข, 'all', หรือ 'skip')"

## Execute Workflow

For each selected item:
1. วิเคราะห์ task
2. Implement
3. Test
4. Commit (atomic)
5. Update source:
   - `- [ ]` → `- [x]`
   - Add changelog entry

## Output Summary

```markdown
## Completed

- [x] Add consumer mocks (commit: abc1234)
- [ ] Redis patterns (skipped - needs discussion)

Updated:
- kb/05-ai-reviewed/retrospective/2026-04/retrospective_*.md
```

## Rules

| Rule | Description |
|------|-------------|
| **PRIORITIZE** | Patterns first (stable), then ADRs, Bugs, Retros, Learnings |
| **ASK** | If needs discussion/approval |
| **UPDATE** | Source file after completion (use wiki-link `[[...]]` for cross-reference) |
| **ATOMIC** | Use atomic commits |
