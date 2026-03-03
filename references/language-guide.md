# Language Guide

คู่มือการแปลภาษาสำหรับ output ที่ skills generate (issue comments, PR descriptions, local docs, confirmations)

## Reading Language Setting

```bash
LANG=$(grep "^LANGUAGE:" docs/current.md 2>/dev/null | cut -d: -f2 | xargs)
```

- `en` หรือไม่มีค่า → ใช้ English (default)
- `th` → ใช้ภาษาไทยตามตารางด้านล่าง

## Rules

| Rule | Detail |
|------|--------|
| Commit messages | English เสมอ (conventional commits: `feat\|fix\|refactor\|docs\|test\|chore\|perf\|style`) |
| Branch names | English เสมอ |
| Issue titles | Conventional prefix เป็น English (`feat:`, `fix:` etc.) ส่วน description ตาม LANGUAGE |
| Technical terms | คงเป็น English ได้ (PR, commit, branch, merge, build, test, deploy) |
| Mermaid diagram labels | English (rendering compatibility) |
| YAML frontmatter keys | English เสมอ (`date:`, `type:`, `status:`, `tags:`) |
| Table of data values | คงตาม original (ไม่แปล file paths, commit hashes, URLs) |

## Section Heading Translations

### GitHub Issue & PR

| English | Thai |
|---------|------|
| Overview | ภาพรวม |
| Summary | สรุป |
| Current State | สถานะปัจจุบัน |
| Proposed Solution | วิธีแก้ที่เสนอ |
| Technical Details | รายละเอียดทางเทคนิค |
| Acceptance Criteria | เกณฑ์การยอมรับ |
| Session Info | ข้อมูล Session |
| Changes Made | การเปลี่ยนแปลง |
| Testing | การทดสอบ |
| Related Issues | Issues ที่เกี่ยวข้อง |

### /pr Issue Comments

| English | Thai |
|---------|------|
| Running Tests | กำลังรัน Tests |
| Tests Passed | Tests ผ่าน |
| Tests Failed | Tests ไม่ผ่าน |
| Build Passed | Build ผ่าน |
| Build Failed | Build ไม่ผ่าน |
| Code Review Started | เริ่ม Code Review |
| Code Review Passed | Code Review ผ่าน |
| Code Review Failed | Code Review ไม่ผ่าน |
| Pull Request Created | สร้าง Pull Request แล้ว |
| All Checks Passed | ผ่านการตรวจสอบทั้งหมด |
| Critical Issues Found | พบปัญหาร้ายแรง |
| Error Output | ผลลัพธ์ Error |
| Action Required | ต้องดำเนินการ |

### /td & Retrospective

| English | Thai |
|---------|------|
| Session Summary | สรุป Session |
| Tasks Done | งานที่ทำแล้ว |
| Test Results | ผลการทดสอบ |
| Test Details | รายละเอียดการทดสอบ |
| Errors | ข้อผิดพลาด |
| Additional Notes | หมายเหตุเพิ่มเติม |
| Session Metadata | ข้อมูล Session |
| Context: Before | บริบท: ก่อน |
| Context: After | บริบท: หลัง |
| Problem | ปัญหา |
| Existing Behavior | พฤติกรรมเดิม |
| Why Change | ทำไมต้องเปลี่ยน |
| Solution | วิธีแก้ |
| New Behavior | พฤติกรรมใหม่ |
| Improvements | สิ่งที่ดีขึ้น |
| Metrics | ตัวชี้วัด |
| Decisions & Rationale | การตัดสินใจและเหตุผล |
| Task Description | รายละเอียดงาน |
| Outcome | ผลลัพธ์ |
| Technical Details | รายละเอียดทางเทคนิค |
| Files Modified | ไฟล์ที่แก้ไข |
| Recent Commits | Commits ล่าสุด |
| Honest Feedback | ข้อเสนอแนะ |
| What Went Well | สิ่งที่ทำได้ดี |
| What Could Be Improved | สิ่งที่ควรปรับปรุง |
| Lessons Learned | บทเรียนที่ได้ |
| Validation Checklist | รายการตรวจสอบ |
| Session Complete | จบ Session |
| Next Steps | ขั้นตอนถัดไป |

### /commit

| English | Thai |
|---------|------|
| Implementation Update | อัปเดตการพัฒนา |
| Changes Made | การเปลี่ยนแปลง |
| Commits | Commits |
| Status | สถานะ |

### /pr-review

| English | Thai |
|---------|------|
| Review Summary | สรุป Review |
| Action Required | ต้องดำเนินการ |
| Suggestions | ข้อเสนอแนะ |
| Deferred | เลื่อนออกไป |
| Praise/Acknowledgments | คำชม/รับทราบ |
| Questions | คำถาม |
| PR Review Complete | Review PR เสร็จสิ้น |
| Actions Taken | สิ่งที่ดำเนินการ |
| Summary Statistics | สถิติสรุป |
| Deferred Items | รายการที่เลื่อนออกไป |
| Files Modified | ไฟล์ที่แก้ไข |
| Learning Document | เอกสารการเรียนรู้ |
| Key Insights from Review | ข้อค้นพบสำคัญจาก Review |
| What Reviewers Caught | สิ่งที่ Reviewer พบ |
| Patterns to Remember | รูปแบบที่ควรจดจำ |
| Code Examples | ตัวอย่างโค้ด |
| Before | ก่อน |
| After | หลัง |
| Why This Matters | ทำไมเรื่องนี้สำคัญ |
| Apply To | นำไปใช้กับ |
| PR Review Progress | ความคืบหน้า Review PR |

### /review

| English | Thai |
|---------|------|
| Code Review Passed | Code Review ผ่าน |
| Code Review Failed | Code Review ไม่ผ่าน |
| Critical Issues | ปัญหาร้ายแรง |
| Warnings | คำเตือน |
| Info | ข้อมูลเพิ่มเติม |
| Overall Assessment | การประเมินโดยรวม |
| Ready to Push | พร้อม Push |

### /mem

| English | Thai |
|---------|------|
| Key Insight | ข้อค้นพบสำคัญ |
| What We Learned | สิ่งที่เรียนรู้ |
| How Things Connect | ความเชื่อมโยง |
| Gotchas & Warnings | ข้อควรระวัง |
| Related | ที่เกี่ยวข้อง |
| Tags | แท็ก |
| Raw Thoughts | ความคิดดิบ |

### /distill

| English | Thai |
|---------|------|
| Key Insight | ข้อค้นพบสำคัญ |
| The Problem | ปัญหา |
| The Solution | วิธีแก้ |
| Anti-Patterns | รูปแบบที่ไม่ควรทำ |
| When to Apply | เมื่อไหร่ควรใช้ |
| Decision Rationale | เหตุผลของการตัดสินใจ |
| Alternatives Considered | ทางเลือกที่พิจารณา |
| Why This Choice? | ทำไมเลือกทางนี้? |
| Trade-offs Accepted | ข้อแลกเปลี่ยนที่ยอมรับ |
| Changelog | บันทึกการเปลี่ยนแปลง |

### /summary

| English | Thai |
|---------|------|
| Week Summary | สรุปรายสัปดาห์ |
| Monthly Summary | สรุปรายเดือน |
| Sessions | Sessions |
| Issues Closed | Issues ที่ปิด |
| PRs Merged | PRs ที่ Merge |
| Learnings Captured | ความรู้ที่บันทึก |
| Key Accomplishments | ผลงานสำคัญ |
| Knowledge Distilled | ความรู้ที่สังเคราะห์ |
| Decisions Made | การตัดสินใจ |
| Open Items | รายการค้าง |
| Next Week Focus | โฟกัสสัปดาห์หน้า |
| Weekly Breakdown | แบ่งตามสัปดาห์ |
| Top Accomplishments | ผลงานเด่น |
| Patterns & Trends | รูปแบบและแนวโน้ม |
| Open Items Carried Over | รายการค้างยกมา |
| Next Month Priorities | สิ่งที่ต้องทำเดือนหน้า |

### /example

| English | Thai |
|---------|------|
| Title | ชื่อ |
| Description | คำอธิบาย |
| Usage | การใช้งาน |
| Created | สร้างเมื่อ |

### /flow

| English | Thai |
|---------|------|
| Overview | ภาพรวม |
| Diagram | แผนภาพ |
| Steps | ขั้นตอน |
| Error Handling | การจัดการ Error |

### /pattern

| English | Thai |
|---------|------|
| Intent | จุดประสงค์ |
| Problem | ปัญหา |
| Solution | วิธีแก้ |
| Structure | โครงสร้าง |
| Example | ตัวอย่าง |
| When to Use | เมื่อไหร่ควรใช้ |
| When NOT to Use | เมื่อไหร่ไม่ควรใช้ |
| Trade-offs | ข้อแลกเปลี่ยน |
| Related Patterns | รูปแบบที่เกี่ยวข้อง |
| References | อ้างอิง |

### /recap & /improve

| English | Thai |
|---------|------|
| Session Recap | สรุป Session |
| Current Focus | โฟกัสปัจจุบัน |
| Recent Activity | กิจกรรมล่าสุด |
| Git Status | สถานะ Git |
| Pending Improvements | การปรับปรุงที่รอดำเนินการ |
| From Knowledge Base | จาก Knowledge Base |
| From Retrospectives | จาก Retrospectives |
| From Learnings | จาก Learnings |
| Completed Improvements | การปรับปรุงที่เสร็จแล้ว |
| Completed | เสร็จสิ้น |

### /focus

| English | Thai |
|---------|------|
| Focus Set | ตั้ง Focus แล้ว |
| Issue Created | สร้าง Issue แล้ว |

### Common Fields

| English | Thai |
|---------|------|
| Field | ฟิลด์ |
| Value | ค่า |
| Date | วันที่ |
| Time | เวลา |
| Duration | ระยะเวลา |
| Type | ประเภท |
| Branch | Branch |
| Issue | Issue |
| Status | สถานะ |
| Started | เริ่มต้น |
| In Progress | กำลังดำเนินการ |
| Captured | บันทึกเมื่อ |
| Context | บริบท |
| Sources | แหล่งที่มา |
| Created | สร้างเมื่อ |
| Metric | ตัวชี้วัด |

## Common Phrases

| English | Thai |
|---------|------|
| Fix errors and run `/pr` again | แก้ไข errors และรัน `/pr` อีกครั้ง |
| Ready to start! Use `/td` when done | พร้อมเริ่มงาน! ใช้ `/td` เมื่อจบ session |
| All tests passed | Tests ทั้งหมดผ่าน |
| Build successful | Build สำเร็จ |
| Proceeding to build... | กำลังไปขั้นตอน build... |
| Proceeding to code review... | กำลังไปขั้นตอน code review... |
| Proceeding to create PR... | กำลังไปสร้าง PR... |
| PR will auto-close this issue when merged | PR จะปิด issue นี้อัตโนมัติเมื่อ merge |
| Wait for reviewer approval | รอ reviewer อนุมัติ |
| Address feedback if any | แก้ไขตาม feedback (ถ้ามี) |
| No review yet | ยังไม่มี review |
| Sending to agent for auto-fix... | กำลังส่งให้ agent แก้ไขอัตโนมัติ... |
| No changes to commit | ไม่มีการเปลี่ยนแปลงที่ต้อง commit |
| Use `/focus` to set new task | ใช้ `/focus` เพื่อตั้งงานใหม่ |
| No pending work | ไม่มีงานค้าง |
