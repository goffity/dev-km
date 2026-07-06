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

## money-flow-false-critical — อย่า flag double-credit/double-spend โดยไม่ตรวจ DB constraint จริง

**อาการที่เห็น:** เห็น credit/UPDATE balance เกิด **ก่อน** status-update guard บน money flow (deposit callback,
withdraw, transfer) → สรุปว่า "concurrent duplicate → double-credit, receiver ไม่ idempotent" แล้ว flag CRITICAL

**ความจริง (เคสจริง kol-wallet #964, RUAYS-1767):** CRITICAL นี้ **ผิด** ด้วยเหตุผลอิสระ 3 ข้อ —

1. **Partial unique index ที่ child partition ไม่โผล่ที่ parent/ORM.** `wallet_histories` (PostgreSQL,
   partition by `created_at`) มี **partial UNIQUE index ราย partition** เช่น
   `idx_wallet_histories_YYYY_MM_deposit UNIQUE (reference_event_id, reference_transaction_id, transaction_type, amount) WHERE wallet_action = 'deposit'`
   — ตัวนี้ **ไม่โผล่** ตอน query `pg_indexes` บน parent (parent เห็นแค่ PK), **ไม่มี** ใน GORM struct tag,
   โผล่เฉพาะตอน query **child partition** ตรง ๆ. reviewer ที่ดูแค่ parent + application code → สรุปผิดว่า "ไม่มี idempotency guard"
2. **Underestimate atomicity.** credit path `UpdateBalanceWithTx` ห่อ `UPDATE player_wallets SET balance = balance + ?`
   **และ** `INSERT wallet_histories` ไว้ใน `gorm.Transaction()` เดียว. duplicate INSERT ชน unique index →
   **ทั้ง transaction rollback** รวม balance update → ไม่มี double-credit. "credit เกิดก่อน guard" จึง **ปลอดภัย**
   เพราะ credit เป็น idempotent-by-constraint (at-least-once delivery + idempotent receiver pattern)
3. **Mis-attribute TODO comment.** หลักฐาน `//TODO FIXME: Validate duplicate transaction ... is not unique`
   ที่ยกมาจริง ๆ อยู่ใน `UpdateAffiliateBalance` (คนละ function, affiliate path) ไม่ใช่ `UpdateBalance` หลัก —
   reviewer grep line number แล้วใช้เป็น evidence โดยไม่ได้อ่าน enclosing function

**สิ่งที่ต้องทำ (ก่อน flag CRITICAL idempotency/double-credit/double-spend บน money flow):**
1. **ตรวจ DB constraint จริงบน live DB** (หรือ migration) รวม **child partitions** — partial unique index
   บน partition ไม่โผล่ที่ parent `pg_indexes` และไม่มีใน ORM tag. ใช้ readonly DB access (MCP) ถ้ามี
2. **ไล่ operation-ordering ลงชั้นล่างสุด** — tx wrapper (เช่น `gorm.Transaction`) รอบ credit+history-insert
   เปลี่ยนความหมายของ "credit เกิดก่อน guard" ทั้งหมด: rollback ทำให้ ordering ปลอดภัย
3. **อย่าอ้าง TODO/comment เป็นหลักฐานโดยไม่อ่าน enclosing function** — grep line number attribute ผิดง่ายมาก
4. **credit-first + idempotent receiver เป็น design ที่ถูกต้อง (บ่อยครั้งดีกว่า) เทียบ claim-before-credit** —
   claim-first เสี่ยง "status=success แต่เงินยังไม่เข้า" ต้องมี compensation logic. อย่าเสนอ claim-first เป็น
   default fix เมื่อ DB unique constraint ทำให้ credit idempotent อยู่แล้ว

## วิธีค้น KB ก่อน flag

```bash
grep -ri "<keyword>" kb/02-patterns/ kb/03-bugs/ kb/02-patterns/anti-patterns/ 2>/dev/null
```

- มี entry → ทำตาม KB
- ไม่มี → หยุดถาม user + เสนอแนะ + บันทึกใหม่
