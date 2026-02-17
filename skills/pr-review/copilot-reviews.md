# Handling Copilot Reviews

GitHub Copilot reviews are automatically triggered on PRs. They have some differences from human reviews.

## Detection

```bash
# Check if reviewer is Copilot
COPILOT_REVIEWER="copilot-pull-request-reviewer"

if [[ "$reviewer" == "$COPILOT_REVIEWER" ]]; then
    echo "This is a Copilot review"
fi
```

## Key Differences

| Aspect | Human Review | Copilot Review |
|--------|-------------|----------------|
| Review State | APPROVED, CHANGES_REQUESTED, COMMENTED | Usually COMMENTED |
| Response Time | Can wait | Can be processed immediately |
| Thread Resolution | Ask reviewer first | Can auto-resolve after fixing |
| Learning Value | High (contextual) | Medium (pattern-based) |

## Processing Copilot Comments

1. **All Copilot comments can be auto-resolved** after addressing
2. **No need to wait for re-review** - Copilot will review again on next push
3. **Batch process** - Fix all comments, then resolve all threads

```bash
# After fixing all Copilot comments:
# 1. Commit all fixes
git add -A
git commit -m "fix: address Copilot review comments"

# 2. Resolve all Copilot threads (with pagination for >100 threads)
resolve_all_copilot_threads() {
    local pr_number="$1"
    local cursor=""
    local owner="${REPO%%/*}"
    local repo="${REPO##*/}"

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
                                        author { login }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        ' -f owner="$owner" -f repo="$repo" -F pr="$pr_number" $cursor_arg)

        # Resolve unresolved Copilot threads in this page
        echo "$result" | jq -r '
            .data.repository.pullRequest.reviewThreads.nodes[] |
            select(.isResolved == false) |
            select(.comments.nodes[0]?.author?.login == "copilot-pull-request-reviewer") |
            .id
        ' | while read -r thread_id; do
            [[ -z "$thread_id" ]] && continue
            gh api graphql -f query='
                mutation($threadId: ID!) {
                    resolveReviewThread(input: {threadId: $threadId}) {
                        thread { isResolved }
                    }
                }
            ' -f threadId="$thread_id"
        done

        # Check for more pages
        local has_next=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
        cursor=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')

        if [[ "$has_next" != "true" || -z "$cursor" || "$cursor" == "null" ]]; then
            break
        fi
    done
}

resolve_all_copilot_threads "$pr_number"

# 3. Push to trigger new Copilot review
git push
```

## Example Session

```bash
# PR #42 has Copilot review with 3 comments
# All comments are suggestions about code quality

# 1. Fix all issues
# ... make changes ...

# 2. Commit
git add -A
git commit -m "fix: address Copilot review comments"

# 3. Reply to each comment
COMMIT_HASH=$(git rev-parse --short HEAD)
for comment_id in 201 202 203; do
    gh api repos/$OWNER/$REPO/pulls/42/comments/$comment_id/replies \
      -f body="Fixed in $COMMIT_HASH"
done

# 4. Resolve all Copilot threads
resolve_all_copilot_threads 42

# 5. Push
git push
```
