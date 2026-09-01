---
name: dev-km
description: 4-layer knowledge capture system for development sessions with session management, retrospectives, and knowledge distillation.
user-invocable: false
---

# Development Knowledge Management System

4-layer system for capturing and organizing development knowledge.

## Dev Flow

```
/recap → /focus (issue + branch) → /tdd (red-green loop) + /commit → /td (retrospective) + /mem (capture knowledge)
```

## Core Skills (user-invocable)

| Skill | Layer | Output | Trigger |
|-------|-------|--------|---------|
| `/mem [topic]` | 1 | `kb/05-ai-reviewed/learnings/YYYY-MM/DD/HH.MM_slug.md` | Quick insight capture |
| `/distill [topic]` | 2 | `kb/02-patterns/<domain>/[topic].md` | 3+ learnings on same topic |
| `/td` | 3 | `kb/05-ai-reviewed/retrospective/YYYY-MM/retrospective_*.md` | Task completed |
| `/improve` | 4 | Implementation | Work on pending items |
| `/recap` | - | Context summary | Start new session |
| `/focus [task]` | - | Issue + branch | Set current task |

## Git & PR Skills (user-invocable)

| Skill | Purpose |
|-------|---------|
| `/commit` | Atomic commits (TDD-aware, self-contained) |
| `/pr` | Tests, build, review, create PR |
| `/review` | Code review before push |
| `/pr-review` | Handle PR review feedback (own PR) |
| `/pr-audit [pr#]` | Reviewer-side deep audit of an open PR (clone+build, inline+summary) |
| `/pr-poll` | PR review notification daemon |

## Knowledge & Docs Skills (user-invocable)

| Skill | Purpose |
|-------|---------|
| `/cleanup` | Retention policy management |
| `/consolidate` | Daily session file consolidation |
| `/summary` | Weekly/monthly summaries |
| `/search` | Search knowledge index |
| `/example` | Save code examples |
| `/flow` | Process flow diagrams |
| `/pattern` | Design pattern docs |
| `/share` | Cross-project knowledge sharing |

## Integration & Config Skills (user-invocable)

| Skill | Purpose |
|-------|---------|
| `/jira` | Jira issue management |
| `/permission` | Manage Claude Code permissions |

## Specialist Skills (context: fork, not user-invocable)

| Skill | Purpose |
|-------|---------|
| `code-reviewer` | Reviews code for bugs, security, performance |
| `session-analyzer` | Analyzes git changes for retrospective drafts |
| `knowledge-curator` | Scans learnings, suggests distill topics |
| `build-validator` | Validates build, tests, lint before push |
| `code-simplifier` | Simplifies code, reduces complexity |
| `security-auditor` | OWASP Top 10 security audit |

## Directory Structure

```
kb/                          # symlink to Obsidian second-brain vault
├── 02-patterns/             # /distill, /pattern output (curated patterns)
│   ├── <domain>/            #   grpc, observability, database, k8s, ...
│   ├── anti-patterns/       #   anti-pattern registry
│   ├── examples/            # /example output
│   └── flows/               # /flow output
├── 03-bugs/                 # Bug postmortems (scanned by /improve)
├── 04-decisions/            # ADRs (scanned by /improve)
└── 05-ai-reviewed/
    ├── learnings/           # /mem output
    │   └── YYYY-MM/DD/
    ├── retrospective/       # /td output
    │   └── YYYY-MM/
    └── summaries/           # /summary output

docs/                        # repo-local, NOT in vault
├── auto-captured/           # Auto-capture output
├── shared-knowledge/        # /share output
├── logs/                    # Activity log
└── current.md               # Current focus state (STATE/TASK/ISSUE/BRANCH/LANGUAGE)
```

> `kb/` = symlink to the Obsidian vault. Legacy `docs/{learnings,knowledge-base,retrospective,...}` paths are deprecated.

## Setup

```bash
./scripts/init.sh $PROJECT_ROOT
```

## Language Support

Output language is configured via `LANGUAGE` field in `docs/current.md`.

| Value | Behavior |
|-------|----------|
| `en` (default) | All generated output in English |
| `th` | Generated output in Thai (commit messages stay English) |

Set during `/focus` or manually edit `docs/current.md`. See `references/language-guide.md` for translation reference.

## References

- `references/bash-helpers.md` - Common bash snippets (TZ, language detection, focus context)
- `references/mem-template.md` - Full /mem template
- `references/distill-template.md` - Full /distill template
- `references/td-template.md` - Full /td template
- `references/improve-workflow.md` - /improve detailed workflow
- `references/language-guide.md` - Thai/English translation guide
