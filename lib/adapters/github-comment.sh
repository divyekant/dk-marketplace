#!/bin/bash
# lib/adapters/github-comment.sh — Post a comment on the GitHub issue
set -euo pipefail

PAYLOAD=$(cat)
REPO=$(echo "$PAYLOAD" | jq -r '.repo')
ISSUE=$(echo "$PAYLOAD" | jq -r '.issue')
EVENT=$(echo "$PAYLOAD" | jq -r '.event')
ACTION=$(echo "$PAYLOAD" | jq -r '.action')
DETAILS=$(echo "$PAYLOAD" | jq -r '.details')
TIMESTAMP=$(echo "$PAYLOAD" | jq -r '.timestamp')

# Wrap details in code block to prevent markdown injection from untrusted input
# SECURITY: Use printf and --body-file to avoid shell expansion of untrusted content
COMMENT=$(printf '**Argos** (`%s`)\n\n**Action:** `%s`\n**Details:**\n```\n%s\n```\n**Time:** %s' \
  "$EVENT" "$ACTION" "$DETAILS" "$TIMESTAMP")

printf '%s' "$COMMENT" | gh issue comment "$ISSUE" --repo "$REPO" --body-file - 2>/dev/null || true
