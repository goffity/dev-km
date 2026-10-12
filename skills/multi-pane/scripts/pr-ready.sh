#!/usr/bin/env bash
# pr-ready.sh owner/repo <PR> — one line: state, head, Copilot reviewed the head?, unresolved threads, mergeable, checks.
# Use before telling the user a PR is ready, and after merge to confirm it was a merge commit (parents=2).
repo=$1; n=$2; export GH_TOKEN="${GITHUB_TOKEN:-$GH_TOKEN}"; o=${repo%/*}; r=${repo#*/}
gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){state mergeable headRefOid mergeCommit{oid parents{totalCount}} reviews(last:30){nodes{author{login} commit{oid}}} reviewThreads(first:100){nodes{isResolved}}}}}' \
  -f o="$o" -f r="$r" -F n="$n" -q '.data.repository.pullRequest as $p | ($p.headRefOid) as $h |
  "'"$repo#$n"' state=\($p.state) mergeable=\($p.mergeable) head=\($h[0:7]) copilot_on_head=\([$p.reviews.nodes[]|select((.author.login|test("copilot";"i")) and .commit.oid==$h)]|length>0) unresolved=\([$p.reviewThreads.nodes[]|select(.isResolved==false)]|length)" + (if $p.mergeCommit then " merge_parents=\($p.mergeCommit.parents.totalCount)" else "" end)'
gh pr checks "$n" -R "$repo" 2>/dev/null | awk '{printf "  %s:%s", $1, $2} END {print ""}'
