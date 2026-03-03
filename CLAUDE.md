# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

dev-km is a 4-layer knowledge management skill for Claude Code CLI. It provides 27 sub-skills (21 user-invocable + 6 specialist) that handle session management, knowledge capture, git workflows, and integrations. All skills use the official Claude Code `SKILL.md` specification with YAML frontmatter.

## Architecture

### Skill System

Each skill lives in `skills/<name>/SKILL.md` using YAML frontmatter (`name`, `description`, `user-invocable`). The root `SKILL.md` is the system overview with `user-invocable: false`.

**Two types of skills:**
- **User-invocable** (`user-invocable: true`): Triggered by `/command` (e.g., `/mem`, `/focus`, `/pr`)
- **Specialists** (`context: fork`): Run in forked context for automated workflows (e.g., `code-reviewer`, `build-validator`)

### 4-Layer Knowledge Flow

```
/mem (Layer 1: quick capture) → /distill (Layer 2: extract patterns) → /td (Layer 3: retrospective) → /improve (Layer 4: act on pending items)
```

Output directories under `docs/`:
- `learnings/YYYY-MM/DD/` - `/mem` output
- `knowledge-base/` - `/distill` output
- `retrospective/YYYY-MM/` - `/td` output
- `auto-captured/YYYY-MM/DD/` - Auto-capture output

### Session Lifecycle

```
/recap → /focus (creates issue + branch) → work (/mem, /commit) → /pr (test + build + review + PR) → /td (retrospective)
```

State tracked in `docs/current.md` with states: ready → working → pending → blocked → completed.

### Installation Mechanism

- `scripts/install-symlinks.sh` creates symlinks from `skills/*` into `~/.claude/skills/` (27 total)
- `scripts/init.sh` sets up project-local directories (`docs/`, `.claude/commands/`, `.claude/scripts/`)
- Preferred install: `npx skills add goffity/dev-km --full-depth --all -g`

### Hooks

Defined in `hooks.json` and `.claude/settings.json`:
- **Notification hooks**: `idle_prompt`, `permission_prompt`, `elicitation_dialog` → `scripts/notify.sh`
- **Stop hook**: Auto-captures session on exit via `scripts/auto-capture.sh`

## Key Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Root skill definition (system overview, not user-invocable) |
| `hooks.json` | Hook configurations for notifications and auto-capture |
| `references/*.md` | Templates for mem, distill, td, and improve workflows |
| `scripts/init.sh` | Project initialization (creates dirs, copies commands, installs symlinks) |
| `scripts/install-symlinks.sh` | Creates 27 skill symlinks in `~/.claude/skills/` |
| `docs/current.md` | Current focus state (ISSUE/TASK tracking) |

## Development Notes

- This is a pure shell + markdown project. No build system, no package.json, no Makefile, no tests.
- Skills are markdown-only (`SKILL.md` files) — they contain instructions that Claude Code interprets.
- Scripts are bash (`scripts/*.sh`) with security measures: path validation (reject `..`), input sanitization in `notify.sh`.
- The `/commit` skill delegates to `tdg:atomic` (an external TDG skill dependency).
- The `/pr` skill expects target projects to have `make test` and `make build` — these are run in the user's project, not in dev-km itself.
- Commit messages use conventional format (`feat|fix|refactor|docs|test|chore|perf|style`) with no footer.

## Conventions

- Skill instructions (SKILL.md files) use Thai as the primary language.
- Generated output (issue comments, PR descriptions, local docs) follows the `LANGUAGE` setting in `docs/current.md`. Default is `en`. When `th`, use `references/language-guide.md` for translations.
- Commit messages and branch names always use English regardless of language setting.
- Timestamps use `Asia/Bangkok` timezone (`export TZ='Asia/Bangkok'`).
- GitHub CLI (`gh`) is used for all GitHub operations (issues, PRs, comments).
- Branch detection prefers `develop` as base, falls back to default branch.
