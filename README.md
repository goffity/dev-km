# Knowledge Management Skill for Claude Code

ระบบจัดการความรู้ 4 layers สำหรับ Claude Code CLI - inspired by [Claude-Mem](https://claude-mem.ai/) แต่เก็บไว้ใน Git repository

[![GitHub release](https://img.shields.io/github/v/release/goffity/dev-km)](https://github.com/goffity/dev-km/releases)
[![GitHub issues](https://img.shields.io/github/issues/goffity/dev-km)](https://github.com/goffity/dev-km/issues)

> **Roadmap**: ดู [ROADMAP.md](ROADMAP.md) สำหรับแผนพัฒนา
>
> **Usage Guide**: ดู [USAGE.md](USAGE.md) สำหรับคู่มือการใช้งานฉบับสมบูรณ์

## Features

- 🚀 **4-Layer System**: /mem → /distill → /td → /improve
- 📝 **Before/After Context**: จับบริบทก่อน-หลังเหมือน Claude-Mem
- 🔍 **Searchable**: ค้นหาด้วย grep, type filter
- 📁 **Git-Tracked**: Version control ทุก knowledge
- 🔧 **Portable**: ใช้ได้กับทุก AI tool ที่อ่าน markdown
- 🤖 **Auto-Capture**: บันทึก session อัตโนมัติ พร้อม AI analysis
- 📋 **Session Management**: /recap → /focus → /td workflow
- 🔗 **GitHub Integration**: สร้าง Issues + PRs อัตโนมัติ
- 🎫 **Jira Integration**: สร้าง/จัดการ Jira issues (Atlassian Cloud)
- ✅ **Code Review**: /review ก่อน push
- 🔔 **Notification Hooks**: แจ้งเตือนเมื่อ Claude ต้องการ input (รองรับ Multi-Tab Workflow)
- 🤝 **Multi-Agent Compatible**: รองรับการใช้งานร่วมกับ [multi-agent-auto-skill](https://github.com/goffity/multi-agent-auto-skill)

## Quick Start

> For detailed usage examples and workflow guides, see [USAGE.md](USAGE.md)

### Installation

```bash
# Clone to Claude skills directory
git clone https://github.com/goffity/dev-km.git ~/.claude/skills/dev-km

# Install symlinks (makes all 27 skills globally available)
bash ~/.claude/skills/dev-km/scripts/install-symlinks.sh

# Initialize in your project
cd /path/to/your/project
~/.claude/skills/dev-km/scripts/init.sh .
```

### Uninstall

```bash
bash ~/.claude/skills/dev-km/scripts/uninstall-symlinks.sh
```

## Commands

### Session Management

| Command | Purpose | Usage |
|---------|---------|-------|
| `/recap` | เริ่ม session - โหลด context เดิม | `/recap` |
| `/focus [task]` | ตั้ง focus + สร้าง issue (GitHub/Jira) | `/focus Implement feature X` |
| `/td [status]` | จบ session: สร้าง retrospective | `/td done` |

### Git & Code

| Command | Purpose | Usage |
|---------|---------|-------|
| `/commit` | Atomic commits (via TDG) | `/commit` |
| `/pr` | Test + Build + Review + Create PR + Auto-respond | `/pr` |
| `/review` | Manual code review | `/review` |
| `/pr-review` | ตอบ PR feedback | `/pr-review` |
| `/pr-poll` | จัดการ PR review polling daemon | `/pr-poll start` / `/pr-poll auto` |

### Knowledge Capture (4-Layer)

| Command | Layer | Purpose | Output |
|---------|-------|---------|--------|
| `/mem [topic]` | 1 | Quick capture ระหว่างงาน | `docs/learnings/YYYY-MM/DD/HH.MM_slug.md` |
| `/distill [topic]` | 2 | Extract patterns | `docs/knowledge-base/[topic].md` |
| `/td` | 3 | Post-task retrospective | `docs/retrospective/YYYY-MM/retrospective_*.md` |
| `/improve` | 4 | Work on pending items | Implementation |

### Knowledge & Docs

| Command | Purpose | Usage |
|---------|---------|-------|
| `/cleanup [days]` | Retention policy management | `/cleanup 30` |
| `/consolidate` | Daily session file consolidation | `/consolidate --execute` |
| `/summary [period]` | Weekly/monthly summaries | `/summary weekly` |
| `/search [query]` | Search knowledge index | `/search "auth pattern"` |
| `/example [lang] [name]` | Save code examples | `/example go retry-backoff` |
| `/flow [name]` | Process flow diagrams | `/flow deployment` |
| `/pattern [name]` | Design pattern docs | `/pattern retry-with-backoff` |
| `/share [path]` | Cross-project knowledge sharing | `/share docs/knowledge-base/topic.md` |

### Integration & Config

| Command | Purpose | Usage |
|---------|---------|-------|
| `/jira [cmd]` | Jira issue management | `/jira list PROJ` |
| `/permission` | Manage Claude Code permissions | `/permission suggest` |

> See [references/jira-integration.md](references/jira-integration.md) for full Jira documentation.

## Session Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                        SESSION START                            │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │      /recap         │
                    │  โหลด context เดิม   │
                    └─────────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │      /focus         │
                    │  ตั้งงาน + สร้าง issue │
                    └─────────────────────┘
                               │
                               ▼
              ┌────────────────────────────────┐
              │         ทำงาน                   │
              │  /mem - บันทึก insight         │
              │  /commit - atomic commits      │
              │  /review - manual code review  │
              └────────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │        /pr          │
                    │  test + build       │
                    │  code review        │
                    │  create PR          │
                    │  start auto-respond │
                    └─────────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   [Auto-Respond]    │
                    │  poll for reviews   │
                    │  Claude handles     │
                    │  feedback auto      │
                    └─────────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │        /td          │
                    │  retrospective      │
                    │  comment issue      │
                    └─────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SESSION END                              │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start Workflow

```bash
# 1. เริ่ม session
/recap                          # โหลด context + state เดิม

# 2. ตั้ง focus + สร้าง issue
/focus Implement feature X      # จะถามรายละเอียด (Overview, Technical Details, etc.)

# 3. ทำงาน...
/mem "JWT refresh pattern"      # บันทึก insight ระหว่างทาง
/commit                         # commit เมื่อเสร็จ chunk

# 4. สร้าง PR
/pr                             # test + build + review + สร้าง PR

# 5. จบ session
/td done                        # สร้าง retrospective + comment issue
```

## Knowledge Layer Workflow

```
                    ระหว่างทำงาน
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 1: /mem                                                  │
│  Quick capture → docs/learnings/YYYY-MM/DD/HH.MM_slug.md       │
└─────────────────────────────────────────────────────────────────┘
                         │
                         │ (เมื่อมี 3+ learnings เรื่องเดียวกัน)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 2: /distill                                              │
│  Extract patterns → docs/knowledge-base/topic.md               │
└─────────────────────────────────────────────────────────────────┘
                         │
                         │ (periodic review)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 4: /improve                                              │
│  Work on pending items from knowledge-base + retrospectives    │
└─────────────────────────────────────────────────────────────────┘
```

## Before/After Context

Feature เด่นจาก Claude-Mem ที่ช่วยให้เข้าใจบริบท:

```markdown
## Context: Before

- **Problem**: MongoDB timeout under load
- **Existing Behavior**: Error "context deadline exceeded" after 30s
- **Metrics**: p99 = 2s, error rate = 5%

## Context: After

- **Solution**: Connection pool + retry with exponential backoff
- **New Behavior**: Connections stable under load
- **Metrics**: p99 = 200ms, error rate < 0.1%
```

## Type Classification

ใน `/td` ระบุ type ใน frontmatter เพื่อ filter ได้ง่าย:

| Type | Use When |
|------|----------|
| `feature` | New functionality |
| `bugfix` | Bug fix |
| `refactor` | Code restructure |
| `decision` | Architecture decision |
| `discovery` | Research/learning |
| `config` | Configuration changes |
| `docs` | Documentation only |

## State Machine

```
          /focus
ready ─────────────▶ working ──/td done──▶ completed
  ▲                     │                      │
  │                     │ /td pending          │
  │ /focus new          ▼                      │
  └───────────────── pending ◀────────────────┘
                        │        /focus new task
                        │
                        │ /td blocked
                        ▼
                     blocked
```

| State | Meaning | Next Action |
|-------|---------|-------------|
| `ready` | ว่าง รอ task | `/focus` เพื่อตั้งงาน |
| `working` | กำลังทำ | `/td` เมื่อจบ |
| `pending` | รอทำต่อ | `/recap` แล้ว `/focus` |
| `blocked` | ติดปัญหา | แก้ปัญหาก่อน |
| `completed` | เสร็จแล้ว | `/focus` งานใหม่ |

## Project Directory Structure

After running `init.sh`, your project will have:

```
project/
└── docs/
    ├── current.md           # Current focus state
    ├── WIP.md               # Work in progress (paused tasks)
    ├── logs/
    │   └── activity.log     # Activity history
    ├── learnings/           # Layer 1: Quick capture (/mem)
    │   └── YYYY-MM/DD/
    ├── knowledge-base/      # Layer 2: Curated patterns (/distill)
    ├── retrospective/       # Layer 3: Full reviews (/td)
    │   └── YYYY-MM/
    ├── auto-captured/       # Auto-captured sessions
    │   └── YYYY-MM/DD/
    ├── examples/            # Code examples (/example)
    ├── summaries/           # Session summaries (/summary)
    ├── shared-knowledge/    # Cross-project knowledge (/share)
    ├── flows/               # Process flows (/flow)
    └── patterns/            # Design patterns (/pattern)
```

## Search

```bash
# Find by type
grep -l "type: bugfix" docs/retrospective/**/*.md

# Search content
grep -r "mongodb" docs/

# Recent learnings (last 7 days)
find docs/learnings -name "*.md" -mtime -7

# List all decisions
grep -l "type: decision" docs/retrospective/**/*.md
```

## Skill Structure

All 27 skills use the official Claude Code `SKILL.md` specification with YAML frontmatter.

```
dev-km/
├── SKILL.md                        # System overview (user-invocable: false)
├── skills/                         # 27 sub-skills
│   ├── mem/SKILL.md                # /mem - Quick knowledge capture
│   ├── focus/                      # /focus - Set task + create issue
│   │   ├── SKILL.md
│   │   └── jira-paths.md          # Jira integration detail
│   ├── td/                         # /td - Session retrospective
│   │   ├── SKILL.md
│   │   └── pr-commit-workflow.md
│   ├── recap/SKILL.md              # /recap - Load session context
│   ├── distill/SKILL.md            # /distill - Extract patterns
│   ├── improve/SKILL.md            # /improve - Work on pending items
│   ├── commit/SKILL.md             # /commit - Atomic commits
│   ├── pr/                         # /pr - Create PR
│   │   ├── SKILL.md
│   │   └── pr-post-create.md      # Auto-polling setup
│   ├── review/SKILL.md             # /review - Code review
│   ├── pr-review/                  # /pr-review - Handle PR feedback
│   │   ├── SKILL.md
│   │   ├── thread-resolution.md   # GraphQL thread resolve helpers
│   │   └── copilot-reviews.md     # Copilot review handling
│   ├── pr-poll/SKILL.md            # /pr-poll - PR review daemon
│   ├── cleanup/SKILL.md            # /cleanup - Retention policy
│   ├── consolidate/SKILL.md        # /consolidate - Session merger
│   ├── summary/SKILL.md            # /summary - Weekly/monthly summaries
│   ├── search/SKILL.md             # /search - Knowledge search
│   ├── jira/SKILL.md               # /jira - Jira integration
│   ├── example/SKILL.md            # /example - Code examples
│   ├── flow/SKILL.md               # /flow - Process flow docs
│   ├── pattern/SKILL.md            # /pattern - Design patterns
│   ├── share/SKILL.md              # /share - Cross-project sync
│   ├── permission/SKILL.md         # /permission - Permission management
│   ├── code-reviewer/SKILL.md      # Specialist (context: fork)
│   ├── session-analyzer/SKILL.md   # Specialist (context: fork)
│   ├── knowledge-curator/SKILL.md  # Specialist (context: fork)
│   ├── build-validator/SKILL.md    # Specialist (context: fork)
│   ├── code-simplifier/SKILL.md    # Specialist (context: fork)
│   └── security-auditor/SKILL.md   # Specialist (context: fork)
├── .claude/
│   └── settings.json               # Hook configurations
├── scripts/
│   ├── init.sh                     # Project setup script
│   ├── install-symlinks.sh         # Create 27 global symlinks
│   ├── uninstall-symlinks.sh       # Clean removal
│   ├── auto-capture.sh             # Auto session capture
│   ├── notify.sh                   # macOS notification script
│   └── ...
├── references/                     # Templates
├── assets/commands/                # Command source files (reference)
└── docs/                           # Knowledge data
```

## Issue Tracker Integration

`/focus` รองรับทั้ง GitHub Issues และ Jira:

### Supported Trackers

| Tracker | Setup | Usage |
|---------|-------|-------|
| GitHub Issues | ไม่ต้องตั้งค่า (ใช้ gh CLI) | Default option |
| Jira | `/jira init` ครั้งแรก | เลือกเมื่อรัน `/focus` |

### `/focus` Workflow

```
/focus [task description]
     │
     ├── ถ้ามี Jira config ──→ เลือก: GitHub / Jira (new) / Jira (existing)
     │
     └── ถ้าไม่มี Jira ──→ ใช้ GitHub Issues (default)
```

### Jira Setup

```bash
# 1. สร้าง API Token ที่ https://id.atlassian.com/manage-profile/security/api-tokens

# 2. ตั้งค่า credentials
/jira init

# 3. ทดสอบ connection
/jira test
```

> See [references/jira-integration.md](references/jira-integration.md) for full Jira documentation.

## GitHub Integration

`/focus` และ `/td` integrate กับ GitHub โดยอัตโนมัติ:

### Issue Format (/focus)

```markdown
## Overview
Brief description of the feature/bug.

## Current State
What exists now.

## Proposed Solution
What should be implemented.

## Technical Details
- Components affected
- Implementation approach

## Acceptance Criteria
- [ ] Specific testable criteria
- [ ] Performance requirements
```

### PR Format (/td)

```markdown
## Summary
Brief summary of the changes made.

## Changes Made
- List of key changes.

## Testing
- Description of tests performed.

## Related Issues
- #issue_number

Fixes #issue_number
```

### Pre-Push Checklist (via /pr)

| Check | Command | Required |
|-------|---------|----------|
| Tests | `make test` | Must pass |
| Build | `make build` | Must pass |
| Code Review | Subagent | No critical issues |

**Note:** `/pr` จะรันทุกขั้นตอนนี้ให้อัตโนมัติพร้อม update issue ทุก step

### PR Review Auto-Respond

หลังจาก `/pr` สร้าง PR เสร็จ จะ auto-start polling daemon ที่จัดการ reviews อัตโนมัติ:

```
/pr สร้าง PR เสร็จ
        ↓
Start PR Poll Daemon (--auto-respond)
        ↓
[รอ reviewer...]
        ↓
เมื่อมี review → Daemon ตรวจจับ
        ↓
Spawn Claude CLI → run /pr-review อัตโนมัติ
        ↓
แก้ code, reply comments, push changes
```

| Event | Action |
|-------|--------|
| PR Approved | Notification (Glass sound) |
| Changes Requested | Claude auto-responds |
| Reviewer Comments | Claude auto-responds |

**Commands:**

```bash
# ดูสถานะ daemon
/pr-poll status

# หยุด auto-respond
/pr-poll stop

# ดู Claude logs
tail -f ~/.pr-review-claude-*.log
```

### Forbidden Actions

| Action | Reason |
|--------|--------|
| Merge PR | ต้องรอ reviewer approve |
| Close Issue | จะปิดอัตโนมัติเมื่อ PR merge |
| Force Push | อันตราย ห้ามใช้ |
| Skip Tests | ต้อง pass ก่อน push |

## Why Not Claude-Mem?

| Feature | Claude-Mem | This Skill |
|---------|------------|------------|
| Auto-capture | ✅ Automatic | ✅ Hooks/Wrapper/AI |
| Git tracked | ❌ | ✅ |
| Portable | ❌ Claude Code only | ✅ Any tool |
| Editable | Limited | ✅ Full control |
| Structure | Fixed | ✅ Customizable |
| Dependency | Plugin required | ✅ Just markdown |
| GitHub Integration | ❌ | ✅ Issues + PRs |

## Notification Hooks (Multi-Tab Workflow)

รองรับการทำงานแบบ Multi-Tab ตามแนวทางของ Boris Cherny (ผู้สร้าง Claude Code) - เปิดหลาย terminal tabs พร้อมกัน และรับ notification เมื่อ tab ใดต้องการ input

### Notification Types

| Type | เมื่อไหร่ | Sound |
|------|----------|-------|
| `idle_prompt` | Claude รอ input นานเกิน 60 วินาที | Ping |
| `permission_prompt` | ต้องการ permission | Basso |
| `elicitation_dialog` | MCP tool ต้องการข้อมูลเพิ่ม | Purr |

### Setup

เพิ่มใน `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [{
          "type": "command",
          "command": "~/.claude/skills/dev-km/scripts/notify.sh"
        }]
      },
      {
        "matcher": "permission_prompt",
        "hooks": [{
          "type": "command",
          "command": "~/.claude/skills/dev-km/scripts/notify.sh"
        }]
      },
      {
        "matcher": "elicitation_dialog",
        "hooks": [{
          "type": "command",
          "command": "~/.claude/skills/dev-km/scripts/notify.sh"
        }]
      }
    ]
  }
}
```

### Multi-Tab Workflow

```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  Tab 1  │  │  Tab 2  │  │  Tab 3  │  │  Tab 4  │  │  Tab 5  │
│ Feature │  │ Bug Fix │  │Refactor │  │  Tests  │  │  Docs   │
└────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
     │            │            │            │            │
     └────────────┴─────┬──────┴────────────┴────────────┘
                        │
                        ▼
              🔔 macOS Notification
              "Tab X needs your input"
                        │
                        ▼
                 สลับไป Tab นั้น
```

### ใช้ร่วมกับ Git Worktrees

```bash
# สร้าง worktree สำหรับแต่ละ tab
git worktree add ../project-feature-a -b feature-a
git worktree add ../project-bugfix -b bugfix-123

# Tab 1: cd ../project-feature-a && claude
# Tab 2: cd ../project-bugfix && claude
```

### Test Notification

```bash
echo '{"notification_type": "idle_prompt", "cwd": "/test"}' | \
  ~/.claude/skills/dev-km/scripts/notify.sh
```

### Optional: terminal-notifier

สำหรับ notification ที่ดีกว่า (clickable, groupable):

```bash
brew install terminal-notifier
```

---

## Auto-Capture

บันทึก session อัตโนมัติเมื่อจบงาน - 3 options:

### Option 1: Hooks (Recommended)

```bash
# Add to ~/.claude/settings.json
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "[ ! -f docs/retrospective/$(date +%Y-%m)/retrospective_$(date +%Y-%m-%d)_*.md ] && ~/.claude/skills/dev-km/scripts/auto-capture.sh . 2>/dev/null || true"
      }]
    }]
  }
}
```

> Note: Duplicate check prevents multiple captures on the same day.

### Option 2: Wrapper

```bash
# Add alias
alias claude='~/.claude/skills/dev-km/scripts/claude-wrap.sh'

# Usage - shows summary and asks to capture
claude
```

### Option 3: AI-Powered

```bash
export ANTHROPIC_API_KEY='your-key'
./scripts/ai-capture.sh .
```

**Output**: `docs/auto-captured/YYYY-MM/DD/HH.MM_session-*.md`

See [AUTO-CAPTURE.md](AUTO-CAPTURE.md) for full documentation.

## Security

สคริปต์ทั้งหมดมีการป้องกันความปลอดภัย:

### Path Validation

ป้องกัน path traversal attacks - ทุกสคริปต์ตรวจสอบ path ก่อนใช้งาน:

```bash
# ❌ จะถูก reject
./init.sh "../../../etc"
./auto-capture.sh "../../sensitive"

# ✅ ใช้งานได้
./init.sh .
./init.sh /path/to/project
```

### Input Sanitization

`notify.sh` sanitize ทุก input ก่อนส่งให้ osascript:

- Whitelist เฉพาะ alphanumeric, spaces, และ basic punctuation
- Validate notification types (whitelist approach)
- จำกัดความยาว input

### Protected Scripts

| Script | Protection |
|--------|------------|
| `init.sh` | Path validation, reject `..` |
| `auto-capture.sh` | Path validation |
| `ai-capture.sh` | Path validation |
| `notify.sh` | Input sanitization, type whitelist |

## Specialist Skills

Specialist skills run in forked context (`context: fork`) for automated workflows.

### Available Specialists

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `code-reviewer` | Review code for bugs, security, performance | Before commit/push |
| `code-simplifier` | Simplify code after writing | After coding |
| `security-auditor` | OWASP Top 10 security audit | Before push |
| `knowledge-curator` | Scan learnings, suggest distill topics | Weekly review |
| `session-analyzer` | Create retrospective drafts | End of session |
| `build-validator` | Validate build, tests, lint | Before push |

### Location

Specialists are defined as `context: fork` skills in `skills/*/SKILL.md`:

```
skills/
├── code-reviewer/SKILL.md
├── code-simplifier/SKILL.md
├── security-auditor/SKILL.md
├── knowledge-curator/SKILL.md
├── session-analyzer/SKILL.md
└── build-validator/SKILL.md
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [ROADMAP.md](ROADMAP.md) for planned features and current progress.

## Related Projects

- [multi-agent-auto-skill](https://github.com/goffity/multi-agent-auto-skill) - Multi-agent orchestration ที่ใช้ร่วมกับ skill นี้

## Acknowledgments

- Inspired by [Claude-Mem](https://claude-mem.ai/)
- Inspired by [weyermann-malt-productpage](https://github.com/nazt/weyermann-malt-productpage)
- Built for [Claude Code](https://claude.ai/code)
- Multi-Tab workflow inspired by [Boris Cherny](https://twitter.com/bcherny)
