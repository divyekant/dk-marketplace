#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"

echo "=== Skill Conductor Uninstaller ==="
echo ""

SKILL_NAMES=(conductor shaping breadboarding breadboard-reflection)

for skill_name in "${SKILL_NAMES[@]}"; do
    target_path="$SKILLS_DIR/$skill_name"

    if [ -L "$target_path" ]; then
        existing_target="$(readlink "$target_path")"
        # Only remove if it points to our project
        if [[ "$existing_target" == "$SCRIPT_DIR"* ]]; then
            rm "$target_path"
            echo "  Removed: $skill_name"

            # Restore backup if it exists
            if [ -e "${target_path}.bak" ]; then
                mv "${target_path}.bak" "$target_path"
                echo "  Restored: ${skill_name}.bak → $skill_name"
            fi
        else
            echo "  Skipped: $skill_name (points to $existing_target, not ours)"
        fi
    else
        echo "  Skipped: $skill_name (not a symlink)"
    fi
done

echo ""
echo "Uninstall complete. Other skills in ~/.claude/skills/ are unaffected."
