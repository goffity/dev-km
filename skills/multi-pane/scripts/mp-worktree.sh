#!/usr/bin/env bash
# mp-worktree.sh <repo-dir> <TICKET> [--base <ref>] [--slug <words>] — make sure a worktree + branch for TICKET exists,
# print its absolute path on stdout (everything else goes to stderr).
#
# Why: a worker opened straight in a shared checkout inherits whatever branch that checkout happens to be on
# (e.g. an old merged feature branch) and starts committing there. Every code-changing worker gets its own
# worktree on its own ticket branch instead.
#
# - worktree path: <parent>/<repo>-wt-<ticket number>   (e.g. ~/Development/kol/kol-report-wt-2402)
# - branch: reuse a local branch whose name contains TICKET, else create feat/<TICKET>-<slug> from the base
# - base: --base, else origin/develop if it exists, else origin's default branch (fetched first)
# - never touches the shared checkout's working tree; never deletes anything
set -euo pipefail
usage() { echo "usage: mp-worktree.sh <repo-dir> <TICKET> [--base <ref>] [--slug <words>]" >&2; exit 64; }
[ $# -ge 2 ] || usage
dir=$1; ticket=$2; shift 2
base=''; slug=''
while [ $# -gt 0 ]; do
  case $1 in
    --base) base=${2:?}; shift 2 ;;
    --slug) slug=${2:?}; shift 2 ;;
    *) usage ;;
  esac
done
[[ $ticket =~ ^[A-Z][A-Z0-9]+-[0-9]+$ ]] || { echo "bad ticket '$ticket' (expected e.g. RUAYS-2402)" >&2; exit 64; }

# the main checkout of the repo, even if <repo-dir> is itself a worktree or a subdirectory
common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || { echo "not a git repo: $dir" >&2; exit 65; }
repo=$(dirname "$common")
num=${ticket##*-}
wt="$(dirname "$repo")/$(basename "$repo")-wt-$num"

# already have a worktree for this ticket? reuse it
# whole-ticket match: RUAYS-240 must not match RUAYS-2402
re="(^|[^A-Za-z0-9])$ticket([^0-9]|\$)"
existing=$(git -C "$repo" worktree list --porcelain | awk -v re="$re" '
  /^worktree /{p=substr($0,10)} /^branch /{b=substr($0,19); if (b ~ re) {print p; exit}}')
if [ -n "$existing" ]; then
  echo "reuse worktree $existing ($(git -C "$existing" branch --show-current))" >&2
  [ "$existing" = "$repo" ] && echo "WARN: that is the shared checkout itself — other sessions working there will see this worker's changes" >&2
  echo "$existing"; exit 0
fi
if [ -e "$wt" ]; then
  echo "path $wt exists but is not a worktree of $ticket — pick another dir or clean it up by hand" >&2; exit 73
fi

git -C "$repo" fetch --quiet origin || echo "WARN: fetch failed, using local refs" >&2
if [ -z "$base" ]; then
  if git -C "$repo" rev-parse --verify --quiet origin/develop >/dev/null; then base=origin/develop
  else base=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main); fi
fi

branch=$(git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads/ | grep -E "$re" | head -1 || true)
if [ -n "$branch" ]; then
  echo "branch $branch already exists — checking it out in $wt (base ignored)" >&2
  git -C "$repo" worktree add --quiet "$wt" "$branch" >&2
else
  s=$(printf '%s' "${slug:-work}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//; s/-*$//' | cut -c1-40)
  branch="feat/$ticket-${s:-work}"
  echo "new branch $branch from $base in $wt" >&2
  git -C "$repo" worktree add --quiet -b "$branch" "$wt" "$base" >&2
fi
echo "$wt"
