---
name: pr-audit
description: Deep reviewer-side audit of an open PR (by number/URL) — clone+build, cross-file caller tracing, compare with Copilot, post inline + summary review.
argument-hint: "[pr-number|url] [--mode] [--lang] [--repo owner/name]"
user-invocable: true
---

# PR Audit (Reviewer-Side Deep Review)

รีวิว PR ที่เปิดค้างอยู่ **ในฐานะ reviewer** แบบเชิงลึก — clone + build จริง, ไล่ caller ข้ามไฟล์,
เทียบกับ Copilot/reviewer อื่น แล้วโพสต์ inline conversation + summary review ขึ้น GitHub

> ต่างจาก `/pr` (สร้าง PR ใหม่), `/pr-review` (จัดการ feedback บน PR **ของตัวเอง**), `/review` (รีวิว local diff ก่อน push)
> `/pr-audit` = ออกรีวิว PR ของคนอื่นฝั่ง reviewer

## Usage

```
/pr-audit 351                       # รีวิว PR #351 ใน repo ปัจจุบัน (ถามโหมดตอนเริ่ม)
/pr-audit https://github.com/o/r/pull/351
/pr-audit 642 --repo owner/name     # รีวิวข้าม repo
/pr-audit 351 --mode=comment --lang=th   # โพสต์ลง PR เป็นภาษาไทย
/pr-audit 351 --mode=review              # ดูอย่างเดียว ไม่โพสต์
```

## Options

| Option | ค่า | Default | ความหมาย |
|--------|-----|---------|----------|
| `--mode` | `review` \| `comment` | ถามตอนเริ่ม | `review` = ดู/รายงานใน chat อย่างเดียว, `comment` = โพสต์ inline + summary ลง PR |
| `--lang` | `th` \| `en` | `th` | ภาษาของ comment ที่โพสต์ (เทียบ `references/language-guide.md`) |
| `--repo` | `owner/name` | repo ปัจจุบัน | รีวิว PR ข้าม repo |

## Instructions

### Language Setting

> Default `--lang=th`. ถ้าไม่ระบุ ตรวจ `LANGUAGE` ใน `docs/current.md` ด้วย แล้ว fallback เป็น `th`.
> แปล output ที่ผู้ใช้เห็น/comment ที่โพสต์ตาม `references/language-guide.md`.
> **คงเป็น English เสมอ:** code, commit hash, file path, line number, technical terms

### Step 0: Parse Arguments & Resolve PR

```bash
# แยก pr-number / url / flags จาก $ARGUMENTS
# ตั้ง REPO_FLAG="--repo owner/name" ถ้ามี --repo หรือ url ข้าม repo
PR=<pr-number>
REPO_FLAG=""   # เช่น "--repo owner/name"

# ดึง metadata
gh pr view $PR $REPO_FLAG --json number,title,url,headRefName,baseRefName,headRepository,headRepositoryOwner,state,author,additions,deletions,changedFiles,mergeable
```

ถ้า `--mode` ไม่ระบุ → **ถาม user** ก่อนว่าจะ `review` (ดูอย่างเดียว) หรือ `comment` (โพสต์ลง PR)

### Step 1: Fetch Diff & File List (กรอง noise)

```bash
# รายชื่อไฟล์ที่เปลี่ยน
gh pr diff $PR $REPO_FLAG --name-only

# ดู diff เต็ม (ข้าม lock/generated/vendor)
gh pr diff $PR $REPO_FLAG
```

**กรองออกจากการ deep-review** (แต่ยังนับว่ามีการเปลี่ยน): `*.lock`, `go.sum`, `package-lock.json`,
`*_gen.go`, `*.pb.go`, `dist/`, `vendor/`, `node_modules/`, generated/snapshot files

### Step 2: Clone / Worktree the PR Branch (ไม่แตะ working tree หลัก)

> **Safety:** ห้ามแตะ branch ปัจจุบัน — ใช้ worktree แยก และ cleanup เสมอ (ดู Step 8)

```bash
# stash ของหลักไว้ก่อน (กันพลาด) — ถ้ามี uncommitted
git stash push -m "pr-audit-autostash" 2>/dev/null || true

# สร้าง worktree แยกสำหรับ branch ของ PR
WT=$(mktemp -d -t pr-audit-$PR-XXXX)
git fetch origin pull/$PR/head:pr-audit-$PR 2>/dev/null \
  || gh pr checkout $PR $REPO_FLAG --branch pr-audit-$PR   # cross-repo fallback
git worktree add "$WT" pr-audit-$PR
echo "Worktree: $WT"
```

> ข้าม repo (`--repo`): ถ้า PR มาจาก fork ใช้ `gh pr checkout` ซึ่งจัดการ remote ของ fork ให้

### Step 3: Build + Test — **ทำทุกครั้ง (ไม่ optional)**

ใช้ **`build-validator`** subagent บน worktree — ห้ามเขียน build heuristic ซ้ำ

```
ใช้ Task tool subagent_type="build-validator":
"Detect project type in <WT> and run build + tests + lint.
Report PASS/FAIL per check with logs. Working dir: <WT>."
```

- ถ้า build/test **ไม่ผ่าน** → บันทึกเป็น finding ระดับ **CRITICAL** พร้อม log (ไม่หยุด flow — รายงานต่อ)
- ผลลัพธ์ build/test ใช้ยืนยัน finding (ดู KB-first ข้อ Step 5 — เช่น dup-import ที่ build ผ่าน)

### Step 4: Deep Review — ไล่ caller ข้ามไฟล์ + cross-layer wiring

ใช้ **`code-reviewer`** subagent หา bug/security/perf — ห้ามเขียน heuristic ซ้ำ

```
ใช้ Task tool subagent_type="code-reviewer":
"Review the diff of PR #<PR> at <WT> vs base <baseRef>.
Beyond per-file issues, trace cross-file wiring:
- caller → callee across files (signature/contract drift)
- cross-layer flow (e.g. CI workflow → Dockerfile ARG → app env → runtime)
- config/proto/schema changes vs their consumers
Return findings with severity (CRITICAL/WARNING/INFO), file:line, evidence, suggested fix."
```

เพิ่มการตรวจ cross-layer ที่ subagent มักพลาด (ไล่เองด้วย grep ใน worktree):
- workflow/CI → Dockerfile (`ARG`/`ENV`) → app — ค่าที่ส่งผ่านครบไหม (เช่น `ARG SITE` หาย → multi-site ไม่สลับธีม)
- migration/schema → repository/query layer
- proto/interface → ทั้ง server และ client implementations

### Step 5: KB-First Policy (ก่อน flag known-pattern)

ก่อนจะ flag finding ที่เป็น "known pattern" ให้ค้น KB ก่อน:

```bash
grep -ri "<keyword>" kb/02-patterns/ kb/03-bugs/ kb/02-patterns/anti-patterns/ 2>/dev/null
```

- **มี entry ตรง** → ทำตาม KB (ปรับ severity/คำแนะนำตามที่ KB สรุปไว้)
- **ไม่มี entry** → **หยุดถาม user** + เสนอแนะ แล้วบันทึกเป็น memory/KB ใหม่หลังจบ (Step 9)

**Known-pattern ที่ต้องระวัง** (ดู [known-patterns.md](known-patterns.md)):
- **dup-import**: import module path เดียวกันคนละ alias → Go **คอมไพล์ได้** อย่า flag เป็น compile error
  จนกว่าจะ build ยืนยัน (Step 3) — ดู known-patterns.md
- **money-flow-false-critical**: ก่อน flag CRITICAL double-credit/double-spend/idempotency บน money flow
  (deposit/withdraw/transfer) → ตรวจ DB constraint จริงรวม **child partition indexes** (partial unique index
  บน partition ไม่โผล่ที่ parent `pg_indexes` และไม่มีใน ORM tag; ใช้ readonly DB MCP ถ้ามี) + ไล่ atomicity
  ชั้นล่างสุด (tx wrapper รอบ credit+history-insert → rollback ทำ ordering ปลอดภัย) ก่อนโพสต์ — ดู known-patterns.md

### Step 6: Compare with Copilot / Other Reviews

```bash
# ดึง reviews + review comments ที่มีอยู่
gh pr view $PR $REPO_FLAG --json reviews,comments
gh api repos/{owner}/{repo}/pulls/$PR/comments --jq '.[] | {id, path, line, user: .user.login, body}'
```

- **ตัด finding ที่ซ้ำ** กับ Copilot/reviewer อื่น (ไม่โพสต์ซ้ำ)
- **ที่ไม่เห็นด้วย** → reply ที่ comment นั้นโดยตรงพร้อม **หลักฐาน** (build log / file:line / KB entry)

### Step 7: Output

#### Mode = review (ดูอย่างเดียว)
แสดง report ใน chat:

```markdown
## PR Audit #[number]: [title]   ([owner/repo])

**Build/Test:** PASS / FAIL (รายละเอียด)
**Findings:** [N] CRITICAL · [N] WARNING · [N] INFO  (ตัดซ้ำ Copilot [N] รายการ)

### CRITICAL
- `file:line` — [issue] · evidence: [...] · fix: [...]

### WARNING / INFO
- ...

### vs Copilot
- เห็นด้วย: [...]
- ไม่เห็นด้วย: [comment_id] — [เหตุผล + หลักฐาน]
```

#### Mode = comment (โพสต์ลง PR)
1. **Inline conversation** ต่อจุดโค้ด (ผูก commit_id + path + line):

```bash
HEAD_SHA=$(gh pr view $PR $REPO_FLAG --json headRefOid --jq .headRefOid)
gh api repos/{owner}/{repo}/pulls/$PR/comments \
  -f body="[finding + suggested fix]" \
  -f commit_id="$HEAD_SHA" \
  -f path="<file>" \
  -F line=<line> \
  -f side="RIGHT"
```

2. **Summary review comment** รวมทุกอย่าง (ภาษาตาม `--lang`):

```bash
gh pr review $PR $REPO_FLAG --comment --body "$(cat <<'EOF'
## PR Audit Summary
- Build/Test: [PASS/FAIL]
- CRITICAL: [N] · WARNING: [N] · INFO: [N]
- [สรุป findings สำคัญ + cross-file issues]
EOF
)"
```

> เลือก `--comment` (ไม่ block) เป็น default. ใช้ `--request-changes` เฉพาะเมื่อมี CRITICAL และ user ยืนยัน
> **หมายเหตุ:** submitted review **ลบไม่ได้** (แก้ body ได้), inline comment ลบได้ — โพสต์อย่างระมัดระวัง

### Step 8: Cleanup (เสมอ — แม้ flow ล้มเหลว)

```bash
git worktree remove "$WT" --force 2>/dev/null
git branch -D pr-audit-$PR 2>/dev/null
rm -rf "$WT" 2>/dev/null
git stash pop 2>/dev/null || true   # คืน working tree เดิม
```

### Step 9: Update KB (pattern ใหม่)

ถ้าเจอ pattern/anti-pattern ใหม่ที่ยังไม่มีใน KB (Step 5) → บันทึก:
- เป็น learning: `kb/05-ai-reviewed/learnings/YYYY-MM/DD/HH.MM_[slug].md` หรือ
- เป็น anti-pattern entry ใน `kb/02-patterns/anti-patterns/`

## Safety Rules (ตาม workspace rules)

| Rule | Detail |
|------|--------|
| ห้ามลบไฟล์ผู้ใช้ | review เท่านั้น |
| ห้าม force push / ห้ามแก้ branch ของ PR | reviewer ไม่ push |
| stash ก่อนสลับ/cleanup | คืน working tree เดิมเสมอ |
| ห้าม commit ลง main/develop | ไม่มี commit ในการ audit |
| cleanup worktree เสมอ | แม้ build ล้มเหลว (Step 8) |
| GitHub comments | submitted review ลบไม่ได้ (แก้ body ได้), inline ลบได้ |

## Reuse (ห้ามเขียน heuristic ซ้ำ)

| ต้องการ | เรียก |
|---------|-------|
| หา bug/security/perf | `code-reviewer` subagent |
| build/test/lint | `build-validator` subagent |
| ภาษา output | `references/language-guide.md` |

## Related Commands

| Command | Purpose |
|---------|---------|
| `/pr` | สร้าง PR ใหม่ (ฝั่ง author) |
| `/pr-review` | จัดการ feedback บน PR ของตัวเอง |
| `/review` | รีวิว local diff ก่อน push |
| `/pr-audit` | รีวิว PR คนอื่นเชิงลึกฝั่ง reviewer (คุณอยู่ที่นี่) |
