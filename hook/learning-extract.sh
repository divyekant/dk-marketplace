#!/bin/bash
# learning-extract.sh — Stop hook enhancement
# Extracts failure-to-fix patterns from the last few message pairs.
# Runs alongside memory-extract.sh as an additional Stop hook.

set -euo pipefail

[ -f "${MEMORIES_ENV_FILE:-$HOME/.config/memories/env}" ] && . "${MEMORIES_ENV_FILE:-$HOME/.config/memories/env}"

MEMORIES_URL="${MEMORIES_URL:-http://localhost:8900}"
MEMORIES_API_KEY="${MEMORIES_API_KEY:-}"

# Skip if no API key (memories not configured)
[ -z "$MEMORIES_API_KEY" ] && exit 0

INPUT=$(cat)

CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
PROJECT=$(basename "$CWD")
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Expand tilde if present
TRANSCRIPT_PATH="${TRANSCRIPT_PATH/#\~/$HOME}"

MESSAGES=""

# Read more context than standard extract -- last 500 lines to catch failure-fix arcs
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  MESSAGES=$(tail -500 "$TRANSCRIPT_PATH" 2>/dev/null | jq -sr '
    [
      .[]
      | select(.type == "user" or .type == "assistant")
      | {
          role: .type,
          text: (
            if .message.content | type == "string" then
              .message.content
            elif .message.content | type == "array" then
              [.message.content[] | select(.type == "text") | .text] | join(" ")
            else
              ""
            end
          )
        }
      | select(.text != "" and (.text | length) > 10)
    ]
    | .[-6:]
    | map(.role + ": " + (.text | .[0:2000]))
    | join("\n\n")
  ' 2>/dev/null) || true
fi

if [ -z "$MESSAGES" ] || [ "$MESSAGES" = "null" ]; then
  exit 0
fi

# Cap at 8000 chars (larger window to capture failure-fix arcs)
MESSAGES="${MESSAGES:0:8000}"

# Prompt specifically for learning extraction
LEARNING_PROMPT="Extract any learnings where something was tried and failed, then a different approach worked. Format each as: [LEARNING] <category>: <summary> | TRIED: <what failed> | SOLUTION: <what worked> | CONTEXT: <project/tool>. Categories: debugging, implementation, infra/config, api-usage, tooling. Only extract genuine failure-to-fix patterns, not general facts."

curl -sf -X POST "$MEMORIES_URL/memory/extract" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $MEMORIES_API_KEY" \
  -d "{\"messages\": $(echo "$MESSAGES" | jq -Rs), \"source\": \"learning/$PROJECT\", \"context\": $(echo "$LEARNING_PROMPT" | jq -Rs)}" \
  > /dev/null 2>&1 || true
