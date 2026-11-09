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
# code-changing worker: its own worktree + ticket branch (never the shared checkout)
P1=$($MP/mp-new.sh "1 BE · kol-report RUAYS-2402" ~/Development/kol/kol-report --ticket RUAYS-2402 --slug "root win loss report")
P2=$($MP/mp-new.sh "2 FRONTEND · repoA,repoB" ~/Development/kol)   # multi-repo owner: brief says which worktree per repo
P5=$($MP/mp-new.sh "5 QA · dev" ~/Development/kol/kol-architecture)  # read-only/QA may use the shared checkout
```

**Branch setup is the main session's job, not the worker's.** `--ticket KEY-123` runs `mp-worktree.sh`: it reuses the
ticket's worktree/branch if one exists, otherwise fetches and creates `<repo>-wt-<number>` on `feat/KEY-123-<slug>` from
`origin/develop` (or `--base <ref>`), and opens the worker there. Without `--ticket`, `mp-new.sh` warns when the pane opens in
a shared checkout — a worker there inherits whatever branch that checkout is on (e.g. an old merged feature branch). For a
multi-repo owner pane, prepare one worktree per repo yourself (`$MP/mp-worktree.sh <repo> KEY-123`) and list the paths in the
brief. Untracked files a repo needs to build (e.g. `.env`, `.tool-versions`) are not copied — say so in the brief.

### 4. Send work as a file (never type long text with send-keys)
Write the brief to a scratchpad file, then:
```bash
$MP/mp-send.sh "$P2" brief-p2.md     # pastes, presses Enter until the pane shows "esc to interrupt"
```
Every brief must contain: scope (repos, **the exact worktree path + branch per repo** — never touch shared checkouts),
**first action: `git branch --show-current` in each worktree; if it is not the stated branch, print `NEED-INPUT wrong branch
<repo>: <actual>` and stop**, constraints (tests/build, no --no-verify, PR via /pr, don't merge), review gate
(Copilot + /pr-review), and **the marker to print when done**:
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
- Pastes can stay unsubmitted → `mp-send.sh` retries Enter and checks "esc to interrupt".
- **Copilot outage** (review requested but never appears): wait 30–60 min → subagent code review + triage → note
  "Copilot did not review" in the PR. Never claim a review that did not happen.
- Before declaring "ready to merge": `pr-ready.sh` must show copilot_on_head=true (or the documented fallback),
  unresolved=0, checks pass. After merge: merge_parents=2 (release/sync PRs must be merge commits, never squash).
- Workers must not merge, release, or change prod data; the main session decides per the authority agreed in step 1.
- **Never start a code-changing worker in a shared checkout** — it picks up that checkout's current branch. A worker on
  `feat/RUAYS-2036-…` (already merged) was given RUAYS-2402 work this way. Use `mp-new.sh --ticket`; fix a worker on the
  wrong branch from the main session (new worktree via `mp-worktree.sh`, then brief it to move), not by letting it switch
  branches in the shared checkout.
- The main session must not bypass a worker's safety refusal by doing the same thing itself (no permission laundering).
- Panes cannot SendMessage each other reliably — the main session relays via `mp-send.sh`.

## Related
`/pr`, `/pr-review`, kb pattern `02-patterns/workflow/Multi-Pane Claude Orchestration.md`
