---
name: jira
description: Manages Jira issues including creation, listing, transitions, and workflow integration.
argument-hint: "[command] [arguments]"
user-invocable: true
---

# Jira Integration

จัดการ Jira issues ผ่าน CLI รองรับ Atlassian Cloud

## Usage

```
/jira [command] [arguments]
```

## Available Commands

| Command | Description |
|---------|-------------|
| `/jira init` | ตั้งค่า Jira credentials |
| `/jira test` | ทดสอบ connection |
| `/jira list` | แสดง issues ใน project |
| `/jira my` | แสดง issues ที่ assign ให้ฉัน |
| `/jira get <key>` | ดู issue details |
| `/jira create` | สร้าง issue ใหม่ (Bug → ใช้ `create-bug`) |
| `/jira create-bug` | สร้าง Bug พร้อม template + kb/00-inbox note |
| `/jira create-story` | สร้าง Story พร้อม template |
| `/jira create-epic` | สร้าง Epic พร้อม template |
| `/jira create-subtask-templated` | สร้าง Subtask พร้อม template และ dependency links |
| `/jira search <query>` | ค้นหา issues |
| `/jira transitions <key>` | ดู transitions ที่ทำได้ |
| `/jira transition <key> <id>` | เปลี่ยน status ด้วย transition ID |
| `/jira comment <key>` | เพิ่ม comment |
| `/jira add-labels <key>` | เพิ่ม labels |
| `/jira link <type>` | สร้าง dependency link |

## Instructions

### Command: init

ตั้งค่า Jira credentials

```bash
./scripts/jira-client.sh init
```

**หลังจาก init สำเร็จ:**
```
Jira configured successfully!

ใช้ /jira test เพื่อทดสอบ connection
```

### Command: test

ทดสอบ connection กับ Jira

```bash
./scripts/jira-client.sh test
```

**Output:**
```
Testing connection to [domain]...
Connected as: [name] ([email])
```

### Command: list

แสดง issues ใน project

```bash
# Default project
./scripts/jira-client.sh list

# Specific project
./scripts/jira-client.sh list PROJ

# Filter by status
./scripts/jira-client.sh list PROJ "In Progress"
```

**แสดงผลในรูปแบบ table:**
```
KEY        STATUS       SUMMARY
PROJ-123   To Do        Fix login bug
PROJ-124   In Progress  Add search feature
PROJ-125   Done         Update docs
```

### Command: my

แสดง issues ที่ assign ให้ user

```bash
./scripts/jira-client.sh my-issues

# Filter by status
./scripts/jira-client.sh my-issues "To Do"
```

### Command: get

ดู issue details

```bash
./scripts/jira-client.sh get PROJ-123
```

**แสดงผล:**
```json
{
  "key": "PROJ-123",
  "summary": "Fix login bug",
  "status": "In Progress",
  "type": "Bug",
  "priority": "High",
  "assignee": "John Doe",
  "url": "https://company.atlassian.net/browse/PROJ-123"
}
```

### Command: create

สร้าง Jira issue ใหม่ (interactive)

**Step 1: ถามข้อมูล issue**

ใช้ AskUserQuestion:

```
สร้าง Jira Issue

1. Project Key (e.g., PROJ)
2. Issue Type (Task, Bug, Story, Epic)
3. Summary (หัวข้อ)
4. Description (รายละเอียด)
5. Priority (Highest, High, Medium, Low, Lowest)
```

> **Issue Type = Bug → ห้ามใช้ `create ... Bug`** ให้ไปที่ [Command: create-bug](#command-create-bug) แทน
> (template ของ Bug + Acceptance Criteria + kb note ถูกบังคับที่นั่น)

**Step 2: สร้าง issue**

```bash
./scripts/jira-client.sh create "[PROJECT]" "[SUMMARY]" "[DESCRIPTION]" "[TYPE]"
```

**Step 3: แสดงผล**

```
Issue Created!

Key: PROJ-123
URL: https://company.atlassian.net/browse/PROJ-123
Summary: [summary]
Type: [type]

ใช้ /focus แล้วเลือก "Jira (existing)" เพื่อเริ่มทำงาน
```

**Step 4: kb note** — ticket ทุกใบที่สร้าง (ไม่ใช่แค่ Bug) ต้องมี note ที่ `kb/00-inbox/YYYY-MM-DD <KEY> <system> - <title>.md` ด้วย (`create-bug` เขียนให้อัตโนมัติ, type อื่นเขียนเองตาม format เดียวกัน)

### Command: create-bug

สร้าง Bug ticket พร้อม Bug template และเขียน kb/00-inbox note ให้อัตโนมัติ — **Bug ทุกใบต้องสร้างผ่านคำสั่งนี้** ไม่ใช้ `create ... Bug`

> สร้างผ่าน `jira-client.sh create-bug` เท่านั้น ห้ามยิง Jira API ตรงๆ เพื่อสร้าง Bug (จะไม่ได้ template และ kb note)

```bash
./scripts/jira-client.sh create-bug <project> <summary> [description|@file] \
  [--labels L1,L2] [--assign me|accountId] [--points N] \
  [--root-cause text|@file] [--root-cause-in-ticket] \
  [--system name] [--kb-dir path] [--no-kb]
```

**Options:**
- `description|@file` - ไม่ใส่ = เติม Bug template เปล่าให้ (`@file` = อ่านจากไฟล์ markdown)
- `--labels L1,L2` - labels (comma-separated)
- `--assign me|accountId` - assign
- `--points N` - story points
- `--root-cause text|@file` - ต้นเหตุ → เขียนลง kb note เท่านั้น
- `--root-cause-in-ticket` - ใส่ต้นเหตุเป็น section `## ต้นเหตุ` ท้าย ticket ด้วย (ต้องมี `--root-cause`) — **ใช้เฉพาะเมื่อ user ขอชัดเจน**
- `--system name` - ชื่อ system ในชื่อไฟล์ kb note (default = repo จาก prefix `[repo]` ของ summary ตัด `kol-` ออก, ไม่มี prefix = `general`)
- `--kb-dir path` - ตำแหน่ง kb (default = `$KB_DIR` หรือ `<script-dir>/../kb`)
- `--no-kb` - ไม่เขียน kb note (ไม่ใช้ เว้นแต่ user สั่ง)

**Template Sections (description ต้องมีครบตามลำดับนี้):**
- ปัญหา - ผู้ใช้เห็นอะไร หน้าไหน agent/แบรนด์ไหน เมื่อไร + id/ภาพหน้าจอ
- ขั้นตอนทำซ้ำ - ขั้นตอนเป็นข้อๆ
- ผลที่ได้ - สิ่งที่เกิดขึ้นจริง (actual)
- ผลที่ควรเป็น - สิ่งที่ควรเกิดขึ้น (expected)
- ผลกระทบ - กระทบเงิน/รายงาน/ผู้ใช้กี่ราย กี่แบรนด์ ช่วงเวลาไหน
- ที่ต้องการ - ขอบเขตที่ต้องแก้
- Acceptance Criteria - checklist ที่ **QA ตรวจได้** รูปแบบ "เมื่อ … แล้ว …" (ไม่ใช่ todo list ของ dev เช่น "แก้ฟังก์ชัน X")
- Out of scope - สิ่งที่ไม่ทำในใบนี้ + link ใบที่เกี่ยวข้อง
- ทดสอบ - environment, ข้อมูลทดสอบ, rollback ถ้าแตะเงินหรือข้อมูล

> ถ้าส่ง description เอง ต้องใช้หัวข้อชุดเดียวกันนี้ และเติมเนื้อหาจริงทุกหัวข้อ (โดยเฉพาะ expected vs actual และ AC) — อย่าส่ง template ที่ยังมี placeholder `[...]` ค้างอยู่

**kb note (อัตโนมัติ):**
- ทุก ticket ที่สร้าง → มี note ที่ `kb/00-inbox/YYYY-MM-DD <KEY> <system> - <title>.md` (title = summary ที่ตัด `[repo]` prefix ออก)
- frontmatter: `tags: [inbox, bug, <labels>]`, `type: idea`, `jira: <KEY>`, `status: backlog`
- section `## ต้นเหตุ` = ค่าจาก `--root-cause` หรือ "ยังไม่ทราบ — เติมเมื่อพบ" ถ้าไม่ระบุ, ตามด้วย `## รายละเอียดตอนเปิด ticket` (สำเนา description)
- **ต้นเหตุอยู่ที่ kb note ไม่ใช่ ticket** (ค่าเริ่มต้น) — ใส่ใน ticket เฉพาะ `--root-cause-in-ticket` เมื่อ user ขอ
- ticket สร้างแล้วแต่ note fail → ได้ warning (ticket ไม่ถูกลบ) ต้องเขียน note เองตาม format เดิม
- note อยู่ใน kol-brain repo (`kb/` symlink) → commit/push ที่ kol-brain

**Conventions:**
- Summary: งาน single-repo ขึ้นต้น `[repo-name]` + ชื่อเรื่องภาษาไทยขึ้นต้นด้วยคำกริยา เช่น `[kol-wallet] แก้ยอดฝากซ้ำเมื่อ callback มาซ้ำ`
- Labels: lowercase ชื่อ service + หมวด (เช่น `kol-wallet,bug`) + label กลุ่มร่วมกันสำหรับ ticket ที่เกี่ยวข้องกัน · ห้ามใช้ label กว้างๆ อย่าง `Backend` / `Frontend`
- Bug ข้ามหลาย repo: สร้าง **parent Bug 1 ใบ** (อาการที่ผู้ใช้เห็น ปิดได้เมื่อ child ทุกใบขึ้นแล้ว + QA ผ่าน) + ticket ต่อ repo แล้ว link ด้วย `link blocks <child> <parent>`

**Example:**

```bash
# เขียน description ตาม template ลงไฟล์ก่อน แล้วส่งเป็น @file
./scripts/jira-client.sh create-bug RUAYS "[kol-wallet] แก้ยอดฝากเข้าซ้ำเมื่อ gateway ส่ง callback ซ้ำ" @/tmp/bug-desc.md \
  --labels kol-wallet,bug,deposit-callback \
  --root-cause "ยังไม่ทราบ"

# Bug ข้าม repo: parent + child แล้ว link
./scripts/jira-client.sh create-bug RUAYS "แก้ยอดฝากเข้าซ้ำเมื่อ gateway ส่ง callback ซ้ำ" @/tmp/parent.md --labels bug,deposit-callback
./scripts/jira-client.sh create-bug RUAYS "[kol-wallet] กัน callback ฝากซ้ำด้วย idempotency key" @/tmp/wallet.md --labels kol-wallet,bug,deposit-callback
./scripts/jira-client.sh link blocks RUAYS-<child> RUAYS-<parent>
```

### Command: create-story

สร้าง Story พร้อม standard template

```bash
./scripts/jira-client.sh create-story PROJ "Feature summary" --labels Backend,Player --due 2026-02-14
```

**Template Sections:**
- Overview - อธิบายสั้นๆ ว่าทำอะไร
- Requirements - รายละเอียดความต้องการ
- System Flow - flow diagram (ASCII art)
- Subtask Dependencies - dependency tree
- Acceptance Criteria - functional, admin, logging requirements
- Definition of Done (DoD) - checklist
- Test Scenarios - test cases สำหรับ QA

**Options:**
- `--labels L1,L2` - เพิ่ม labels (comma-separated)
- `--due YYYY-MM-DD` - กำหนด due date

### Command: create-epic

สร้าง Epic พร้อม standard template (same as Story)

```bash
./scripts/jira-client.sh create-epic PROJ "Epic summary" --labels Backend --due 2026-02-28
```

### Command: create-subtask-templated

สร้าง Subtask พร้อม template และ dependency links

```bash
./scripts/jira-client.sh create-subtask-templated PROJ-123 "Phase 1: Data Models" \
  --labels Backend,Player \
  --due 2026-02-10 \
  --blocked-by PROJ-120 \
  --blocks PROJ-125,PROJ-128
```

**Template Sections:**
- Scope - อธิบายว่า subtask นี้ทำอะไร
- Dependencies - Blocked by / Blocks (links)
- Tasks - รายละเอียดงาน พร้อม file locations และ code snippets
- Acceptance Criteria - checklist

**Options:**
- `--labels L1,L2` - เพิ่ม labels
- `--due YYYY-MM-DD` - กำหนด due date
- `--blocked-by KEY1,KEY2` - สร้าง "blocked by" links
- `--blocks KEY1,KEY2` - สร้าง "blocks" links

### Command: add-labels

เพิ่ม labels ให้ issue

```bash
./scripts/jira-client.sh add-labels PROJ-123 Backend Player game
```

### Command: link

สร้าง dependency link ระหว่าง issues

```bash
# PROJ-124 blocks PROJ-125
./scripts/jira-client.sh link blocks PROJ-124 PROJ-125

# PROJ-125 is blocked by PROJ-124
./scripts/jira-client.sh link blocked-by PROJ-125 PROJ-124

# PROJ-123 relates to PROJ-456
./scripts/jira-client.sh link relates PROJ-123 PROJ-456
```

**Link Types:**
- `blocks` - from_key blocks to_key
- `blocked-by` - from_key is blocked by to_key
- `relates` - from_key relates to to_key

### Workflow: Start Working on Issue

> **Note:** ไม่มีคำสั่ง `/jira start` โดยตรง ให้ใช้ `/focus` แล้วเลือก "Jira (existing)" แทน
> หรือทำ workflow ด้านล่างนี้ด้วยตัวเอง

เริ่มทำงาน Jira issue - ดึงมาเป็น current focus

**Step 1: ดึงข้อมูล issue**

```bash
./scripts/jira-client.sh get [ISSUE_KEY]
```

**Step 2: สร้าง feature branch**

```bash
# Format: [type]/[issue-key]-[short-description]
# Type mapping from Jira issue type:
#   Bug -> fix
#   Story/Task -> feat
#   Epic -> feat
#   Improvement -> refactor

git checkout -b [type]/[ISSUE_KEY]-[slug]
```

**Step 3: Update docs/current.md**

```bash
export TZ='Asia/Bangkok'
cat > docs/current.md << EOF
STATE: working
TASK: [ISSUE_KEY] - [summary]
SINCE: $(date '+%Y-%m-%d %H:%M')
ISSUE: [ISSUE_KEY]
BRANCH: [branch-name]
JIRA_URL: [url]
EOF
```

**Step 4: Update activity.log**

```bash
export TZ='Asia/Bangkok'
echo "$(date '+%Y-%m-%d %H:%M') | working | [ISSUE_KEY] - [summary]" >> docs/logs/activity.log
```

**Step 5: Transition issue to "In Progress" (if available)**

```bash
# Get available transitions
./scripts/jira-client.sh transitions [ISSUE_KEY]

# If "In Progress" or similar transition exists, apply it
./scripts/jira-client.sh transition [ISSUE_KEY] [transition_id]
```

**Step 6: Assign to self**

```bash
./scripts/jira-client.sh assign [ISSUE_KEY] me
```

**Output:**
```
Started: [ISSUE_KEY]
Summary: [summary]
Branch: [branch]

Issue transitioned to: In Progress
Assigned to: you

Ready to work!
```

### Command: transition

เปลี่ยน status ของ issue ผ่าน Jira workflow transitions

**Step 1: แสดง available transitions**

```bash
./scripts/jira-client.sh transitions [ISSUE_KEY]
```

**Step 2: ถามว่าจะเปลี่ยนเป็น status ไหน**

ใช้ AskUserQuestion กับ options จาก transitions

**Step 3: Apply transition**

```bash
./scripts/jira-client.sh transition [ISSUE_KEY] [transition_id]
```

> **Note:** Jira ใช้ workflow transitions แทนการเปลี่ยน status โดยตรง ต้องใช้ transition ID (ตัวเลข) ไม่ใช่ชื่อ status

### Command: comment

เพิ่ม comment ใน issue

**Step 1: ถาม comment**

```
ใส่ comment สำหรับ [ISSUE_KEY]:
```

**Step 2: Add comment**

```bash
./scripts/jira-client.sh comment [ISSUE_KEY] "[comment]"
```

## Configuration

### First-time Setup

1. ไปที่ https://id.atlassian.com/manage-profile/security/api-tokens
2. สร้าง API Token
3. รัน `/jira init`

### Config File Locations

| Type | Location | Priority |
|------|----------|----------|
| Project | `.jira-config` | 1 (highest) |
| User | `~/.config/claude-km/jira.conf` | 2 |
| Environment | `JIRA_*` variables | 3 |

### Required Variables

```bash
JIRA_DOMAIN="company.atlassian.net"
JIRA_EMAIL="user@example.com"
JIRA_API_TOKEN="your-api-token"
JIRA_PROJECT="PROJ"  # default project
```

## Issue Type Mapping

| Jira Type | Git Branch Prefix |
|-----------|-------------------|
| Bug | `fix/` |
| Task | `feat/` |
| Story | `feat/` |
| Epic | `feat/` |
| Improvement | `refactor/` |
| Sub-task | `feat/` |

## Examples

```bash
# Setup
/jira init
/jira test

# Browse issues
/jira list PROJ
/jira my
/jira get PROJ-123

# Create issue
/jira create

# Create Bug (template + kb/00-inbox note)
./scripts/jira-client.sh create-bug PROJ "[kol-wallet] แก้ยอดฝากซ้ำ" @/tmp/bug-desc.md --labels kol-wallet,bug

# Create Story/Epic with templates
./scripts/jira-client.sh create-story PROJ "Feature summary" --labels Backend,Player --due 2026-02-14
./scripts/jira-client.sh create-epic PROJ "Big Feature Initiative" --labels Backend

# Create subtasks with dependencies
./scripts/jira-client.sh create-subtask-templated PROJ-123 "Phase 1: Data Models" --labels Backend --blocks PROJ-125,PROJ-128
./scripts/jira-client.sh create-subtask-templated PROJ-123 "Phase 2: Win Processing" --labels Backend --blocked-by PROJ-124 --blocks PROJ-126

# Add labels and links
./scripts/jira-client.sh add-labels PROJ-123 Backend Player game
./scripts/jira-client.sh link blocks PROJ-124 PROJ-125

# Start work (use /focus with Jira path)
/focus  # then select "Jira (existing)" and enter PROJ-123

# Change status (use transition ID from /jira transitions)
/jira transitions PROJ-123  # see available transitions
/jira transition PROJ-123 31  # 31 = Done (example ID)
/jira comment PROJ-123 "Fixed the issue"
```

## Integration with Other Commands

| Command | Jira Integration |
|---------|------------------|
| `/focus` | เลือกได้ว่าจะสร้าง GitHub Issue หรือ Jira |
| `/td` | อัพเดต Jira status เมื่อจบ session |
| `/recap` | แสดง Jira issue ถ้ามี |

## Error Handling

**Connection Error:**
```
Error: Failed to connect to Jira
Check your credentials with: /jira init
```

**Permission Error:**
```
Error: Permission denied for [ISSUE_KEY]
You may not have access to this project
```

**Invalid Issue:**
```
Error: Issue not found: [ISSUE_KEY]
Check the issue key and try again
```
