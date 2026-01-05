# Knowledge Management Skill for Claude Code

ระบบจัดการความรู้ 4 layers สำหรับ Claude Code CLI - inspired by [Claude-Mem](https://claude-mem.ai/) แต่เก็บไว้ใน Git repository

## Features

- 🚀 **4-Layer System**: /mem → /distill → /td → /improve
- 📝 **Before/After Context**: จับบริบทก่อน-หลังเหมือน Claude-Mem
- 🔍 **Searchable**: ค้นหาด้วย grep, type filter
- 📁 **Git-Tracked**: Version control ทุก knowledge
- 🔧 **Portable**: ใช้ได้กับทุก AI tool ที่อ่าน markdown
- 🤖 **Auto-Capture**: บันทึก session อัตโนมัติ พร้อม AI analysis
- 📋 **Session Management**: /recap → /focus → /td workflow
- 🔗 **GitHub Integration**: สร้าง Issues + PRs อัตโนมัติ
- ✅ **Code Review**: /review ก่อน push

## Quick Start

### Installation

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/knowledge-management-skill.git

# Copy to Claude skills directory
cp -r knowledge-management-skill ~/.claude/skills/

# Or install in your project
cd /path/to/your/project
~/.claude/skills/knowledge-management-skill/scripts/init.sh .
```

### Manual Setup

```bash
# Create directories
mkdir -p .claude/commands
mkdir -p docs/{learnings,knowledge-base,retrospective}

# Copy command files
cp ~/.claude/skills/knowledge-management-skill/assets/commands/*.md .claude/commands/
```

## Commands

### Session Management

| Command | Purpose | Usage |
|---------|---------|-------|
| `/recap` | เริ่ม session - โหลด context เดิม | `/recap` |
| `/focus [task]` | ตั้ง focus + สร้าง GitHub issue | `/focus Implement feature X` |
| `/td [status]` | จบ session: test + review + PR | `/td done` |

### Git & Code

| Command | Purpose | Usage |
|---------|---------|-------|
| `/commit` | Atomic commits (via TDG) | `/commit` |
| `/review` | Manual code review | `/review` |

### Knowledge Capture (4-Layer)

| Command | Layer | Purpose | Output |
|---------|-------|---------|--------|
| `/mem [topic]` | 1 | Quick capture ระหว่างงาน | `docs/learnings/YYYY-MM/DD/HH.MM_slug.md` |
| `/distill [topic]` | 2 | Extract patterns | `docs/knowledge-base/[topic].md` |
| `/td` | 3 | Post-task retrospective | `docs/retrospective/YYYY-MM/retrospective_*.md` |
| `/improve` | 4 | Work on pending items | Implementation |

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
                    │        /td          │
                    │  test + review      │
                    │  comment issue      │
                    │  create PR          │
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

# 4. จบ session
/td done                        # test + review + comment issue + สร้าง PR
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

## Directory Structure

```
project/
├── .claude/
│   └── commands/
│       ├── mem.md
│       ├── distill.md
│       ├── td.md
│       ├── improve.md
│       ├── commit.md
│       ├── focus.md        # NEW: Set focus + create issue
│       ├── recap.md        # NEW: Session context recovery
│       └── review.md       # NEW: Code review
└── docs/
    ├── current.md           # Current focus state
    ├── WIP.md               # Work in progress (paused tasks)
    ├── logs/
    │   └── activity.log     # Activity history
    ├── learnings/           # Layer 1: Quick capture
    │   └── YYYY-MM/
    │       └── DD/
    │           └── HH.MM_slug.md
    ├── knowledge-base/      # Layer 2: Curated patterns
    │   └── [topic].md
    ├── retrospective/       # Layer 3: Full reviews
    │   └── YYYY-MM/
    │       └── retrospective_YYYY-MM-DD_hhmmss.md
    └── auto-captured/       # Auto-captured sessions
        └── YYYY-MM/
            └── DD/
                └── HH.MM_session-*.md
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

```
knowledge-management-skill/
├── SKILL.md                    # Main skill definition
├── scripts/
│   └── init.sh                 # Project setup script
├── references/
│   ├── mem-template.md         # Full /mem template
│   ├── distill-template.md     # Full /distill template
│   ├── td-template.md          # Full /td template
│   └── improve-workflow.md     # /improve workflow
└── assets/
    └── commands/               # Slash command files
        ├── README.md           # Commands documentation
        ├── mem.md
        ├── distill.md
        ├── td.md
        ├── improve.md
        ├── commit.md
        ├── focus.md            # NEW
        ├── recap.md            # NEW
        └── review.md           # NEW
```

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

### Pre-Push Checklist

| Check | Command | Required |
|-------|---------|----------|
| Tests | `make test` | Must pass |
| Build | `make build` | Must pass |
| Code Review | `/review` | No critical issues |

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
        "command": "[ ! -f docs/retrospective/$(date +%Y-%m)/retrospective_$(date +%Y-%m-%d)_*.md ] && ~/.claude/skills/knowledge-management/scripts/auto-capture.sh . 2>/dev/null || true"
      }]
    }]
  }
}
```

> Note: Duplicate check prevents multiple captures on the same day.

### Option 2: Wrapper

```bash
# Add alias
alias claude='~/.claude/skills/knowledge-management/scripts/claude-wrap.sh'

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

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- Inspired by [Claude-Mem](https://claude-mem.ai/)
- Inspired by [weyermann-malt-productpage](https://github.com/nazt/weyermann-malt-productpage)
- Built for [Claude Code](https://claude.ai/code)
