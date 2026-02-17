---
name: code-simplifier
description: Simplifies and cleans up code by reducing complexity and removing unnecessary abstractions.
context: fork
user-invocable: false
---

# Code Simplifier

Agent สำหรับ simplify code หลังจากเขียนเสร็จ - ลด complexity และทำให้ code อ่านง่ายขึ้น

## Purpose

- ลด code complexity
- Remove unnecessary abstractions
- Simplify logic และ control flow
- ลด duplication
- ทำให้ code อ่านง่ายและ maintain ง่าย

## When to Use

- หลังจากเขียน code เสร็จ
- เมื่อ code ดู complex เกินไป
- ก่อน commit เพื่อ clean up
- เมื่อต้องการ refactor

## Instructions

### Step 1: Identify Target Files

```bash
git diff --name-only HEAD
```

### Step 2: Analyze Complexity

For each file, check for:

1. **Over-engineering:**
   - Unnecessary abstractions
   - Too many layers of indirection
   - Premature optimization
   - Over-generalization

2. **Code Smells:**
   - Functions longer than 20 lines
   - Deep nesting (> 3 levels)
   - Too many parameters (> 4)
   - Duplicate code blocks

3. **Unnecessary Patterns:**
   - Design patterns where simple code works
   - Complex inheritance when composition is simpler
   - Callbacks when async/await is cleaner

### Step 3: Simplification Strategies

| Problem | Solution |
|---------|----------|
| Long function | Extract smaller functions |
| Deep nesting | Early returns, guard clauses |
| Complex conditionals | Switch/match or lookup tables |
| Duplicate code | Extract shared function |
| Over-abstraction | Inline simple abstractions |
| Too many helpers | Consolidate or inline |

### Step 4: Apply YAGNI Principle

- Remove code for "future use"
- Remove unused parameters
- Remove commented-out code
- Remove empty/placeholder functions

### Step 5: Readability Improvements

- Use descriptive variable names
- Add whitespace for clarity
- Group related code together
- Simplify boolean expressions
- Use early returns

## Output Format

```markdown
## Code Simplification Report

**Files Analyzed:** N files
**Simplifications Found:** X items

---

### File: [filename]

#### Before
```[language]
// Complex code
```

#### After
```[language]
// Simplified code
```

**Why:** Explanation of the simplification

---

### Summary of Changes

| Type | Count |
|------|-------|
| Functions simplified | X |
| Abstractions removed | Y |
| Duplicates merged | Z |
| Lines reduced | N |
```

## Guidelines

### DO Simplify:
- 3 similar lines → 1 loop or function
- Nested if-else → switch or early returns
- Complex boolean → named variable
- Callback hell → async/await

### DON'T Over-Simplify:
- Don't remove necessary error handling
- Don't merge unrelated functions
- Don't sacrifice clarity for brevity
- Don't remove useful abstractions
