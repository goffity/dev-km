#!/bin/bash
# Knowledge Management System - Init Script
# Usage: ./init.sh [project-root]

set -e

PROJECT_ROOT="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Initializing Knowledge Management System..."
echo "   Project: $PROJECT_ROOT"
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p "$PROJECT_ROOT/docs/learnings"
mkdir -p "$PROJECT_ROOT/docs/knowledge-base"
mkdir -p "$PROJECT_ROOT/docs/retrospective"
mkdir -p "$PROJECT_ROOT/docs/auto-captured"
mkdir -p "$PROJECT_ROOT/.claude/commands"
mkdir -p "$PROJECT_ROOT/.claude/scripts"

# Copy command files from assets (all .md files except README.md)
echo "📄 Copying command files..."
if [ -d "$SKILL_ROOT/assets/commands" ]; then
    for file in "$SKILL_ROOT/assets/commands"/*.md; do
        filename=$(basename "$file")
        if [ "$filename" != "README.md" ]; then
            cp "$file" "$PROJECT_ROOT/.claude/commands/"
            echo "   - $filename"
        fi
    done
fi

# Copy scripts
echo "📜 Copying scripts..."
if [ -f "$SKILL_ROOT/scripts/notify.sh" ]; then
    cp "$SKILL_ROOT/scripts/notify.sh" "$PROJECT_ROOT/.claude/scripts/"
    chmod +x "$PROJECT_ROOT/.claude/scripts/notify.sh"
    echo "   - notify.sh"
fi

# Copy hooks.json example
echo "🔗 Copying hooks example..."
if [ -f "$SKILL_ROOT/hooks.json" ]; then
    cp "$SKILL_ROOT/hooks.json" "$PROJECT_ROOT/.claude/hooks.example.json"
    echo "   - hooks.example.json"
fi

# Create .gitkeep files
touch "$PROJECT_ROOT/docs/learnings/.gitkeep"
touch "$PROJECT_ROOT/docs/knowledge-base/.gitkeep"
touch "$PROJECT_ROOT/docs/retrospective/.gitkeep"
touch "$PROJECT_ROOT/docs/auto-captured/.gitkeep"

echo ""
echo "✅ Knowledge Management System initialized!"
echo ""
echo "📂 Structure created:"
echo "   $PROJECT_ROOT/"
echo "   ├── .claude/"
echo "   │   ├── commands/        (slash commands)"
echo "   │   ├── scripts/         (notify.sh)"
echo "   │   └── hooks.example.json"
echo "   └── docs/"
echo "       ├── learnings/"
echo "       ├── knowledge-base/"
echo "       ├── retrospective/"
echo "       └── auto-captured/"
echo ""
echo "📝 Next steps:"
echo "   1. Add to git: git add .claude/ docs/"
echo "   2. Commit: git commit -m 'feat: add Knowledge Management System'"
echo "   3. (Optional) Enable notifications:"
echo "      - Copy hooks.example.json to settings.json"
echo "      - Update script paths to match your project"
echo ""
echo "🎯 Commands:"
echo "   /mem [topic]     - Quick knowledge capture"
echo "   /distill [topic] - Extract patterns"
echo "   /td              - Post-task retrospective"
echo "   /improve         - Work on pending items"
echo ""
echo "🔔 Notifications:"
echo "   notify.sh sends macOS notifications when Claude needs attention"
