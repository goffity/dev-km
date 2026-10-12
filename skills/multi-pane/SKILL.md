---
name: multi-pane
description: Run multi-session work — this (main) session stays a normal terminal and orchestrates; worker Claude sessions run in a separate tmux session the user watches in its own window. Use when the user asks to split work across panes/sessions/workers, run repos in parallel, or set up an owner + QA pane loop.
user-invocable: true
---

# Multi-Pane Orchestration

The main session (this one, a normal terminal) is the **router**: it talks to the user, sends work to worker panes, watches
for results, checks reviews/CI, merges what it is allowed to, and reports. Worker Claude sessions live in a **separate tmux
session** (default `mp`) that the user watches in its own iTerm window. Workers never talk to each other — everything goes
through the main session.

Scripts: `~/.claude/skills/multi-pane/scripts/` (below called `$MP`). Hook: `~/.claude/hooks/pane-notify.sh`
(Stop/Notification → `~/.claude/pane-status.log` + macOS notification), labels in `~/.claude/pane-labels`.

## Usage

```
/multi-pane <task>        e.g. /multi-pane port feature X to 6 repos, 2 owner panes + 1 QA pane
```

## Steps

### 1. Agree scope + authority first (one short question if not given)
- Which repos / tasks, how to split, QA needed?
- **Authority for this session only** (never assume it carries over): e.g. "merge into develop allowed (admin ok)",
  "prod (main/release) is the user's", "prod DB/config changes need explicit approval".

### 2. Start the worker tmux session (main stays outside tmux)
```bash
$MP/mp-init.sh            # creates detached tmux session "mp" and opens an iTerm window attached to it
```
Tell the user: the worker window is `tmux attach -t mp` (panes are tiled, titled by label).

### 3. Pilot first, then parallel
Same change across many repos → one owner pane does a **pilot repo** first and produces a reusable patch split into
commits (shared code / per-repo theme / wiring). Then split the remaining repos across 2+ owner panes (separate repos, so no
conflicts). Add a QA pane that tests behind the owners.

```bash
P2=$($MP/mp-new.sh "2 FRONTEND · repoA,repoB" ~/Development/kol)   # prints pane id like %31
P5=$($MP/mp-new.sh "5 QA · dev" ~/Development/kol/kol-architecture)
```

### 4. Send work as a file (never type long text with send-keys)
Write the brief to a scratchpad file, then:
```bash
$MP/mp-send.sh "$P2" brief-p2.md     # pastes, presses Enter until the pane shows "esc to interrupt"
```
Every brief must contain: scope (repos/branches, worktree rule — never touch shared checkouts), constraints (tests/build,
no --no-verify, PR via /pr, don't merge), review gate (Copilot + /pr-review), and **the marker to print when done**:
- owner: `OWNER-DONE <repo>#<PR> <short result>` (or `OWNER-FIXING <repo>#<PR>`)
- QA: `QA-RESULT <repo>#<PR> PASS|FAIL <list>`
- either: `NEED-INPUT <question>` if blocked on a user decision
- long reports → "write to <file> then print the marker" (the Claude TUI has no scrollback)

### 5. Watch (background) and route
```bash
$MP/mp-watch.sh      # run_in_background: exits with new "label :: marker" lines (and [ASK] lines when a pane waits)
```
On each wake-up:
- `OWNER-DONE` → `$MP/pr-ready.sh owner/repo PR` (Copilot reviewed the head? unresolved=0? checks?) → if ready and allowed,
  merge (merge commit) → send the PR to the QA pane via `mp-send.sh`.
- `QA-RESULT … FAIL` → relay the findings to the owner pane; `PASS` → next step (e.g. open the release PR, don't merge prod).
- `[ASK]`/`NEED-INPUT` → `$MP/mp-peek.sh <pane>`; answer only within the decided scope, otherwise ask the user.
- Re-arm `mp-watch.sh` after every wake-up. A marker may be re-reported → check PR state before acting.

### 6. Report to the user in short status tables (repo | PR | review | QA | release PR), and say exactly what is waiting on them.

### 7. Wrap up
`$MP/mp-peek.sh` each pane → idle → `$MP/mp-close.sh <pane ids>`; remove worktrees that are clean+pushed
(`git worktree remove`, never rm -rf); summarize; offer to record learnings (memory / kb).

## Rules learned the hard way
- **Grey text in a pane's input box is Claude Code's prompt suggestion**, not a user command — never act on it.
- Pastes can stay unsubmitted → `mp-send.sh` retries Enter until the pane is busy ("esc to interrupt") or the input box is
  empty. Still eyeball the pane once after sending a long brief.
- **Another Claude session may already use tmux session `mp`** (and `~/.claude/pane-labels` is shared): check
  `tmux ls` first; if `mp` exists, use a task-specific session (`MP_SESSION=<task> mp-init.sh`, same env for `mp-new.sh`),
  prefix labels with a task letter (e.g. `Y1`, `Y2`), and scope the watcher to your pane ids so you don't route
  another session's markers.
- **Copilot outage** (review requested but never appears): wait 30–60 min → subagent code review + triage → note
  "Copilot did not review" in the PR. Never claim a review that did not happen.
- Before declaring "ready to merge": `pr-ready.sh` must show copilot_on_head=true (or the documented fallback),
  unresolved=0, checks pass. After merge: merge_parents=2 (release/sync PRs must be merge commits, never squash).
- Workers must not merge, release, or change prod data; the main session decides per the authority agreed in step 1.
- The main session must not bypass a worker's safety refusal by doing the same thing itself (no permission laundering).
- Panes cannot SendMessage each other reliably — the main session relays via `mp-send.sh`.

## Related
`/pr`, `/pr-review`, kb pattern `02-patterns/workflow/Multi-Pane Claude Orchestration.md`
