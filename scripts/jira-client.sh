#!/bin/bash
# Jira API Client for Claude KM Skill
# Supports Atlassian Cloud (*.atlassian.net)

set -e

# =============================================================================
# Dependency Checks
# =============================================================================

check_dependencies() {
    local missing=()
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v curl >/dev/null 2>&1 || missing+=("curl")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing[*]}" >&2
        echo "Please install them and try again." >&2
        return 1
    fi
}

# Run dependency check early (except for help)
if [[ "${1:-}" != "help" ]] && [[ "${1:-}" != "--help" ]] && [[ "${1:-}" != "-h" ]] && [[ -n "${1:-}" ]]; then
    check_dependencies || exit 1
fi

# =============================================================================
# Input Validation
# =============================================================================

# Validate issue key format (PROJECT-123)
validate_issue_key() {
    local key="$1"
    if [[ ! "$key" =~ ^[A-Z][A-Z0-9]+-[0-9]+$ ]]; then
        echo "Error: Invalid issue key format: $key" >&2
        echo "Expected format: PROJECT-123 (e.g., PROJ-42)" >&2
        return 1
    fi
}

# Validate transition ID (numeric)
validate_transition_id() {
    local id="$1"
    if [[ ! "$id" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid transition ID: $id" >&2
        echo "Transition ID must be numeric" >&2
        return 1
    fi
}

# =============================================================================
# Configuration
# =============================================================================

# Config file location (project-level or user-level)
JIRA_CONFIG_FILE="${JIRA_CONFIG_FILE:-.jira-config}"
JIRA_USER_CONFIG="$HOME/.config/claude-km/jira.conf"

# Load config from file if exists
load_config() {
    # Try project-level config first
    if [[ -f "$JIRA_CONFIG_FILE" ]]; then
        source "$JIRA_CONFIG_FILE"
    # Then try user-level config
    elif [[ -f "$JIRA_USER_CONFIG" ]]; then
        source "$JIRA_USER_CONFIG"
    fi
}

# Required environment variables (can be set in config file):
# JIRA_DOMAIN - e.g., "mycompany.atlassian.net"
# JIRA_EMAIL - e.g., "user@example.com"
# JIRA_API_TOKEN - API token from https://id.atlassian.com/manage-profile/security/api-tokens
# JIRA_PROJECT - default project key, e.g., "PROJ"

load_config

# Validate required config
validate_config() {
    local missing=()
    [[ -z "$JIRA_DOMAIN" ]] && missing+=("JIRA_DOMAIN")
    [[ -z "$JIRA_EMAIL" ]] && missing+=("JIRA_EMAIL")
    [[ -z "$JIRA_API_TOKEN" ]] && missing+=("JIRA_API_TOKEN")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required configuration: ${missing[*]}" >&2
        echo "" >&2
        echo "Set these in one of:" >&2
        echo "  1. Environment variables" >&2
        echo "  2. Project config: $JIRA_CONFIG_FILE" >&2
        echo "  3. User config: $JIRA_USER_CONFIG" >&2
        echo "" >&2
        echo "Run: jira-client.sh init" >&2
        return 1
    fi

    # Sanitize JIRA_DOMAIN: strip protocol and trailing slash
    JIRA_DOMAIN="${JIRA_DOMAIN#https://}"
    JIRA_DOMAIN="${JIRA_DOMAIN#http://}"
    JIRA_DOMAIN="${JIRA_DOMAIN%/}"

    # Validate domain format
    if [[ ! "$JIRA_DOMAIN" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
        echo "Error: Invalid JIRA_DOMAIN format: $JIRA_DOMAIN" >&2
        echo "Expected: company.atlassian.net (without https://)" >&2
        return 1
    fi
}

# Base URL for API calls
get_base_url() {
    echo "https://${JIRA_DOMAIN}/rest/api/3"
}

# =============================================================================
# API Helper Functions
# =============================================================================

# Make authenticated API request
jira_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    local url="$(get_base_url)${endpoint}"
    local auth=$(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)

    local curl_args=(
        -s
        -X "$method"
        -H "Authorization: Basic $auth"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )

    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi

    curl "${curl_args[@]}" "$url"
}

# =============================================================================
# Commands
# =============================================================================

# Initialize configuration
cmd_init() {
    local domain="" email="" token="" project=""
    local config_type="project"
    local config_file

    # Parse arguments for non-interactive mode
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --domain)
                [[ -z "${2:-}" || "$2" == --* ]] && { echo "Error: --domain requires a value" >&2; return 1; }
                domain="$2"; shift 2 ;;
            --email)
                [[ -z "${2:-}" || "$2" == --* ]] && { echo "Error: --email requires a value" >&2; return 1; }
                email="$2"; shift 2 ;;
            --token)
                [[ -z "${2:-}" || "$2" == --* ]] && { echo "Error: --token requires a value" >&2; return 1; }
                token="$2"; shift 2 ;;
            --project)
                [[ -z "${2:-}" || "$2" == --* ]] && { echo "Error: --project requires a value" >&2; return 1; }
                project="$2"; shift 2 ;;
            --location)
                [[ -z "${2:-}" || "$2" == --* ]] && { echo "Error: --location requires a value" >&2; return 1; }
                [[ "$2" != "project" && "$2" != "user" ]] && { echo "Error: --location must be 'project' or 'user'" >&2; return 1; }
                config_type="$2"; shift 2 ;;
            user|project) config_type="$1"; shift ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Usage: jira-client.sh init --domain X --email Y --token Z --project P [--location project|user]" >&2
                return 1
                ;;
        esac
    done

    if [[ "$config_type" == "user" ]]; then
        config_file="$JIRA_USER_CONFIG"
        mkdir -p "$(dirname "$config_file")"
    else
        config_file="$JIRA_CONFIG_FILE"
    fi

    # If arguments not fully provided, fall back to interactive mode
    if [[ -z "$domain" ]] || [[ -z "$email" ]] || [[ -z "$token" ]] || [[ -z "$project" ]]; then
        # Check if running in interactive terminal
        if [[ ! -t 0 ]]; then
            echo "Error: Non-interactive mode detected but required arguments missing." >&2
            echo "" >&2
            echo "Usage: jira-client.sh init --domain X --email Y --token Z --project P [--location project|user]" >&2
            echo "" >&2
            echo "Arguments:" >&2
            echo "  --domain    Jira domain (e.g., mycompany.atlassian.net)" >&2
            echo "  --email     Your Atlassian account email" >&2
            echo "  --token     API token from https://id.atlassian.com/manage-profile/security/api-tokens" >&2
            echo "  --project   Default project key (e.g., PROJ)" >&2
            echo "  --location  Config location: 'project' (default) or 'user'" >&2
            return 1
        fi

        echo "Jira Configuration Setup"
        echo "========================"
        echo ""

        [[ -z "$domain" ]] && read -p "Jira Domain (e.g., mycompany.atlassian.net): " domain
        [[ -z "$email" ]] && read -p "Email: " email
        [[ -z "$token" ]] && { read -sp "API Token: " token; echo ""; }
        [[ -z "$project" ]] && read -p "Default Project Key (e.g., PROJ): " project
    fi

    # Validate required fields
    if [[ -z "$domain" ]] || [[ -z "$email" ]] || [[ -z "$token" ]] || [[ -z "$project" ]]; then
        echo "Error: All fields are required (domain, email, token, project)" >&2
        return 1
    fi

    # Format validation
    if [[ ! "$domain" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
        echo "Error: Invalid domain format. Expected something like 'mycompany.atlassian.net'." >&2
        return 1
    fi

    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo "Error: Invalid email format. Expected something like 'user@example.com'." >&2
        return 1
    fi

    if [[ ! "$project" =~ ^[A-Z][A-Z0-9]*$ ]]; then
        echo "Error: Invalid project key format. Use uppercase letters and numbers (e.g., 'PROJ')." >&2
        return 1
    fi

    cat > "$config_file" << EOF
# Jira Configuration
# Generated: $(date '+%Y-%m-%d %H:%M')

JIRA_DOMAIN="$domain"
JIRA_EMAIL="$email"
JIRA_API_TOKEN="$token"
JIRA_PROJECT="$project"
EOF

    chmod 600 "$config_file"

    echo "Configuration saved to: $config_file"

    # Add to .gitignore if project-level
    if [[ "$config_type" != "user" ]] && [[ -f ".gitignore" ]]; then
        if ! grep -q "^\.jira-config$" .gitignore 2>/dev/null; then
            echo ".jira-config" >> .gitignore
            echo "Added .jira-config to .gitignore"
        fi
    fi
}

# Test connection
cmd_test() {
    validate_config || return 1

    echo "Testing connection to ${JIRA_DOMAIN}..."
    local result=$(jira_api GET "/myself")

    if echo "$result" | jq -e '.accountId' > /dev/null 2>&1; then
        local name=$(echo "$result" | jq -r '.displayName')
        local email=$(echo "$result" | jq -r '.emailAddress')
        echo "Connected as: $name ($email)"
        return 0
    else
        echo "Connection failed:" >&2
        echo "$result" | jq -r '.errorMessages[]?' 2>/dev/null || echo "$result" >&2
        return 1
    fi
}

# List projects
cmd_projects() {
    validate_config || return 1

    local result=$(jira_api GET "/project")
    echo "$result" | jq -r '.[] | "\(.key)\t\(.name)"' | column -t -s $'\t'
}

# Create issue
cmd_create() {
    validate_config || return 1

    local project="${1:-$JIRA_PROJECT}"
    local summary="$2"
    local description="$3"
    local issue_type="${4:-Task}"

    if [[ -z "$project" ]] || [[ -z "$summary" ]]; then
        echo "Usage: jira-client.sh create <project> <summary> [description] [issue_type]" >&2
        return 1
    fi

    # Build payload using jq for safe JSON escaping
    local payload
    if [[ -n "$description" ]]; then
        payload=$(jq -n \
            --arg project "$project" \
            --arg summary "$summary" \
            --arg description "$description" \
            --arg issue_type "$issue_type" \
            '{
                fields: {
                    project: { key: $project },
                    summary: $summary,
                    description: {
                        type: "doc",
                        version: 1,
                        content: [{
                            type: "paragraph",
                            content: [{
                                type: "text",
                                text: $description
                            }]
                        }]
                    },
                    issuetype: { name: $issue_type }
                }
            }')
    else
        payload=$(jq -n \
            --arg project "$project" \
            --arg summary "$summary" \
            --arg issue_type "$issue_type" \
            '{
                fields: {
                    project: { key: $project },
                    summary: $summary,
                    issuetype: { name: $issue_type }
                }
            }')
    fi

    local result=$(jira_api POST "/issue" "$payload")

    if echo "$result" | jq -e '.key' > /dev/null 2>&1; then
        local key=$(echo "$result" | jq -r '.key')
        # Info messages to stderr, key to stdout for programmatic use
        echo "Created: $key" >&2
        echo "URL: https://${JIRA_DOMAIN}/browse/$key" >&2
        echo "$key"
    else
        echo "Failed to create issue:" >&2
        echo "$result" | jq -r '.errors // .errorMessages[]?' 2>/dev/null || echo "$result" >&2
        return 1
    fi
}

# Get issue details
cmd_get() {
    validate_config || return 1

    local issue_key="$1"

    if [[ -z "$issue_key" ]]; then
        echo "Usage: jira-client.sh get <issue_key>" >&2
        return 1
    fi

    validate_issue_key "$issue_key" || return 1

    local result=$(jira_api GET "/issue/$issue_key")

    if echo "$result" | jq -e '.key' > /dev/null 2>&1; then
        echo "$result" | jq '{
            key: .key,
            summary: .fields.summary,
            status: .fields.status.name,
            type: .fields.issuetype.name,
            priority: .fields.priority.name,
            assignee: (.fields.assignee.displayName // "Unassigned"),
            reporter: .fields.reporter.displayName,
            created: .fields.created,
            updated: .fields.updated,
            url: "https://'"${JIRA_DOMAIN}"'/browse/\(.key)"
        }'
    else
        echo "Issue not found: $issue_key" >&2
        return 1
    fi
}

# List issues (with JQL)
cmd_list() {
    validate_config || return 1

    local project="${1:-$JIRA_PROJECT}"
    local status="${2:-}"
    local max_results="${3:-20}"

    local jql="project = $project"
    if [[ -n "$status" ]]; then
        jql="$jql AND status = '$status'"
    fi
    jql="$jql ORDER BY updated DESC"

    local encoded_jql=$(echo "$jql" | jq -sRr @uri)
    local result=$(jira_api GET "/search?jql=$encoded_jql&maxResults=$max_results&fields=key,summary,status,issuetype,priority,assignee")

    echo "$result" | jq -r '.issues[] | "\(.key)\t\(.fields.status.name)\t\(.fields.summary)"' | column -t -s $'\t'
}

# Search issues by text
cmd_search() {
    validate_config || return 1

    local query="$1"
    local project="${2:-$JIRA_PROJECT}"
    local max_results="${3:-20}"

    if [[ -z "$query" ]]; then
        echo "Usage: jira-client.sh search <query> [project] [max_results]" >&2
        return 1
    fi

    local jql="text ~ \"$query\""
    if [[ -n "$project" ]]; then
        jql="project = $project AND $jql"
    fi
    jql="$jql ORDER BY updated DESC"

    local encoded_jql=$(echo "$jql" | jq -sRr @uri)
    local result=$(jira_api GET "/search?jql=$encoded_jql&maxResults=$max_results&fields=key,summary,status,issuetype")

    echo "$result" | jq -r '.issues[] | "\(.key)\t\(.fields.status.name)\t\(.fields.summary)"' | column -t -s $'\t'
}

# Get available transitions for an issue
cmd_transitions() {
    validate_config || return 1

    local issue_key="$1"

    if [[ -z "$issue_key" ]]; then
        echo "Usage: jira-client.sh transitions <issue_key>" >&2
        return 1
    fi

    validate_issue_key "$issue_key" || return 1

    local result=$(jira_api GET "/issue/$issue_key/transitions")
    echo "$result" | jq -r '.transitions[] | "\(.id)\t\(.name)"' | column -t -s $'\t'
}

# Transition issue to new status
cmd_transition() {
    validate_config || return 1

    local issue_key="$1"
    local transition_id="$2"

    if [[ -z "$issue_key" ]] || [[ -z "$transition_id" ]]; then
        echo "Usage: jira-client.sh transition <issue_key> <transition_id>" >&2
        echo "Use 'jira-client.sh transitions <issue_key>' to see available transitions" >&2
        return 1
    fi

    validate_issue_key "$issue_key" || return 1
    validate_transition_id "$transition_id" || return 1

    # Build payload using jq for safe JSON
    local payload=$(jq -n --arg id "$transition_id" '{transition: {id: $id}}')
    local result=$(jira_api POST "/issue/$issue_key/transitions" "$payload")

    # Jira API returns 204 No Content on success (empty response)
    if [[ -z "$result" ]]; then
        echo "Transitioned $issue_key successfully"
        # Show new status
        cmd_get "$issue_key" | jq -r '"New status: \(.status)"'
    else
        echo "Failed to transition:" >&2
        echo "$result" >&2
        return 1
    fi
}

# Add comment to issue
cmd_comment() {
    validate_config || return 1

    local issue_key="$1"
    local comment="$2"

    if [[ -z "$issue_key" ]] || [[ -z "$comment" ]]; then
        echo "Usage: jira-client.sh comment <issue_key> <comment>" >&2
        return 1
    fi

    validate_issue_key "$issue_key" || return 1

    # Build payload using jq for safe JSON escaping
    local payload=$(jq -n --arg comment "$comment" '{
        body: {
            type: "doc",
            version: 1,
            content: [{
                type: "paragraph",
                content: [{
                    type: "text",
                    text: $comment
                }]
            }]
        }
    }')

    local result=$(jira_api POST "/issue/$issue_key/comment" "$payload")

    if echo "$result" | jq -e '.id' > /dev/null 2>&1; then
        echo "Comment added to $issue_key"
    else
        echo "Failed to add comment:" >&2
        echo "$result" >&2
        return 1
    fi
}

# Assign issue
cmd_assign() {
    validate_config || return 1

    local issue_key="$1"
    local account_id="$2"  # Use -1 for unassigned, or account ID

    if [[ -z "$issue_key" ]]; then
        echo "Usage: jira-client.sh assign <issue_key> [account_id|-1|me]" >&2
        return 1
    fi

    validate_issue_key "$issue_key" || return 1

    # Get current user's account ID if "me"
    if [[ "$account_id" == "me" ]]; then
        account_id=$(jira_api GET "/myself" | jq -r '.accountId')
    fi

    # Build payload using jq for safe JSON escaping
    local payload
    if [[ "$account_id" == "-1" ]] || [[ -z "$account_id" ]]; then
        payload='{"accountId": null}'
    else
        payload=$(jq -n --arg id "$account_id" '{accountId: $id}')
    fi

    local result=$(jira_api PUT "/issue/$issue_key/assignee" "$payload")

    # Jira API returns 204 No Content on success (empty response)
    if [[ -z "$result" ]]; then
        if [[ "$account_id" == "-1" ]] || [[ -z "$account_id" ]]; then
            echo "Unassigned $issue_key"
        else
            echo "Assigned $issue_key"
        fi
    else
        echo "Failed to assign:" >&2
        echo "$result" >&2
        return 1
    fi
}

# Get my assigned issues
cmd_my_issues() {
    validate_config || return 1

    local status="${1:-}"
    local max_results="${2:-20}"

    local jql="assignee = currentUser()"
    if [[ -n "$status" ]]; then
        jql="$jql AND status = '$status'"
    fi
    jql="$jql ORDER BY updated DESC"

    local encoded_jql=$(echo "$jql" | jq -sRr @uri)
    local result=$(jira_api GET "/search?jql=$encoded_jql&maxResults=$max_results&fields=key,summary,status,issuetype,project")

    echo "$result" | jq -r '.issues[] | "\(.key)\t\(.fields.status.name)\t\(.fields.summary)"' | column -t -s $'\t'
}

# Show status/config info
cmd_status() {
    echo "=== Jira Client Configuration ==="
    echo ""

    if [[ -f "$JIRA_CONFIG_FILE" ]]; then
        echo "Project config: $JIRA_CONFIG_FILE (found)"
    else
        echo "Project config: $JIRA_CONFIG_FILE (not found)"
    fi

    if [[ -f "$JIRA_USER_CONFIG" ]]; then
        echo "User config: $JIRA_USER_CONFIG (found)"
    else
        echo "User config: $JIRA_USER_CONFIG (not found)"
    fi

    echo ""
    echo "Current settings:"
    echo "  Domain: ${JIRA_DOMAIN:-<not set>}"
    echo "  Email: ${JIRA_EMAIL:-<not set>}"
    # Never expose token value - only show if set or not
    if [[ -n "$JIRA_API_TOKEN" ]]; then
        echo "  Token: <set>"
    else
        echo "  Token: <not set>"
    fi
    echo "  Project: ${JIRA_PROJECT:-<not set>}"
}

# =============================================================================
# Main
# =============================================================================

show_help() {
    cat << EOF
Jira API Client for Claude KM Skill

Usage: jira-client.sh <command> [arguments]

Configuration Commands:
  init [options]         Initialize configuration
                        Options: --domain, --email, --token, --project, --location
  test                  Test connection
  status                Show configuration status

Issue Commands:
  create <project> <summary> [description] [type]
                        Create new issue
  get <issue_key>       Get issue details
  list [project] [status] [max]
                        List issues in project
  search <query> [project] [max]
                        Search issues by text
  my-issues [status] [max]
                        List my assigned issues

Status Commands:
  transitions <issue_key>
                        List available transitions
  transition <issue_key> <transition_id>
                        Transition issue to new status

Other Commands:
  comment <issue_key> <comment>
                        Add comment to issue
  assign <issue_key> [account_id|me|-1]
                        Assign issue (me=self, -1=unassign)
  projects              List available projects

Examples:
  jira-client.sh init
  jira-client.sh init --domain myco.atlassian.net --email me@co.com --token XXXX --project PROJ
  jira-client.sh init --domain myco.atlassian.net --email me@co.com --token XXXX --project PROJ --location user
  jira-client.sh create PROJ "Fix login bug" "Users can't login" Bug
  jira-client.sh list PROJ "In Progress"
  jira-client.sh transition PROJ-123 31
  jira-client.sh my-issues "To Do"

Environment Variables:
  JIRA_DOMAIN           Jira domain (e.g., company.atlassian.net)
  JIRA_EMAIL            Your Atlassian account email
  JIRA_API_TOKEN        API token from Atlassian
  JIRA_PROJECT          Default project key

Security Note:
  Passing --token via CLI args exposes it in process list and shell history.
  Prefer setting JIRA_API_TOKEN env var or using interactive mode for sensitive tokens.
EOF
}

# Main command dispatcher
main() {
    local command="${1:-}"

    # Show help when no command or explicit help flag
    if [[ -z "$command" || "$command" == "help" || "$command" == "--help" || "$command" == "-h" ]]; then
        show_help
        return 0
    fi

    # Shift past command name (safe here because we know $1 exists)
    shift

    case "$command" in
        init)        cmd_init "$@" ;;
        test)        cmd_test "$@" ;;
        status)      cmd_status "$@" ;;
        projects)    cmd_projects "$@" ;;
        create)      cmd_create "$@" ;;
        get)         cmd_get "$@" ;;
        list)        cmd_list "$@" ;;
        search)      cmd_search "$@" ;;
        my-issues)   cmd_my_issues "$@" ;;
        transitions) cmd_transitions "$@" ;;
        transition)  cmd_transition "$@" ;;
        comment)     cmd_comment "$@" ;;
        assign)      cmd_assign "$@" ;;
        *)
            echo "Unknown command: $command" >&2
            echo "Run 'jira-client.sh help' for usage" >&2
            return 1
            ;;
    esac
}

main "$@"
