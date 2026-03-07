#!/bin/bash
# lib/adapters/system.sh — macOS native notification
set -euo pipefail

PAYLOAD=$(cat)
TITLE=$(echo "$PAYLOAD" | jq -r '"Argos: " + .repo')
BODY=$(echo "$PAYLOAD" | jq -r '.action + " on #" + (.issue | tostring) + ": " + .title')
EVENT=$(echo "$PAYLOAD" | jq -r '.event')

# Sanitize for AppleScript string interpolation (untrusted input from issues)
SAFE_BODY=$(echo "$BODY" | tr -cd '[:alnum:][:space:]._#\-:')
SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:][:space:]._#/\-:')
SAFE_EVENT=$(echo "$EVENT" | tr -cd '[:alnum:][:space:]._\-:')

if [[ "$(uname)" == "Darwin" ]]; then
  osascript -e "display notification \"$SAFE_BODY\" with title \"$SAFE_TITLE\" subtitle \"$SAFE_EVENT\"" 2>/dev/null || true
fi
