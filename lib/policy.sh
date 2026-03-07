#!/bin/bash
# lib/policy.sh — Policy loading and boundary checking for Argos
# Reads YAML policy files and provides functions to check action tiers,
# approval modes, and guardrails.

load_policy() {
  local policy_file="$1"
  if [[ ! -f "$policy_file" ]]; then
    echo '{}'
    return 1
  fi
  python3 -c "
import yaml, json, sys
with open(sys.argv[1]) as f:
    print(json.dumps(yaml.safe_load(f)))
" "$policy_file"
}

get_action_tier() {
  local action="$1"
  jq -r --arg action "$action" '
    if (.actions.auto // [] | any(. == $action)) then "auto"
    elif (.actions.approve // [] | any(. == $action)) then "approve"
    elif (.actions.deny // [] | any(. == $action)) then "deny"
    else "deny"
    end
  '
}

get_approval_mode() {
  local action="$1"
  jq -r --arg action "$action" '
    .approval_modes[$action].mode // "wait"
  '
}

get_approval_timeout() {
  local action="$1"
  jq -r --arg action "$action" '
    .approval_modes[$action].timeout // "24h"
  '
}

get_poll_interval() {
  jq -r '.poll_interval // "5m"'
}

get_filter_labels() {
  jq -r '.filters.labels // []'
}

get_ignore_labels() {
  jq -r '.filters.ignore_labels // []'
}

get_max_age() {
  jq -r '.filters.max_age // "7d"' | sed 's/d//'
}

is_dry_run() {
  jq -r '.guardrails.dry_run // false'
}

get_guardrail() {
  local key="$1"
  jq -r --arg key "$key" '.guardrails[$key] // ""'
}

is_path_protected() {
  local filepath="$1"
  local protected_patterns
  protected_patterns=$(jq -r '.guardrails.protected_paths // [] | .[]')
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    # Use bash pattern matching for glob-style checks
    # shellcheck disable=SC2254
    case "$filepath" in
      $pattern) return 0 ;;
    esac
  done <<< "$protected_patterns"
  return 1
}

get_notification_channels() {
  local event_type="$1"
  jq -r --arg event "$event_type" '.notifications[$event] // [] | .[]'
}
