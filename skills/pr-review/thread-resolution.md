# Thread Resolution - GraphQL Helpers

GraphQL helper functions for resolving PR review conversation threads.

## Helper Functions

### Get Thread ID from Comment ID (with pagination)

Supports PRs with >100 review threads.

```bash
get_thread_id_for_comment() {
    local owner="$1"
    local repo="$2"
    local pr_number="$3"
    local comment_id="$4"
    local cursor=""
    local thread_id=""

    while [[ -z "$thread_id" ]]; do
        local cursor_arg=""
        if [[ -n "$cursor" && "$cursor" != "null" ]]; then
            cursor_arg="-f cursor=$cursor"
        fi

        # shellcheck disable=SC2086
        local result=$(gh api graphql -f query='
            query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
                repository(owner: $owner, name: $repo) {
                    pullRequest(number: $pr) {
                        reviewThreads(first: 100, after: $cursor) {
                            pageInfo {
                                hasNextPage
                                endCursor
                            }
                            nodes {
                                id
                                isResolved
                                comments(first: 1) {
                                    nodes {
                                        databaseId
                                    }
                                }
                            }
                        }
                    }
                }
            }
        ' -f owner="$owner" -f repo="$repo" -F pr="$pr_number" $cursor_arg)

        # Find thread_id using --argjson for safe variable passing
        thread_id=$(echo "$result" | jq -r --argjson commentId "$comment_id" '
            .data.repository.pullRequest.reviewThreads.nodes[] |
            select(.comments.nodes[0].databaseId == $commentId) | .id // empty
        ')

        # Check for more pages
        local has_next=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
        cursor=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')

        if [[ "$has_next" != "true" || -z "$cursor" || "$cursor" == "null" ]]; then
            break
        fi
    done

    echo "$thread_id"
}
```

### Resolve Thread by ID

```bash
resolve_thread() {
    local thread_id="$1"

    if [[ -z "$thread_id" ]]; then
        echo "Warning: No thread_id provided, skipping resolve"
        return 1
    fi

    gh api graphql -f query='
        mutation($threadId: ID!) {
            resolveReviewThread(input: {threadId: $threadId}) {
                thread {
                    id
                    isResolved
                }
            }
        }
    ' -f threadId="$thread_id" --jq '.data.resolveReviewThread.thread.isResolved'
}
```

## Usage - Resolve After Reply

```bash
# 1. Reply to comment (per Step 6.1-6.5 in SKILL.md)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="Fixed in ${COMMIT_HASH}! [description]"

# 2. Get thread_id and resolve immediately
THREAD_ID=$(get_thread_id_for_comment "$owner" "$repo" "$pr_number" "$comment_id")
if [[ -n "$THREAD_ID" ]]; then
    resolve_thread "$THREAD_ID" && echo "Resolved thread for comment $comment_id"
else
    echo "Could not find thread for comment $comment_id (may already be resolved)"
fi
```

## When to Resolve

| Comment Type | Resolve? | Reason |
|--------------|----------|--------|
| Fixed (6.1) | Yes | Work is done |
| Won't fix (6.2) | Yes | Decision made, explained |
| Question answered (6.3) | Yes | Question addressed |
| Praise acknowledged (6.4) | Yes | No action needed |
| Deferred with issue (6.5) | Yes | Tracked in issue |

## When NOT to Resolve

- Reviewer explicitly asks to verify before resolving
- Ongoing discussion (multiple back-and-forth)
- Blocking concern that needs approval

## Error Handling

```bash
# Handle permission errors gracefully
resolve_thread "$THREAD_ID" 2>/dev/null || echo "Could not resolve (permission or already resolved)"
```

## Example - Multiple Comments

```bash
# Setup
OWNER="owner"
REPO="repo"
PR_NUMBER=42
COMMIT_HASH=$(git rev-parse --short HEAD)

# Comment 1: ต้องแก้ไข (comment_id: 123)
gh api repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/123/replies \
  -f body="Fixed in $COMMIT_HASH! Changed context.Background() to context.WithTimeout(ctx, 30*time.Second)"
THREAD_ID=$(get_thread_id_for_comment "$OWNER" "$REPO" "$PR_NUMBER" 123)
resolve_thread "$THREAD_ID" && echo "Resolved comment 123"

# Comment 2: ไม่แก้ไข (comment_id: 124)
gh api repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/124/replies \
  -f body="Good point! However, I kept this approach because..."
THREAD_ID=$(get_thread_id_for_comment "$OWNER" "$REPO" "$PR_NUMBER" 124)
resolve_thread "$THREAD_ID" && echo "Resolved comment 124"

# Comment 3: Defer (comment_id: 126)
DEFER_ISSUE=$(gh issue create \
  --title "test: add unit tests for auth handler" \
  --label "enhancement" \
  --body "From PR #42 review by @senior-dev..." \
  --json number -q .number)
gh api repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/126/replies \
  -f body="Thanks for the feedback! Created #$DEFER_ISSUE to track this work."
THREAD_ID=$(get_thread_id_for_comment "$OWNER" "$REPO" "$PR_NUMBER" 126)
resolve_thread "$THREAD_ID" && echo "Resolved comment 126"
```

## Verify All Threads Resolved (Fallback)

Primary resolve happens inline in Steps 6.1-6.5. Step 6.6 runs this check for verification and catching missed threads.

```bash
check_unresolved_threads() {
    local owner="$1"
    local repo="$2"
    local pr_number="$3"

    local count=$(gh api graphql -f query='
        query($owner: String!, $repo: String!, $pr: Int!) {
            repository(owner: $owner, name: $repo) {
                pullRequest(number: $pr) {
                    reviewThreads(first: 100) {
                        nodes {
                            isResolved
                        }
                    }
                }
            }
        }
    ' -f owner="$owner" -f repo="$repo" -F pr="$pr_number" \
      --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)] | length')

    echo "$count unresolved threads"
}
```

## Batch Thread Resolution (for missed threads)

```bash
get_thread_id() {
    local pr_number="$1"
    local owner="${REPO%%/*}"
    local repo="${REPO##*/}"
    local cursor=""
    local all_threads="[]"

    while true; do
        local cursor_arg=""
        if [[ -n "$cursor" && "$cursor" != "null" ]]; then
            cursor_arg="-f cursor=$cursor"
        fi

        # shellcheck disable=SC2086
        local result=$(gh api graphql -f query='
            query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
                repository(owner: $owner, name: $repo) {
                    pullRequest(number: $pr) {
                        reviewThreads(first: 100, after: $cursor) {
                            pageInfo {
                                hasNextPage
                                endCursor
                            }
                            nodes {
                                id
                                isResolved
                                comments(first: 1) {
                                    nodes {
                                        id
                                        databaseId
                                    }
                                }
                            }
                        }
                    }
                }
            }
        ' -f owner="$owner" -f repo="$repo" -F pr="$pr_number" $cursor_arg)

        local page_threads=$(echo "$result" | jq '.data.repository.pullRequest.reviewThreads.nodes // []')
        all_threads=$(jq -n --argjson all "$all_threads" --argjson page "$page_threads" '$all + $page')

        local has_next=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
        cursor=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')

        if [[ "$has_next" != "true" || -z "$cursor" || "$cursor" == "null" ]]; then
            break
        fi
    done

    echo "$all_threads"
}
```
