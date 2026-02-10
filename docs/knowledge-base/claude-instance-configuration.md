# Claude Instance Configuration & Knowledge Sharing

| Field | Value |
|-------|-------|
| **Created** | 2026-02-10 |
| **Sources** | 3 learnings (2025-12-23, 2026-02-10 x2) |
| **Tags** | `claude-md` `preferences` `specialist` `multi-agent` `configuration` |

---

## Key Insight

> `~/.claude/CLAUDE.md` is the single **globally shared** baseline for rules that ALL Claude instances must follow — including specialists spawned by multi-agent orchestration. Project and workspace rule files can add further constraints but should not conflict with these global rules.

---

## The Problem

| Attempt | Result |
|---------|--------|
| Store rules in skill's `docs/` dir (`~/.claude/skills/claude-km-skill/docs/`) | Specialists can't access — different workspace |
| Rely on Claude default behavior | Auto-generated footers, Co-Authored-By in commits |
| Per-project CLAUDE.md only | Rules not shared across projects/instances |

---

## The Solution

### Pattern: Configuration Hierarchy

```
~/.claude/CLAUDE.md              ← Global (ALL instances see this)
  └── {project}/CLAUDE.md        ← Project-specific
       └── {workspace}/.claude/rules/*.md  ← Instance-specific (e.g., specialist)
```

### What Each Instance Can See

**Terminology:**
- **Main Claude** — The primary Claude Code instance the user interacts with directly
- **Specialist** — An independent Claude instance spawned by multi-agent orchestration, running in its own workspace directory (e.g., `workspaces/specialist-name/`)
- **Subagent** — A child agent spawned within the same process via the Task tool; inherits the parent's working directory and context
- **`{project}`** — The root directory of the current git repository (where `CLAUDE.md` lives)
- **`{workspace}`** — The working directory assigned to a specific specialist instance

| Source | Main Claude | Specialist | Subagent |
|--------|-------------|------------|----------|
| `~/.claude/CLAUDE.md` | Yes | Yes | Yes |
| `{project}/CLAUDE.md` | Yes | Only own workspace | Yes (parent's) |
| `{workspace}/.claude/rules/` | Yes | Only own workspace | No |
| `~/.claude/skills/claude-km-skill/docs/` | Yes (if in that dir) | No | No |

### Pattern: What Goes Where

```
~/.claude/CLAUDE.md:
  - User preferences (no footer, no Co-Authored-By)
  - Git workflow rules (stash before checkout, push -u)
  - Shell safety rules (quoted HEREDOC, safe JSON)
  - GitHub API gotchas (Discussions = GraphQL, etc.)

{project}/CLAUDE.md:
  - Project-specific conventions
  - Build/test commands
  - Architecture decisions

{workspace}/.claude/rules/specialist.md:
  - Specialist-specific instructions
  - TDD workflow guidance
  - Signal/IPC protocol
```

**Why this works:**
- Global rules apply everywhere without manual copying
- Project rules stay scoped to their codebase
- Specialist rules are injected at spawn time

---

## Anti-Patterns

| Don't Do This | Do This Instead |
|---------------|-----------------|
| Store global rules in skill's docs/ | Put in `~/.claude/CLAUDE.md` |
| Put too many rules in global CLAUDE.md | Only critical rules and preferences |
| Duplicate rules across project CLAUDE.md files | Use global for shared rules |
| Expect specialist to read other workspace files | Pass info via signals or global config |
| Put project-specific rules in global CLAUDE.md | Use `{project}/CLAUDE.md` |

---

## User Preferences (Current)

Rules currently in `~/.claude/CLAUDE.md`:

| Category | Rule |
|----------|------|
| **GitHub** | No footer in `gh issue create` / `gh pr create` body |
| **GitHub** | No "Generated with Claude Code" footers |
| **Git** | No `Co-Authored-By` in commit messages |
| **Git** | No auto-generated footers in commits |
| **Git** | Stash before checkout, push -u, diff --cached before commit |
| **Shell** | Use `<<'EOF'` by default for HEREDOC |
| **Shell** | Never `-f body="$USER_INPUT"` |
| **API** | Discussions require GraphQL, not REST |
| **API** | `gh issue create` has no `--json` flag |
| **API** | Use `-F` (typed) not `-f` (string) for numeric fields |

---

## When to Apply

### Add to Global CLAUDE.md
- User preferences that apply to ALL projects
- Security rules (shell injection prevention)
- Tool-specific gotchas (GitHub API quirks)
- Conventions that specialists must also follow

### Add to Project CLAUDE.md
- Build/test/lint commands
- Code style specific to project
- Architecture patterns for that codebase
- Branch naming conventions

### Don't Add to CLAUDE.md
- Knowledge that's for reference only (use knowledge-base/)
- Detailed patterns with examples (use knowledge-base/)
- Session-specific notes (use learnings/)

---

## Related

### Source Learnings
- `docs/learnings/2025-12/23/17.23_no-footer-in-github-issues.md`
- `docs/learnings/2026-02/10/01.18_no-co-authored-by-in-commits.md`
- `docs/learnings/2026-02/10/01.25_global-claude-md-rules-specialist-visible.md`

### Related Knowledge
- `docs/knowledge-base/git-workflow-patterns.md`
- `docs/knowledge-base/github-api-patterns.md`
- `docs/knowledge-base/heredoc-quoting.md`

### Code References
- `~/.claude/CLAUDE.md` - Global configuration file
- `~/.claude/skills/multi-agent-auto-skill/templates/CLAUDE.specialist.md` - Specialist template
