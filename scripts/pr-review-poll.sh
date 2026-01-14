#!/bin/bash
# PR Review Polling Daemon
# Polls GitHub for PR review updates and notifies user
#
# Usage: ./pr-review-poll.sh [options]
# Options:
#   --interval N     Polling interval in seconds (default: 300 = 5 minutes)
#   --once           Run once and exit (for testing)
#   --repo OWNER/REPO  Specific repo (default: current repo)
#   -h, --help       Show this help message

set -euo pipefail

# Default configuration
POLL_INTERVAL=300  # 5 minutes
RUN_ONCE=false
REPO=""
STATE_FILE="${HOME}/.pr-review-state.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Sanitize string for AppleScript (escape quotes and backslashes)
sanitize_for_applescript() {
    local str="$1"
    # Escape backslashes first, then double quotes
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    echo "$str"
}

# Help message
show_help() {
    cat << EOF
PR Review Polling Daemon

Polls GitHub for PR review updates and sends notifications when:
- A PR receives a new review
- A review decision changes (approved, changes requested)
- New review comments are added

Usage: ./pr-review-poll.sh [options]

Options:
  --interval N       Polling interval in seconds (default: 300 = 5 minutes)
  --once             Run once and exit (useful for testing)
  --repo OWNER/REPO  Specific repo to monitor (default: current directory's repo)
  -h, --help         Show this help message

State:
  Review state is stored in: $STATE_FILE

Examples:
  ./pr-review-poll.sh                     # Start daemon with defaults
  ./pr-review-poll.sh --interval 60       # Poll every minute
  ./pr-review-poll.sh --once              # Check once and exit
  ./pr-review-poll.sh --repo user/repo    # Monitor specific repo

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --interval)
            POLL_INTERVAL="$2"
            shift 2
            ;;
        --once)
            RUN_ONCE=true
            shift
            ;;
        --repo)
            REPO="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Get repo from git if not specified
if [[ -z "$REPO" ]]; then
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
    if [[ -z "$REPO" ]]; then
        echo -e "${RED}Error: Could not determine repository. Use --repo flag or run from a git repo.${NC}"
        exit 1
    fi
fi

# Ensure state file exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo '{}' > "$STATE_FILE"
fi

# Send notification
send_notification() {
    local pr_number="$1"
    local pr_title="$2"
    local reviewer="$3"
    local review_state="$4"

    local title="PR Review: #${pr_number}"
    local message=""
    local sound="Ping"

    case "$review_state" in
        APPROVED)
            message="Approved by @${reviewer}"
            sound="Glass"
            ;;
        CHANGES_REQUESTED)
            message="Changes requested by @${reviewer}"
            sound="Basso"
            ;;
        COMMENTED)
            message="@${reviewer} left a comment"
            sound="Ping"
            ;;
        *)
            message="Reviewed by @${reviewer}"
            sound="Ping"
            ;;
    esac

    # Add suggestion to run /pr-review
    message="${message}. Run /pr-review to respond."

    # Sanitize strings for shell safety
    local safe_title safe_message safe_pr_title
    safe_title=$(sanitize_for_applescript "$title")
    safe_message=$(sanitize_for_applescript "$message")
    safe_pr_title=$(sanitize_for_applescript "$pr_title")

    # Use osascript for macOS notification
    osascript -e "display notification \"$safe_message\" with title \"$safe_title\" sound name \"$sound\"" 2>/dev/null || true

    # Also use terminal-notifier if available
    if command -v terminal-notifier &> /dev/null; then
        terminal-notifier \
            -title "$safe_title" \
            -subtitle "$safe_pr_title" \
            -message "$safe_message" \
            -sound "$sound" \
            -group "pr-review-$pr_number" \
            -activate "com.apple.Terminal" 2>/dev/null || true
    fi

    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} Notified: PR #$pr_number - $review_state by @$reviewer"
}

# Get state for a PR
get_pr_state() {
    local pr_number="$1"
    jq -r ".\"$pr_number\" // \"{}\"" "$STATE_FILE"
}

# Update state for a PR
update_pr_state() {
    local pr_number="$1"
    local last_review_id="$2"
    local last_comment_count="$3"
    local review_decision="$4"

    local tmp_file=$(mktemp)
    jq --arg pr "$pr_number" \
       --arg rid "$last_review_id" \
       --arg cc "$last_comment_count" \
       --arg rd "$review_decision" \
       '.[$pr] = {"last_review_id": $rid, "comment_count": $cc, "review_decision": $rd, "checked_at": now}' \
       "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
}

# Remove state for closed/merged PRs
cleanup_state() {
    local open_prs="$1"  # comma-separated list of open PR numbers

    local tmp_file=$(mktemp)
    jq --arg open "$open_prs" '
        ($open | split(",")) as $open_list |
        with_entries(select(.key | IN($open_list[])))
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
}

# Check PRs for new reviews
check_prs() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} Checking PRs for $REPO..."

    # Get user's open PRs
    local prs
    prs=$(gh api "repos/$REPO/pulls?state=open" \
        --jq '.[] | select(.user.login == env.USER or .user.login == "'$(gh api user -q .login)'") | {number, title, reviewDecision: .reviewDecision}' 2>/dev/null) || true

    if [[ -z "$prs" ]]; then
        # Try alternative approach
        prs=$(gh pr list --repo "$REPO" --author "@me" --state open --json number,title 2>/dev/null) || true
    fi

    if [[ -z "$prs" || "$prs" == "[]" ]]; then
        echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} No open PRs found"
        return 0
    fi

    # Get list of open PR numbers for cleanup
    local open_pr_numbers
    open_pr_numbers=$(echo "$prs" | jq -r '.number' | tr '\n' ',' | sed 's/,$//')

    # Process each PR (use process substitution to avoid subshell)
    while read -r pr; do
        [[ -z "$pr" ]] && continue

        local pr_number pr_title
        pr_number=$(echo "$pr" | jq -r '.number')
        pr_title=$(echo "$pr" | jq -r '.title')

        # Get reviews for this PR
        local reviews
        reviews=$(gh api "repos/$REPO/pulls/$pr_number/reviews" --jq '
            [.[] | {id, user: .user.login, state, submitted_at}] | sort_by(.submitted_at) | last
        ' 2>/dev/null) || true

        if [[ -z "$reviews" || "$reviews" == "null" ]]; then
            continue
        fi

        local latest_review_id latest_reviewer latest_state
        latest_review_id=$(echo "$reviews" | jq -r '.id // ""')
        latest_reviewer=$(echo "$reviews" | jq -r '.user // ""')
        latest_state=$(echo "$reviews" | jq -r '.state // ""')

        # Get current state
        local current_state
        current_state=$(get_pr_state "$pr_number")
        local stored_review_id
        stored_review_id=$(echo "$current_state" | jq -r '.last_review_id // ""')

        # Check if there's a new review
        if [[ -n "$latest_review_id" && "$latest_review_id" != "$stored_review_id" ]]; then
            send_notification "$pr_number" "$pr_title" "$latest_reviewer" "$latest_state"

            # Get comment count
            local comment_count
            comment_count=$(gh api "repos/$REPO/pulls/$pr_number/comments" --jq 'length' 2>/dev/null) || comment_count="0"

            # Get review decision
            local review_decision
            review_decision=$(gh api "repos/$REPO/pulls/$pr_number" --jq '.reviewDecision // ""' 2>/dev/null) || review_decision=""

            update_pr_state "$pr_number" "$latest_review_id" "$comment_count" "$review_decision"
        fi
    done < <(echo "$prs" | jq -c '.')

    # Cleanup state for closed PRs
    if [[ -n "$open_pr_numbers" ]]; then
        cleanup_state "$open_pr_numbers"
    fi

    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} Check complete"
}

# Main loop
main() {
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           PR Review Polling Daemon                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "📦 Repository: ${GREEN}$REPO${NC}"
    echo -e "⏱️  Interval: ${GREEN}${POLL_INTERVAL}s${NC}"
    echo -e "📁 State file: ${GREEN}$STATE_FILE${NC}"
    echo ""

    if [[ "$RUN_ONCE" == "true" ]]; then
        echo -e "${YELLOW}Running once...${NC}"
        check_prs
        exit 0
    fi

    echo -e "${GREEN}Starting daemon... (Ctrl+C to stop)${NC}"
    echo ""

    while true; do
        check_prs
        echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} Next check in ${POLL_INTERVAL}s"
        sleep "$POLL_INTERVAL"
    done
}

# Run main
main
