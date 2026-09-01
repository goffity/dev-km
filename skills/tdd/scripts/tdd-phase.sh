#!/bin/bash
###########################################
# TDD loop — phase detection
# Detects the current TDD phase from Conventional Commit messages on the
# current branch (commits since merge-base with the base branch), so state
# survives across sessions and ignores unrelated commits (docs, merge)
# made before the branch or between cycles.
#
# Phase markers (Conventional Commits + phase scope):
#   test(red): ...                   → red    (failing test committed)
#   feat(green): / fix(green): ...   → green  (implementation committed)
#   refactor: / refactor(...): ...   → refactor
#
# Output: red | green | refactor | unknown
###########################################

# Base branch: develop preferred (kol convention), else main
if git rev-parse --verify --quiet origin/develop >/dev/null; then
    BASE="origin/develop"
elif git rev-parse --verify --quiet origin/main >/dev/null; then
    BASE="origin/main"
else
    BASE="main"
fi

MERGE_BASE=$(git merge-base HEAD "$BASE" 2>/dev/null)
if [ -z "$MERGE_BASE" ]; then
    echo "unknown"
    exit 0
fi

# Newest branch commit with a phase marker wins
first_marker=$(git log --pretty=%s "$MERGE_BASE"..HEAD 2>/dev/null \
    | grep -m1 -E '^(test\(red\)|feat\(green\)|fix\(green\)|refactor(\([^)]*\))?)!?:')

case "$first_marker" in
    "test(red)"*)                 echo "red" ;;
    "feat(green)"*|"fix(green)"*) echo "green" ;;
    refactor*)                    echo "refactor" ;;
    *)                            echo "unknown" ;;
esac
