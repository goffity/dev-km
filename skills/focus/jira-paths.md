# Jira Integration Paths

## Path B: Jira (New Issue)

### Step 4B: Gather Jira Issue Details

ใช้ AskUserQuestion:

1. **Project Key**: รหัส project ใน Jira (e.g., PROJ)
2. **Issue Type**: Task, Bug, Story, Epic
3. **Summary**: หัวข้อ issue
4. **Description**: รายละเอียด

### Step 5B: Create Jira Issue

```bash
# Get Jira type to git type mapping
# Bug -> fix, Task/Story/Epic -> feat, Improvement -> refactor
JIRA_TYPE="[selected type]"
case "$JIRA_TYPE" in
    Bug) GIT_TYPE="fix" ;;
    Improvement) GIT_TYPE="refactor" ;;
    *) GIT_TYPE="feat" ;;
esac

# Create issue
RESULT=$(./scripts/jira-client.sh create "[PROJECT]" "[SUMMARY]" "[DESCRIPTION]" "[JIRA_TYPE]")
ISSUE_KEY=$(echo "$RESULT" | grep -E '^[A-Z]+-[0-9]+$' | head -1)

echo "Created: $ISSUE_KEY"
```

เก็บ `ISSUE_KEY` (เช่น `PROJ-123`) ไว้ใช้ใน Step 6

**ไปที่ Step 6: Create Feature Branch** (in main SKILL.md)

---

## Path C: Jira (Existing Issue)

### Step 4C: Select Existing Jira Issue

**แสดง issues ที่ assign ให้ user:**
```bash
./scripts/jira-client.sh my-issues
```

**หรือ list issues ใน project:**
```bash
./scripts/jira-client.sh list [PROJECT] "To Do"
```

**ถาม user:**
```
ใส่ Issue Key ที่ต้องการทำ (e.g., PROJ-123):
```

### Step 5C: Fetch Issue Details

```bash
./scripts/jira-client.sh get [ISSUE_KEY]
```

**Map Jira type to git type:**
```bash
JIRA_TYPE=$(./scripts/jira-client.sh get [ISSUE_KEY] | jq -r '.type')
case "$JIRA_TYPE" in
    Bug) GIT_TYPE="fix" ;;
    Improvement) GIT_TYPE="refactor" ;;
    *) GIT_TYPE="feat" ;;
esac
```

**ไปที่ Step 6: Create Feature Branch** (in main SKILL.md)
