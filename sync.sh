#!/usr/bin/env bash
# Sync all plugins from their source repos into the marketplace.
# Run this whenever plugins have been updated.
#
# Usage: ./sync.sh [plugin-name]
#   No args: syncs all plugins
#   With arg: syncs only that plugin

set -euo pipefail

PLUGINS=(
  "update-checker|https://github.com/divyekant/update-checker.git|main"
  "learning-skill|https://github.com/divyekant/learning-skill.git|main"
  "skill-conductor|https://github.com/divyekant/skill-conductor.git|main"
  "apollo|https://github.com/divyekant/apollo.git|main"
  "delphi|https://github.com/divyekant/delphi.git|main"
  "hermes|https://github.com/divyekant/hermes.git|main"
  "think-different|https://github.com/divyekant/think-different.git|main"
  "ui-val|https://github.com/divyekant/ui-val.git|main"
  "claude-code-restart|https://github.com/divyekant/claude-code-restart.git|main"
  "carto|https://github.com/divyekant/carto.git|master"
)

sync_plugin() {
  local name="$1" repo="$2" branch="$3"
  echo "Syncing $name from $branch..."
  if git subtree pull --prefix="plugins/$name" "$repo" "$branch" --squash \
       -m "chore: sync $name" 2>&1 | tail -3; then
    echo "  OK: $name synced"
  else
    echo "  SKIP: $name already up to date"
  fi
  echo ""
}

FILTER="${1:-}"

for entry in "${PLUGINS[@]}"; do
  IFS='|' read -r name repo branch <<< "$entry"
  if [ -n "$FILTER" ] && [ "$FILTER" != "$name" ]; then
    continue
  fi
  sync_plugin "$name" "$repo" "$branch"
done

echo "Done. Run 'git push origin main' to publish."
