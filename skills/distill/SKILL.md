---
name: distill
description: Synthesizes related learnings into reusable knowledge base patterns.
argument-hint: "[topic-name]"
user-invocable: true
---

# Distill - Extract Patterns & Lessons

สังเคราะห์ความรู้จาก /mem learnings เป็น patterns (Layer 2)

## Usage

```
/distill [topic-name]
```

**Input:** `kb/05-ai-reviewed/learnings/` (vault via symlink)
**Output:** `kb/02-patterns/<domain>/<Name>.md`

> Note: `kb/` is a symlink to the Obsidian second-brain vault.
> Legacy path `docs/learnings/` + `docs/knowledge-base/` is deprecated — scan `kb/` only.

## Instructions

### Language Setting

> Check `LANGUAGE` in `docs/current.md`. If `th`, translate output per `references/language-guide.md`. See `references/bash-helpers.md` for detection snippet.

1. **Scan learnings** for related content (3+ files on same topic)
   ```bash
   find $PROJECT_ROOT/kb/05-ai-reviewed/learnings -name "*.md" -type f
   ```
2. **Analyze** for patterns, anti-patterns, insights
3. **Pick domain folder** under `kb/02-patterns/` (grpc, observability, database, k8s, websocket, workflow, auth, architecture, testing). Create new domain folder if needed.
4. **Create** knowledge entry with template below — use Title Case filename (e.g. `Consumer Retry Pattern.md`)
5. **Add frontmatter** per vault convention:
   ```yaml
   ---
   tags: [pattern, <domain>]
   type: pattern
   domain: <domain>
   services: [<services-using-this>]
   date: YYYY-MM-DD
   status: stable
   ---
   ```
6. **Mark sources** as "Distilled" (append `> **Distilled:** → [[<Pattern Name>]]`)
7. **Commit**: `git commit -m "knowledge: [topic] - [summary]"`

## Template

```markdown
# [Topic Name]

| Field | Value |
|-------|-------|
| **Created** | YYYY-MM-DD |
| **Sources** | learnings ที่ใช้ |
| **Tags** | `tag1` `tag2` |

---

## Key Insight

> One-sentence summary

---

## The Problem

| Attempt | Result |
|---------|--------|
| ทำแบบ X | เกิดปัญหา Y |

---

## The Solution

### Pattern: [Name]

```go
// Code example
```

**Why this works:**
- Reason 1

---

## Anti-Patterns

| Don't Do This | Do This Instead |
|---------------|-----------------|
| Bad | Good |

---

## When to Apply

- ใช้เมื่อ...
- ไม่ใช้เมื่อ...

---

## Decision Rationale (Optional)

> ใช้เมื่อ knowledge นี้เกี่ยวข้องกับการตัดสินใจสำคัญ

### Decision

[สรุปการตัดสินใจ]

### Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| Option A | ... | ... |
| **Chosen** | ... | ... |

### Why This Choice?

- เหตุผล 1
- เหตุผล 2

### Trade-offs Accepted

- ยอมรับ X เพื่อได้ Y

---

## Related

- Learnings: source files
- Code: relevant code paths
```

## After Distilling

Mark source learnings (use wiki-link for Obsidian graph):
```markdown
> **Distilled:** → [[<Pattern Name>]]
```

## When to Distill

| Trigger | Action |
|---------|--------|
| 3+ learnings เรื่องเดียวกัน | รวมเป็น knowledge |
| พบ pattern ใช้ซ้ำได้ | สร้าง knowledge |
| Weekly review | Scan pending learnings |
