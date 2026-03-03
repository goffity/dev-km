# Post PR Creation

Steps to execute after PR is created successfully.

> **Language:** Follow the language setting from `docs/current.md` as described in the parent `/pr` skill. If `LANGUAGE: th`, generate confirmation and status text in Thai per `references/language-guide.md`.

## Step 5.5: Start PR Review Polling with Auto-Respond

**Auto-start polling daemon พร้อม auto-respond - Claude จะจัดการ review อัตโนมัติ:**

```bash
# Get script directory and working directory
SKILL_DIR="${HOME}/.claude/skills/dev-km"
WORKING_DIR="$(pwd)"

# Check if daemon already running
PID_FILE="${HOME}/.pr-review-poll.pid"
if [[ -f "$PID_FILE" ]] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
    echo "PR polling daemon already running"
else
    # Start polling daemon with auto-respond
    if [[ -x "${SKILL_DIR}/scripts/pr-review-poll-start.sh" ]]; then
        "${SKILL_DIR}/scripts/pr-review-poll-start.sh" \
            --interval 300 \
            --auto-respond \
            --working-dir "$WORKING_DIR" 2>/dev/null || true
        echo "Started PR review polling with auto-respond (5 min interval)"
        echo "  Claude will automatically handle reviews when they come in"
        echo "  Working dir: $WORKING_DIR"
    fi
fi
```

**Note:**
- Polling daemon จะตรวจสอบ PR reviews ทุก 5 นาที
- เมื่อมี review ใหม่ Claude CLI จะถูก spawn อัตโนมัติเพื่อ run `/pr-review`
- ใช้ `/pr-poll stop` เพื่อหยุด daemon
- ใช้ `/pr-poll status` เพื่อดูสถานะ
- Log ของ Claude sessions: `~/.pr-review-claude-*.log`

## Step 6: Confirm

```markdown
## PR Created Successfully

### Summary

| Check | Status |
|-------|--------|
| Tests | Passed |
| Build | Passed |
| Code Review | Passed |
| PR Created | Done |
| Review Polling | Active |

**Issue:** #[issue-number]
**PR:** [pr-url]

### Auto-Respond Active

PR review polling with auto-respond is now active:
- When reviewer **approves**: Notification (Glass sound)
- When **changes requested**: Claude spawns `/pr-review` automatically
- When reviewer **comments**: Claude spawns `/pr-review` automatically

Claude will automatically:
1. Analyze review feedback
2. Fix code issues
3. Reply to comments
4. Push changes

Use `/pr-poll stop` to disable auto-respond.
View Claude logs: `tail -f ~/.pr-review-claude-*.log`

### Important Reminders

- ห้าม merge PR เอง - รอ reviewer approve
- ห้ามปิด issue เอง - จะปิดอัตโนมัติเมื่อ PR ถูก merge

### Next Steps
1. รอ reviewer approve PR (Claude จะจัดการ feedback อัตโนมัติ)
2. ตรวจสอบ Claude logs: `tail -f ~/.pr-review-claude-*.log`
3. ใช้ `/pr-review` ด้วยตนเองหากต้องการควบคุม
4. ใช้ `/td` เพื่อสร้าง retrospective
5. ใช้ `/focus` เพื่อเริ่มงานใหม่
```

## Flow Summary

```
┌─────────────────────────────────────────────────────────┐
│                        /pr                               │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────┐                                           │
│  │make test │──fail──→ Comment Issue → Stop             │
│  └────┬─────┘          (user fixes & reruns /pr)        │
│       │pass                                              │
│       ▼                                                  │
│  ┌──────────┐                                           │
│  │make build│──fail──→ Comment Issue → Stop             │
│  └────┬─────┘          (user fixes & reruns /pr)        │
│       │pass                                              │
│       ▼                                                  │
│  ┌───────────────┐                                      │
│  │ Code Review   │──fail──→ Comment Issue               │
│  │  (subagent)   │              │                       │
│  └───────┬───────┘              ▼                       │
│          │              ┌───────────────┐               │
│          │              │ Agent Auto-fix│               │
│          │              └───────┬───────┘               │
│          │                      │                       │
│          │              Comment Issue                   │
│          │                      │                       │
│          │              ◄───────┘ (re-review)           │
│          │pass                                          │
│          ▼                                              │
│  ┌──────────┐                                           │
│  │ git push │                                           │
│  └────┬─────┘                                           │
│       ▼                                                  │
│  ┌──────────┐                                           │
│  │Create PR │──→ Comment Issue                          │
│  └──────────┘                                           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Issue Comments Timeline

| Step | Comment |
|------|---------|
| Test Start | Running Tests |
| Test Pass | Tests Passed |
| Test Fail | Tests Failed |
| Build Pass | Build Passed |
| Build Fail | Build Failed |
| Review Start | Code Review Started |
| Review Pass | Code Review Passed |
| Review Fail | Code Review Failed |
| Auto-fix | Auto-fix Applied |
| PR Created | Pull Request Created |
