---
name: example
description: Saves reusable code examples to the examples library with metadata and tags.
argument-hint: "[language] [name]"
user-invocable: true
---

# Example - Code Examples Library

Save and organize reusable code snippets with metadata.

## Usage

```
/example [language] [name]
```

**Output:** `$PROJECT_ROOT/docs/examples/[language]/[name].[ext]`

## Instructions

### Language Setting

Before generating any output, check the language setting:

```bash
LANG=$(grep "^LANGUAGE:" docs/current.md 2>/dev/null | cut -d: -f2 | xargs)
```

If `LANG` is `th`, generate description comments in Thai. Refer to `references/language-guide.md` for standard translations. Code comments for metadata (Title, Tags) remain in English.

1. **Parse arguments**: language (go, typescript, python, bash, etc.) and name (kebab-case)
2. **Determine file extension** from language:
   - go → .go
   - typescript/ts → .ts
   - javascript/js → .js
   - python/py → .py
   - bash/sh → .sh
   - rust → .rs
   - java → .java
3. **Gather context**: Look at recent code in conversation, ask user what code to save if unclear
4. **Create directory**: `docs/examples/[language]/`
5. **Generate file** with metadata header and code
6. **Confirm** with user

## File Format

### Go Example
```go
// Title: [Descriptive Title]
// Tags: [tag1, tag2, tag3]
// Related: [link to knowledge-base or learnings if any]
// Created: YYYY-MM-DD

package examples

// [Description of what this code does]
// Usage:
//   [usage example]
[code]
```

### TypeScript/JavaScript Example
```typescript
// Title: [Descriptive Title]
// Tags: [tag1, tag2, tag3]
// Related: [link to knowledge-base if any]
// Created: YYYY-MM-DD

// [Description]
// Usage:
//   [usage example]
[code]
```

### Python Example
```python
# Title: [Descriptive Title]
# Tags: [tag1, tag2, tag3]
# Related: [link to knowledge-base if any]
# Created: YYYY-MM-DD

# [Description]
# Usage:
#   [usage example]
[code]
```

### Bash Example
```bash
#!/bin/bash
# Title: [Descriptive Title]
# Tags: [tag1, tag2, tag3]
# Related: [link to knowledge-base if any]
# Created: YYYY-MM-DD

# [Description]
# Usage:
#   [usage example]
[code]
```

## Guidelines

- Code should be **runnable** or at minimum compilable
- Include usage examples in comments
- Add relevant tags for searchability
- Link to related knowledge-base entries if they exist
- Keep examples focused on one concept/pattern
- Use descriptive names (e.g., `retry-with-backoff`, `api-client-wrapper`)

## Listing Examples

To browse existing examples:
```bash
find docs/examples -type f | sort
```

## Related Commands

| Command | Purpose |
|---------|---------|
| `/mem` | Quick knowledge capture |
| `/distill` | Extract patterns to knowledge base |
| `/example` | Save code examples (you are here) |
