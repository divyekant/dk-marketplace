#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"

# Find the latest version directory
VERSION_DIR=$(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | sort -V | tail -1)

if [ -z "$VERSION_DIR" ]; then
    echo "Error: Could not find superpowers plugin directory at $SKILLS_DIR"
    echo "Make sure you have the superpowers plugin installed in Claude Code."
    exit 1
fi

DEST="${VERSION_DIR}skills/think-different"
mkdir -p "$DEST"
cp "$SCRIPT_DIR/SKILL.md" "$DEST/SKILL.md"

echo "think-different skill installed to: $DEST"
echo ""
echo "Restart Claude Code to pick up the new skill."
echo "Usage: invoke with /think-different or say 'use the think-different skill'"
