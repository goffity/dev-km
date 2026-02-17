---
name: knowledge-curator
description: Scans learnings and suggests topics ready for distillation into knowledge base.
context: fork
user-invocable: false
---

# Knowledge Curator

Agent สำหรับ scan learnings และแนะนำ topics ที่ควร distill เป็น knowledge base entries

## Purpose

- Scan docs/learnings/ หา patterns
- Group related learnings by topic
- แนะนำ topics ที่มี 3+ learnings
- ช่วยเตรียม input สำหรับ `/distill`
- Track knowledge gaps

## When to Use

- Weekly/periodic knowledge review
- เมื่อมี learnings สะสมหลายรายการ
- ก่อนใช้ `/distill`
- เมื่อต้องการหา knowledge gaps

## Instructions

### Step 1: Scan Learnings Directory

```bash
find docs/learnings -name "*.md" -type f | head -50
find docs/learnings -name "*.md" | wc -l
```

### Step 2: Extract Topics from Each Learning

For each learning file:
1. Read the file content
2. Extract:
   - Title/slug from filename
   - Tags from frontmatter
   - Key concepts mentioned
   - Technology/tools mentioned

### Step 3: Group by Topic

Analyze and group learnings by:
- Common tags
- Similar titles
- Related technologies
- Problem domain

### Step 4: Identify Distill Candidates

A topic is ready for distill when:
- 3+ learnings on same topic
- Clear pattern emerges
- Reusable across projects
- Not already in knowledge-base

### Step 5: Check Existing Knowledge Base

```bash
ls -la docs/knowledge-base/
```

Compare with candidates to avoid duplicates.

### Step 6: Prioritize Topics

| Priority | Criteria |
|----------|----------|
| High | 5+ learnings, frequently referenced |
| Medium | 3-4 learnings, clear pattern |
| Low | 3 learnings, still evolving |

## Output Format

```markdown
## Knowledge Curation Report

**Learnings Scanned:** N files
**Date Range:** YYYY-MM-DD to YYYY-MM-DD
**Distill Candidates:** X topics

---

### Ready to Distill (3+ learnings)

#### 1. [Topic Name] - High Priority
**Learnings:** 5 files
**Pattern:** Brief description of the pattern

| File | Date | Key Point |
|------|------|-----------|
| `HH.MM_slug.md` | YYYY-MM-DD | Key insight |

**Suggested Distill Title:** `topic-name.md`
**Suggested Tags:** tag1, tag2, tag3

---

### Growing Topics (2 learnings)

| Topic | Count | Latest |
|-------|-------|--------|
| [topic] | 2 | YYYY-MM-DD |

---

### Knowledge Gaps

Areas with learnings but no knowledge base entry:
- [gap 1]
- [gap 2]

---

### Recommendations

1. **Distill Now:** [topic] - has 5+ learnings
2. **Watch:** [topic] - needs 1 more learning
3. **Review:** [existing entry] - might need update
```
