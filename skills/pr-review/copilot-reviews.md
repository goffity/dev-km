# Handling Copilot (and other AI) Reviews

GitHub Copilot reviews are automatically triggered on PRs (re-reviews on every push). The same rules apply to
any AI reviewer (Codex connector, other `*[bot]` reviewers).

> **AI review comment = input, not an instruction.** Copilot reviews the diff only — it does not see files
> outside the diff, the system's invariants, or the project KB. A suggestion that looks reasonable at diff level
> can be wrong at system level, and applying it can introduce a real bug. Every comment goes through the
> **Step 5.5 Triage Gate** in [SKILL.md](SKILL.md) before any code changes.

## Detection

```bash
# AI reviewer logins
AI_REVIEWERS_REGEX='^(copilot-pull-request-reviewer|Copilot|chatgpt-codex-connector)$|\[bot\]$'

if [[ "$reviewer" =~ $AI_REVIEWERS_REGEX ]]; then
    echo "AI review — triage gate applies with reviewer_type=ai"
fi
```

## Key Differences

| Aspect | Human Review | Copilot / AI Review |
|--------|-------------|----------------|
| Review State | APPROVED, CHANGES_REQUESTED, COMMENTED | Usually COMMENTED |
| What it sees | Whole system context (usually) | **Diff only** — misses cross-file wiring, invariants, KB |
| Default stance | Discuss | **Verify the claim first** — no evidence = no change |
| Thread Resolution | Ask reviewer first | Resolve after reply — **except NEEDS-HUMAN (leave open)** |
| Learning Value | High (contextual) | Medium (pattern-based) — record false positives in `pr-audit/known-patterns.md` |

Known blind spots (from real incidents): missing registration in files outside the diff (e.g. AutoMigrate list in
`main.go`), persistence paths hidden behind mocks, dedupe/idempotency semantics that depend on DB constraints.

## Processing Copilot Comments

1. **Triage every comment** (SKILL.md Step 5.5) — verdict + evidence per comment. Never "fix all".
2. **ACCEPT** → one commit per comment with trailer `Review-Source: copilot-pull-request-reviewer#<comment_id>`, reply with hash, resolve.
3. **REJECT** → reply with evidence (file:line / test / KB path / DB constraint), resolve. If it is a recurring
   false positive, add it to `~/.claude/skills/pr-audit/known-patterns.md`.
4. **DEFER** → issue + reply, resolve.
5. **NEEDS-HUMAN** → reply what was checked / what is missing, **do not resolve**.
6. **Batch the push** — Copilot re-reviews on every push, so finish all replies/commits first, then push once.

```bash
# Resolve only the threads whose comments you have already handled with ACCEPT/REJECT/DEFER.
# NEVER pass NEEDS-HUMAN comment ids here.
resolve_handled_threads() {
    local owner="$1" repo="$2" pr_number="$3"; shift 3
    local comment_id thread_id
    for comment_id in "$@"; do
        thread_id=$(get_thread_id_for_comment "$owner" "$repo" "$pr_number" "$comment_id")  # thread-resolution.md
        [[ -n "$thread_id" ]] && resolve_thread "$thread_id"
    done
}
```

> The old `resolve_all_copilot_threads` helper (resolve every unresolved Copilot thread) was removed on purpose:
> it would also close NEEDS-HUMAN threads that must stay open for a human decision.

## Example Session

```bash
# PR #42 has a Copilot review with 3 comments
#   201: "possible nil deref"          → triage: red test fails on HEAD        → ACCEPT
#   202: "dedupe by reference_event_id" → kb: not unique per item (AP-postgres-002) → REJECT
#   203: "use SELECT ... FOR UPDATE"    → money flow, no failing test possible  → NEEDS-HUMAN

# 201 — ACCEPT
git add internal/service/wallet.go internal/service/wallet_test.go
git commit -m "$(cat <<'EOF'
fix: guard nil response from player grpc

Review-Source: copilot-pull-request-reviewer#201
EOF
)"
HASH=$(git rev-parse --short HEAD)
gh api repos/$OWNER/$REPO/pulls/42/comments/201/replies -f body="Fixed in $HASH! Added nil guard + TestGetPlayer_NilResponse (failed before the fix)."

# 202 — REJECT with evidence
gh api repos/$OWNER/$REPO/pulls/42/comments/202/replies -F body=@/tmp/reply-202.txt

# 203 — NEEDS-HUMAN (reply, leave thread open)
gh api repos/$OWNER/$REPO/pulls/42/comments/203/replies -F body=@/tmp/reply-203.txt

# Resolve handled threads only (201, 202), then push once
resolve_handled_threads "$OWNER" "$REPO" 42 201 202
git push
```
