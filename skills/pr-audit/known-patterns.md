# PR Audit — Known Patterns (KB-First Reference)

Known patterns ที่ reviewer มักจะ flag ผิด — ตรวจ KB ก่อนเสมอ (Step 5)
ถ้าเจอเคสใหม่ที่ไม่อยู่ที่นี่ → หยุดถาม user + บันทึกเป็น KB ใหม่ (Step 9)

## dup-import (Go) — อย่า flag เป็น compile error

**อาการที่เห็น:** import module path เดียวกันถูก import ด้วย alias ต่างกันในไฟล์เดียว/หลายไฟล์

```go
import (
    pb "example.com/proto/v1"
    pbv1 "example.com/proto/v1"   // ดูเหมือนซ้ำ
)
```

**ความจริง:** Go **คอมไพล์ผ่าน** ตราบใดที่แต่ละ alias ถูกใช้งานจริง (unused import ต่างหากที่ error)
การ flag ว่า "duplicate import → compile error" โดยไม่ build = **false positive**

**สิ่งที่ต้องทำ:**
1. รัน build ก่อน (Step 3) — ถ้า build ผ่าน = ไม่ใช่ compile error
2. ถ้าจะ flag ให้ flag เป็น **WARNING (style)** ว่า "ควรรวม alias เดียว" ไม่ใช่ CRITICAL
3. แนบ build log เป็นหลักฐานใน reply

## Cross-Layer Wiring (มักพลาดเพราะดูทีละไฟล์)

| ชั้น | ตรวจอะไร | ตัวอย่างบั๊กจริง |
|------|----------|------------------|
| CI/workflow → Dockerfile | `ARG`/`ENV`/build-args ส่งครบไหม | `ARG SITE` หายใน Dockerfile → multi-site build ไม่สลับธีม |
| Dockerfile → app runtime | env ที่ app อ่าน มีตั้งใน image ไหม | |
| migration → repository | column/index ที่ query ใช้ ตรงกับ schema ใหม่ไหม | |
| proto/interface → impl | server + client implement ครบทุก method ไหม | |

> วิธีตรวจ: grep ชื่อ symbol/ARG/env ข้ามไฟล์ใน worktree — อย่าเชื่อ per-file review อย่างเดียว

## วิธีค้น KB ก่อน flag

```bash
grep -ri "<keyword>" kb/02-patterns/ kb/03-bugs/ kb/02-patterns/anti-patterns/ 2>/dev/null
```

- มี entry → ทำตาม KB
- ไม่มี → หยุดถาม user + เสนอแนะ + บันทึกใหม่
