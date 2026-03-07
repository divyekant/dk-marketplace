#!/bin/bash
# lib/adapters/session.sh — Write to session context file for CC SessionStart hook
set -euo pipefail

ARGOS_SESSION_FILE="${ARGOS_SESSION_FILE:-$HOME/.claude/argos/session-context.txt}"
mkdir -p "$(dirname "$ARGOS_SESSION_FILE")"

PAYLOAD=$(cat)
REPO=$(echo "$PAYLOAD" | jq -r '.repo')
ISSUE=$(echo "$PAYLOAD" | jq -r '.issue')
ACTION=$(echo "$PAYLOAD" | jq -r '.action')
DETAILS=$(echo "$PAYLOAD" | jq -r '.details')
EVENT=$(echo "$PAYLOAD" | jq -r '.event')

# SECURITY: Sanitize details to prevent stored prompt injection via session file
# The session file is read by hooks and surfaced to Claude in future sessions
SAFE_DETAILS=$(echo "$DETAILS" | tr -cd '[:alnum:][:space:]._#/-:(),' | head -c 200)
echo "[$EVENT] $REPO#$ISSUE: $ACTION — $SAFE_DETAILS" >> "$ARGOS_SESSION_FILE"
