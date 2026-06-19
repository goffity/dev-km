> **Language:** If `LANGUAGE: th` in `docs/current.md`, translate all section headings per `references/language-guide.md`.

# /improve Workflow

## Scan Order (Priority)

1. `kb/02-patterns/` - Patterns to apply (Priority 1)
2. `kb/04-decisions/` - ADR action items (Priority 2)
3. `kb/03-bugs/` - Bug postmortem action items (Priority 3)
4. `kb/05-ai-reviewed/retrospective/` - Future Improvements (Priority 4)
5. `kb/05-ai-reviewed/learnings/` - Gotchas to fix (Priority 5, skip "Distilled")

> `kb/` = symlink to Obsidian second-brain vault.
> Legacy `docs/` paths deprecated.

## Scan Commands

```bash
# Patterns (Priority 1)
find $PROJECT_ROOT/kb/02-patterns -name "*.md" -type f | sort -r

# ADRs (Priority 2)
find $PROJECT_ROOT/kb/04-decisions -name "*.md" -type f | sort -r

# Bug postmortems (Priority 3)
find $PROJECT_ROOT/kb/03-bugs -name "*.md" -type f | sort -r

# Retrospectives (Priority 4)
find $PROJECT_ROOT/kb/05-ai-reviewed/retrospective -name "*.md" -type f | sort -r

# Learnings (Priority 5, skip distilled)
find $PROJECT_ROOT/kb/05-ai-reviewed/learnings -name "*.md" -type f | sort -r
```

## Extract Actionable Items

### From Patterns (Priority 1)

- "## When to Apply" conditions ที่ยังไม่ได้ implement
- Patterns ที่ยังไม่ได้ใช้ในโค้ด
- Anti-patterns ที่ยังมีอยู่ในโค้ด

### From ADRs (Priority 2)

- "## ผลกระทบ" — items ที่ต้องเปลี่ยน (`- [ ]`)
- Migration path ที่ยังไม่เสร็จ

### From Bug Postmortems (Priority 3)

- "## Action Items" — preventive actions (`- [ ]`)
- "## Detection Gap" — monitoring/alerting ที่ต้องเพิ่ม

### From Retrospectives (Priority 4)

- "### Future Improvements" section
- "## 📋 Action Items" (`- [ ]`)

### From Learnings (Priority 5)

- "## Gotchas & Warnings" ที่ควรแก้ไข
- Actionable items จาก "## What We Learned"
- **Skip** items ที่มี `> **Distilled:**`

## Present to User

```markdown
## Pending Improvements

### From Patterns - Priority 1

Kafka Error Handling.md:
1. [ ] Apply retry pattern to all consumers
2. [ ] Add dead letter queue for failed messages

### From ADRs - Priority 2

ADR-008-otelzap-trace-injection.md:
3. [ ] Migrate remaining services to otelzap

### From Bug Postmortems - Priority 3

2026-04-18 mongo - nil pointer.md:
4. [ ] Add nil-vs-empty check to report-api

### From Retrospectives - Priority 4

retrospective_2026-04-01_150100.md:
5. [ ] Add consumer mocks to Makefile

### From Learnings - Priority 5

14.30_redis-connection-issue.md:
6. [ ] Document Redis pubsub patterns in CLAUDE.md
```

## User Selection

Ask:
- "เลือก item ที่ต้องการทำ (ระบุหมายเลข หรือ 'all')"
- หรือ "skip" เพื่อข้าม

## Execute

For each selected item:

1. วิเคราะห์ว่าต้องทำอะไร
2. วางแผนและ implement
3. ทดสอบ (run tests)
4. Commit with atomic commits
5. Update source file:
   - Pattern: เพิ่ม changelog entry
   - ADR: อัพเดท impact checklist
   - Bug: mark action item complete
   - Retrospective: เปลี่ยน `- [ ]` เป็น `- [x]`
   - Learning: เพิ่ม note ว่า resolved
6. ใช้ wiki-link `[[...]]` เมื่อ reference file อื่นใน vault

## Output Summary

```markdown
## Completed Improvements

- [x] Add consumer mocks to Makefile (commit: abc1234)
- [ ] Consider round.status = "settled" (skipped - needs discussion)

Updated files:
- kb/05-ai-reviewed/retrospective/2026-04/retrospective_2026-04-01_150100.md
```

## Notes

- Prioritize patterns + ADRs (stable/curated knowledge)
- ถ้า item ต้องการ discussion หรือ approval ให้ถามก่อน
- Update source file หลังทำเสร็จแต่ละ item
- ห้ามแก้ `docs/` เดิม — ใช้ `kb/` เท่านั้น
