#!/bin/bash
# Claude Code Notification Script
# Sends macOS notifications when Claude needs attention

# Read JSON input from stdin
INPUT=$(cat)

# Parse notification type from hook input
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' | cut -c1-8)

# Get current working directory name for context
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
PROJECT_NAME=$(basename "$CWD" 2>/dev/null || echo "Claude Code")

# Notification messages based on type
case "$NOTIFICATION_TYPE" in
    "idle_prompt")
        TITLE="Claude Code - $PROJECT_NAME"
        MESSAGE="Waiting for your input (session: $SESSION_ID)"
        SOUND="Ping"
        ;;
    "permission_prompt")
        TITLE="Claude Code - Permission Required"
        MESSAGE="$PROJECT_NAME needs your approval"
        SOUND="Basso"
        ;;
    "auth_success")
        TITLE="Claude Code"
        MESSAGE="Authentication successful"
        SOUND="Glass"
        ;;
    "elicitation_dialog")
        TITLE="Claude Code - Input Needed"
        MESSAGE="MCP tool requires additional information"
        SOUND="Purr"
        ;;
    *)
        TITLE="Claude Code - $PROJECT_NAME"
        MESSAGE="Needs your attention"
        SOUND="Ping"
        ;;
esac

# Send macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\""

# Optional: Also send to terminal-notifier if available (for better action support)
if command -v terminal-notifier &> /dev/null; then
    terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound "$SOUND" -group "claude-code-$SESSION_ID"
fi

exit 0
