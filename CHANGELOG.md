# Changelog

All notable changes to **dev-km** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.25.0] - 2026-06-19

### Added
- **`/pr-audit` skill** (#19) — reviewer-side deep audit of an open PR by number/URL.
  - Resolves PR (supports `--repo owner/name` and cross-repo forks).
  - Clones the PR branch into an isolated **git worktree** (never touches the main working tree) and always runs **build + test** via the `build-validator` subagent.
  - Deep review via the `code-reviewer` subagent, plus **cross-layer wiring** checks (CI workflow → Dockerfile `ARG`/`ENV` → app runtime, migration → repository, proto → impl).
  - **KB-first policy**: searches `kb/` before flagging known patterns; stops to ask + records a new KB entry when none exists.
  - Compares against existing **Copilot / reviewer** comments, dedupes, and replies to disagreements with evidence.
  - Two modes — `--mode=review` (report in chat) and `--mode=comment` (post **inline conversation** bound to `commit_id`+`path`+`line` **and** a **summary review**).
  - `--lang=th|en` (default `th`) for posted comments.
  - Always cleans up the worktree and restores the original branch, even on failure.
  - Companion reference `skills/pr-audit/known-patterns.md` (e.g. Go **dup-import** is not a compile error — build first; cross-layer wiring checklist).
- **`/pr-review` Thai reply templates** (#17) — translations for the 6.1–6.5 reply bodies (`Fixed in …`, `Thanks for the suggestion!`, `Thank you!`, `Created #N to track …`) added to `references/language-guide.md`, with a pointer from the skill.

### Changed
- **Usage docs synced with all skills.** `SKILL.md` and `README.md` skill tables now list `/pr-audit` and distinguish `/pr-review` (own PR) from `/pr-audit` (others' PRs).
- **Directory-structure docs migrated** in `SKILL.md` and `README.md` from the legacy `docs/{learnings,knowledge-base,retrospective,…}` layout to the `kb/` Obsidian vault layout (`kb/02-patterns`, `kb/03-bugs`, `kb/04-decisions`, `kb/05-ai-reviewed/{learnings,retrospective,summaries}`). `docs/` now documents only repo-local artifacts (`auto-captured`, `shared-knowledge`, `logs`, `current.md`).
- `ROADMAP.md` records #17/#18/#19 under a completed **v1.3 – i18n, KB Vault & PR Audit** milestone.

### Verified
- **`/pr` language support** (#18) — confirmed already satisfied by the i18n infrastructure: `/pr` reads `LANGUAGE` from `docs/current.md` and `references/language-guide.md` covers all issue comments and the PR body template. No code change required.

## [0.24.4] - 2026-06-19

### Changed
- **Knowledge paths migrated `docs/` → `kb/` (Obsidian vault).** All skills and reference templates now read/write the vault layout:
  - `docs/knowledge-base/` → `kb/02-patterns/<domain>/`
  - `docs/learnings/` → `kb/05-ai-reviewed/learnings/`
  - `docs/retrospective/` → `kb/05-ai-reviewed/retrospective/`
  - `docs/summaries/` → `kb/05-ai-reviewed/summaries/`
- `/improve` and `references/improve-workflow.md` gained scan priorities for `kb/03-bugs/` (postmortem action items) and `kb/04-decisions/` (ADR action items).
- `/distill` pattern template gained YAML frontmatter (`tags`, `type`, `domain`, `services`, `date`, `status`) and `[[wiki-link]]` cross-references for the Obsidian graph.
- `/focus` gained a pre-feature checklist (grep anti-pattern registry, verify data flow in real code, read repo `CLAUDE.md`) and a `PLAN:` field in `docs/current.md`.

## [0.24.x] - 2026-06-19

### Added
- **i18n infrastructure** — `LANGUAGE` config in `docs/current.md`, `references/language-guide.md` translation reference, and Thai language support across docs/GitHub-artifact skills.
- Shared `references/bash-helpers.md` for common snippets (TZ, language detection, focus context).

### Fixed
- `/pr-review` thread resolution inlined into Steps 6.1–6.5 (reply + resolve as one atomic action) with a completion gate verifying zero unresolved threads (#15, #16).

### Changed
- Extracted large skill content into bundled resource files; replaced inline language preambles with compact references.

---

[Unreleased]: https://github.com/goffity/dev-km/compare/v0.25.0...HEAD
[0.25.0]: https://github.com/goffity/dev-km/compare/v0.24.4...v0.25.0
[0.24.4]: https://github.com/goffity/dev-km/releases/tag/v0.24.4
