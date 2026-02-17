#!/bin/bash
# Uninstall symlinks for dev-km skills
# Removes symlinks from ~/.claude/skills/ that point to dev-km/skills/*

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$HOME/.claude/skills"

# All skills to remove
SKILLS=(
    mem
    focus
    td
    recap
    distill
    improve
    commit
    pr
    review
    pr-review
    pr-poll
    cleanup
    consolidate
    summary
    search
    jira
    example
    flow
    pattern
    share
    permission
    code-reviewer
    session-analyzer
    knowledge-curator
    build-validator
    code-simplifier
    security-auditor
)

echo "Uninstalling dev-km skill symlinks..."
echo ""

for skill in "${SKILLS[@]}"; do
    target="$SKILLS_DIR/$skill"

    if [ -L "$target" ]; then
        # Only remove if it's a symlink pointing to our skills
        current=$(readlink "$target")
        if [[ "$current" == *"dev-km/skills/"* ]]; then
            rm "$target"
            echo "  REMOVED: $skill"
        else
            echo "  SKIP: $skill (points to $current, not dev-km)"
        fi
    elif [ -e "$target" ]; then
        echo "  SKIP: $skill (not a symlink)"
    else
        echo "  SKIP: $skill (not found)"
    fi
done

echo ""
echo "Done. Symlinks cleaned up."
