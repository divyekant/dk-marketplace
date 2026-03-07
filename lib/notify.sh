#!/bin/bash
# lib/notify.sh — Notification dispatcher for Argos
# Routes notifications to pluggable adapters based on policy config

ARGOS_PLUGIN_ROOT="${ARGOS_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ARGOS_ADAPTER_DIR="${ARGOS_ADAPTER_DIR:-$ARGOS_PLUGIN_ROOT/lib/adapters}"

build_payload() {
  local event="$1" repo="$2" issue="$3" title="$4" action="$5" details="$6"
  jq -n \
    --arg event "$event" \
    --arg repo "$repo" \
    --argjson issue "$issue" \
    --arg title "$title" \
    --arg action "$action" \
    --arg details "$details" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
      event: $event,
      repo: $repo,
      issue: $issue,
      title: $title,
      action: $action,
      details: $details,
      timestamp: $timestamp
    }'
}

dispatch_to_adapter() {
  local adapter_name="$1"
  # SECURITY: Validate adapter name to prevent path traversal (e.g. ../../tmp/evil)
  if [[ ! "$adapter_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: invalid adapter name '$adapter_name' — must be alphanumeric/hyphen/underscore only" >&2
    return 1
  fi
  local adapter_script="$ARGOS_ADAPTER_DIR/${adapter_name}.sh"
  if [[ -x "$adapter_script" ]]; then
    cat | bash "$adapter_script"
  else
    echo "Warning: adapter '$adapter_name' not found at $adapter_script" >&2
  fi
}

notify() {
  local event="$1" repo="$2" issue="$3" title="$4" action="$5" details="$6"
  shift 6
  local adapters=("$@")
  local payload
  payload=$(build_payload "$event" "$repo" "$issue" "$title" "$action" "$details")
  for adapter in "${adapters[@]}"; do
    echo "$payload" | dispatch_to_adapter "$adapter" &
  done
  wait
}
