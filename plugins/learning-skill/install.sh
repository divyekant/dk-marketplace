#!/bin/bash
# install.sh — Install the learning skill and hook
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"
HOOKS_DIR="$HOME/.claude/hooks/memory"
SETTINGS="$HOME/.claude/settings.json"

# Find the superpowers version directory
VERSION_DIR=$(ls -d "$SKILLS_DIR"/*/skills 2>/dev/null | head -1)
if [ -z "$VERSION_DIR" ]; then
  echo "Error: superpowers plugin not found at $SKILLS_DIR"
  exit 1
fi

# Install skill
echo "Installing skill..."
mkdir -p "$VERSION_DIR/learning"
cp "$SCRIPT_DIR/skill/SKILL.md" "$VERSION_DIR/learning/SKILL.md"
echo "  -> $VERSION_DIR/learning/SKILL.md"

# Install hook (only if memories hooks directory exists)
if [ -d "$HOOKS_DIR" ]; then
  echo "Installing hook..."
  cp "$SCRIPT_DIR/hook/learning-extract.sh" "$HOOKS_DIR/learning-extract.sh"
  chmod +x "$HOOKS_DIR/learning-extract.sh"
  echo "  -> $HOOKS_DIR/learning-extract.sh"

  # Add hook to settings.json if not already present
  if ! grep -q "learning-extract.sh" "$SETTINGS" 2>/dev/null; then
    echo "Adding hook to settings.json..."
    TMP=$(mktemp)
    jq '.hooks.Stop[0].hooks += [{"type": "command", "command": "'"$HOOKS_DIR"'/learning-extract.sh", "timeout": 30}]' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
    echo "  -> Added Stop hook to settings.json"
  else
    echo "  -> Hook already in settings.json"
  fi
else
  echo "Skipping hook install (no memories hooks directory at $HOOKS_DIR)"
fi

echo ""
echo "Done! Restart Claude Code (/restart) to pick up the new skill."
