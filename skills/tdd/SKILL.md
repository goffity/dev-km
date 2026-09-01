---
name: tdd
description: Test-driven development loop (red-green-refactor) with commit-based phase state and Jira traceability. Use when the user wants to build a feature or fix a bug test-first, mentions "tdd", "red-green-refactor", or "test-first". Replaces the tdg plugin — combines its commit/phase discipline with seam-based test quality rules from kb Testing Standards.
argument-hint: "[feature/bug description or RUAYS-XXXX]"
---

# TDD Loop

Red → green loop engine with recoverable state (git commits) and issue traceability.

**This skill owns the loop mechanics only.** What makes a *good* test — seams, anti-patterns (tautological, implementation-coupled), mocking boundaries — is defined in one place: **`kb/02-patterns/standards/Testing Standards.md` §Test Quality** (kol-brain vault, reachable via the `kb/` symlink in kol-architecture or `~/Development/kol/kol-brain/`). Read that section before the first cycle and follow it on every cycle. Do not restate its rules here.

## Step 0: Project Config

Discover how to run tests from the repo itself (no config file needed):

- Read the repo's `CLAUDE.md` and `Makefile` — kol convention: `make test`, `make build`
- Single test: `go test ./<pkg>/... -run '<TestName>'` (use `go.work` at workspace root when the module lacks test deps — e.g. game-repository)
- Coverage: `go test ./<pkg>/... -cover`
- If a legacy `TDG.md` exists, honor it (backward compat)

## Step 1: Traceability

Identify the Jira ticket before starting:

1. Check the user's message for `RUAYS-XXXX`
2. Check the branch name (e.g. `feature/RUAYS-2041-slip-only-flag`)
3. If not found, ask the user

Every commit in the loop ends with the ticket: `(RUAYS-XXXX)`.

## Step 2: Agree Seams (GATE — before any test)

List the seams under test — the public interfaces where behavior will be observed (service interface, handler HTTP contract, repository query layer) — per the seam table in kb §Test Quality. Confirm with the user via AskUserQuestion before writing any test. **No test is written at an unconfirmed seam.** This is how testing effort lands on critical paths instead of every edge case.

Then break the work into vertical slices: one behavior per cycle. Do **not** draft implementation code first — the failing test at the seam is the design step.

## Step 3: Check Phase

```bash
bash ~/.claude/skills/tdd/scripts/tdd-phase.sh
```

Reads commits since merge-base with develop/main, so state survives session restarts and ignores unrelated commits. Resume from the phase it reports:

| Phase | Meaning | Next action |
|---|---|---|
| `unknown` / `refactor` | No cycle in progress | Start RED for the next slice |
| `red` | Failing test committed | Go GREEN |
| `green` | Implementation committed | Next slice (RED) or refactor |

## The Loop

### RED — failing test first

1. Write **one** test for the current slice, at an agreed seam, following kb §Test Quality (expected values from an independent source; name says WHAT not HOW)
2. Run that single test — **it must fail for the right reason** (assertion, not compile error you didn't intend)
3. Commit (only the files you edited, never `git add .`):
   `test(red): <behavior> (RUAYS-XXXX)`

### GREEN — minimal implementation

1. Verify the last phase is `red` (script)
2. Write only enough code to pass the test — no speculative features, no anticipating future tests
3. Run the single test (pass), then the package's tests (no regressions)
4. Commit: `feat(green): <behavior> (RUAYS-XXXX)` — use `fix(green):` for bug fixes

### REFACTOR — optional, light only

Small cleanups (naming, extraction) while green: commit as `refactor: <what> (RUAYS-XXXX)`. Structural redesign belongs to the review stage (`/code-review`, `/pr`), not the loop — don't let refactoring grow the cycle.

Then loop back to RED for the next slice, or finish.

## Rules

- **One slice per cycle**: one seam, one test, one minimal implementation
- **Red before green, always** — never commit implementation without a preceding `test(red)` commit for it
- Commit format is Conventional Commits (passes commitlint); phase lives in the scope. Squash-merge via `/pr` keeps red/green history out of main
- Bug fixes: the RED test is the regression test (must fail on the unfixed code) — satisfies kb "fix bug ต้องมี regression test"
- Track cycles with the Todo list: `☐ RED: <slice>` → `☐ GREEN: <slice>` per slice

## Finish

When all slices are done: run the full `make test` + coverage on touched packages (kb: ≥ 80% for touched functions), then hand off to `/pr`.
