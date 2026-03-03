# Review Learning Template

Template for creating learning documents from PR reviews (used in Step 8 of `/pr-review`).

## File Path

```
docs/learnings/YYYY-MM/DD/HH.MM_pr-review-[topic].md
```

## Setup

```bash
TIMESTAMP=$(TZ='Asia/Bangkok' date '+%H.%M')
DATE_PATH=$(TZ='Asia/Bangkok' date '+%Y-%m/%d')
mkdir -p docs/learnings/$DATE_PATH
```

## Template

```markdown
---
type: review-learning
source: PR #[number]
reviewers: [@reviewer1, @reviewer2]
tags: [relevant-tags]
---

# [Title based on main feedback theme]

## Key Insights from Review

### What Reviewers Caught
- [issue 1]: [what was wrong and why]
- [issue 2]: [what was wrong and why]

### Patterns to Remember
- **Do**: [good practice learned]
- **Don't**: [anti-pattern identified]

## Code Examples

### Before (What I wrote)
```[lang]
[original code]
```

### After (Improved version)
```[lang]
[fixed code]
```

## Why This Matters
[explanation of why reviewer's suggestion is better]

## Apply To
- [future scenario 1]
- [future scenario 2]

## Related
- PR: [url]
- Issue: [url if any]
```
