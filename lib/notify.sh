#!/bin/bash
# lib/notify.sh — Notification dispatcher for Argos
# Routes notifications to pluggable adapters with audience-aware content

ARGOS_PLUGIN_ROOT="${ARGOS_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ARGOS_ADAPTER_DIR="${ARGOS_ADAPTER_DIR:-$ARGOS_PLUGIN_ROOT/lib/adapters}"

build_payload() {
  local event="$1" repo="$2" issue="$3" title="$4" action="$5" content_external="$6" content_internal="$7"
  jq -n \
    --arg event "$event" \
    --arg repo "$repo" \
    --argjson issue "$issue" \
    --arg title "$title" \
    --arg action "$action" \
    --arg content_external "$content_external" \
    --arg content_internal "$content_internal" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
      event: $event,
      repo: $repo,
      issue: $issue,
      title: $title,
      action: $action,
      content_external: $content_external,
      content_internal: $content_internal,
      timestamp: $timestamp
    }'
}

build_pr_payload() {
  local repo="$1" pr_number="$2" title="$3" pr_type="$4" level="$5" findings_count="$6" diff_url="$7" findings_summary="$8"
  jq -n \
    --arg repo "$repo" \
    --argjson number "$pr_number" \
    --arg title "$title" \
    --arg item_type "pr" \
    --arg pr_type "$pr_type" \
    --argjson level "$level" \
    --argjson findings_count "$findings_count" \
    --arg diff_url "$diff_url" \
    --arg findings_summary "$findings_summary" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
      repo: $repo,
      number: $number,
      title: $title,
      item_type: $item_type,
      pr_type: $pr_type,
      level: $level,
      findings_count: $findings_count,
      diff_url: $diff_url,
      findings_summary: $findings_summary,
      timestamp: $timestamp
    }'
}

dispatch_to_adapter() {
  local adapter_name="$1"
  local channel_type="${2:-internal}"
  # SECURITY: Validate adapter name to prevent path traversal
  if [[ ! "$adapter_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: invalid adapter name '$adapter_name' — must be alphanumeric/hyphen/underscore only" >&2
    return 1
  fi
  local adapter_script="$ARGOS_ADAPTER_DIR/${adapter_name}.sh"
  if [[ -x "$adapter_script" ]]; then
    # Select the right content field based on channel type and inject as 'details'
    local content_field="content_internal"
    [[ "$channel_type" == "external" ]] && content_field="content_external"
    cat | jq --arg field "$content_field" '. + {details: .[$field]}' | bash "$adapter_script"
  else
    echo "Warning: adapter '$adapter_name' not found at $adapter_script" >&2
  fi
}

notify() {
  local event="$1" repo="$2" issue="$3" title="$4" action="$5" content_external="$6" content_internal="$7"
  shift 7
  # Remaining args are "name:type" pairs (e.g., "github_comment:external" "system:internal")
  local channels=("$@")
  local payload
  payload=$(build_payload "$event" "$repo" "$issue" "$title" "$action" "$content_external" "$content_internal")
  for channel in "${channels[@]}"; do
    local name="${channel%%:*}"
    local type="${channel##*:}"
    echo "$payload" | dispatch_to_adapter "$name" "$type" &
  done
  wait
}
