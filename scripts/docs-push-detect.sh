#!/bin/bash
# Detect git push to main and remind user to run /docs-update
# Used as PostToolUse hook for Bash tool

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command that was executed
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only check Bash commands
if [ "$TOOL_NAME" != "Bash" ]; then
    exit 0
fi

# Check if command is a git push to main
if echo "$TOOL_INPUT" | grep -qE 'git\s+push\s+.*main'; then
    # Output message to remind user
    echo '{"message": "Pushed to main detected. Run /docs-update to update feature documentation and changelog."}'
fi

exit 0
