#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"

SKILL_NAMES=(conductor shaping breadboarding breadboard-reflection)
SKILL_PATHS=(
    "$SCRIPT_DIR/skills/conductor"
    "$SCRIPT_DIR/vendor/shaping-skills/shaping"
    "$SCRIPT_DIR/vendor/shaping-skills/breadboarding"
    "$SCRIPT_DIR/vendor/shaping-skills/breadboard-reflection"
)

echo "=== Skill Conductor Installer ==="
echo ""

# 1. Initialize/update git submodules
echo "[1/3] Updating vendor submodules..."
cd "$SCRIPT_DIR"
git submodule update --init --recursive
echo "  Done."

# 2. Ensure skills directory exists
mkdir -p "$SKILLS_DIR"

# 3. Create symlinks
echo ""
echo "[2/3] Symlinking skills to $SKILLS_DIR..."

for i in "${!SKILL_NAMES[@]}"; do
    skill_name="${SKILL_NAMES[$i]}"
    source_path="${SKILL_PATHS[$i]}"
    target_path="$SKILLS_DIR/$skill_name"

    if [ -L "$target_path" ]; then
        existing_target="$(readlink "$target_path")"
        if [ "$existing_target" = "$source_path" ]; then
            echo "  $skill_name: already linked (skipped)"
            continue
        else
            echo "  $skill_name: symlink exists -> $existing_target"
            read -p "    Override? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm "$target_path"
            else
                echo "    Skipped."
                continue
            fi
        fi
    elif [ -e "$target_path" ]; then
        echo "  $skill_name: exists at $target_path (not a symlink)"
        read -p "    Override? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "    Backing up to ${target_path}.bak"
            mv "$target_path" "${target_path}.bak"
        else
            echo "    Skipped."
            continue
        fi
    fi

    ln -s "$source_path" "$target_path"
    echo "  $skill_name: linked"
done

# 4. Summary
echo ""
echo "[3/3] Installation complete."
echo ""
echo "Skills installed to $SKILLS_DIR:"
for skill_name in "${SKILL_NAMES[@]}"; do
    if [ -L "$SKILLS_DIR/$skill_name" ]; then
        echo "  + $skill_name"
    else
        echo "  - $skill_name (not installed)"
    fi
done
echo ""
echo "Customize pipelines.yaml to add your own skills and workflows."
echo "See examples/ for a full setup with superpowers + shaping + review-loop."
echo ""
echo "To uninstall: ./uninstall.sh"
