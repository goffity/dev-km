---
name: build-validator
description: Validates build, tests, and lint before push to ensure quality gates pass.
context: fork
user-invocable: false
---

# Build Validator

Agent สำหรับตรวจสอบ build, tests, และ lint ก่อน push

## Purpose

- รัน tests และตรวจสอบผลลัพธ์
- รัน build และตรวจสอบ success
- รัน linter และตรวจสอบ errors
- รวบรวมผลลัพธ์เป็น report
- Block push ถ้าไม่ผ่าน

## Instructions

### Step 1: Detect Project Type

```bash
[ -f "Makefile" ] && echo "Makefile detected"
[ -f "package.json" ] && echo "Node.js project"
[ -f "go.mod" ] && echo "Go project"
[ -f "Cargo.toml" ] && echo "Rust project"
[ -f "pyproject.toml" ] && echo "Python project"
```

### Step 2: Run Tests

| Project Type | Command |
|---|---|
| Makefile | `make test` |
| Node.js | `npm test` / `bun test` / `yarn test` |
| Go | `go test ./...` |
| Python | `pytest` |
| Rust | `cargo test` |

### Step 3: Run Build

| Project Type | Command |
|---|---|
| Makefile | `make build` |
| Node.js | `npm run build` |
| Go | `go build ./...` |
| Rust | `cargo build` |

### Step 4: Run Linter

| Project Type | Command |
|---|---|
| Node.js/TS | `npm run lint` / `eslint .` |
| Go | `golangci-lint run` / `go vet ./...` |
| Python | `ruff check .` / `flake8` |
| Rust | `cargo clippy` |

### Step 5: Run Type Check (if applicable)

| Project Type | Command |
|---|---|
| TypeScript | `npm run typecheck` / `tsc --noEmit` |
| Python | `mypy .` |

### Step 6: Analyze Results

| Check | Pass Criteria |
|-------|---------------|
| Tests | Exit code 0, no failures |
| Build | Exit code 0, artifacts created |
| Lint | No errors (warnings OK) |
| Types | No type errors |

## Output Format

```markdown
## Build Validation Report

**Project:** [project-name]
**Date:** YYYY-MM-DD HH:MM:SS
**Branch:** [branch-name]

### Overall Status: PASS / FAIL

---

### Test Results
| Status | Details |
|--------|---------|
| PASS/FAIL | X tests passed, Y failed |

### Build Results
| Status | Details |
|--------|---------|
| PASS/FAIL | Build details |

### Lint Results
| Status | Details |
|--------|---------|
| PASS/FAIL/WARN | Error/warning counts |

### Type Check Results
| Status | Details |
|--------|---------|
| PASS/FAIL | Type error counts |

---

### Summary

| Check | Status | Time |
|-------|--------|------|
| Tests | pass/fail | Xs |
| Build | pass/fail | Xs |
| Lint | pass/fail | Xs |
| Types | pass/fail | Xs |

**Recommendation:** Ready to Push / Do Not Push
```

## Error Recovery

| Failure | Recovery |
|---------|----------|
| Missing deps | `npm install` / `go mod tidy` |
| Stale cache | Clean and rebuild |
| Type errors | Fix types first |
| Lint errors | Run formatter |
