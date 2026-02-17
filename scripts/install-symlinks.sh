#!/bin/bash
# Install symlinks for dev-km skills
# Creates symlinks in ~/.claude/skills/ pointing to dev-km/skills/*

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$HOME/.claude/skills"

# All skills to symlink (21 user-invocable + 6 specialists)
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

echo "Installing dev-km skill symlinks..."
echo "  Source: $SKILL_ROOT/skills/"
echo "  Target: $SKILLS_DIR/"
echo ""

mkdir -p "$SKILLS_DIR"

for skill in "${SKILLS[@]}"; do
    target="$SKILLS_DIR/$skill"
    source="$SKILL_ROOT/skills/$skill"

    if [ ! -d "$source" ]; then
        echo "  SKIP: $skill (source not found)"
        continue
    fi

    if [ -L "$target" ]; then
        # Symlink exists - check if it points to the right place
        current=$(readlink "$target")
        if [ "$current" = "$source" ]; then
            echo "  OK: $skill (already linked)"
        else
            rm "$target"
            ln -s "$source" "$target"
            echo "  UPDATED: $skill -> $source"
        fi
    elif [ -e "$target" ]; then
        echo "  SKIP: $skill (path exists and is not a symlink)"
    else
        ln -s "$source" "$target"
        echo "  CREATED: $skill -> $source"
    fi
done

echo ""
echo "Done. ${#SKILLS[@]} skills processed."
