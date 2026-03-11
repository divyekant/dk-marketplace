#!/bin/bash
# lib/policy.sh — Policy loading and boundary checking for Argos
# Reads YAML policy files and provides functions to check confidence floors,
# deny lists, and notification channels.

load_policy() {
  local policy_file="${1:-}"
  local project_root="${2:-}"
  local resolved=""

  # 1. In-repo policy takes priority
  if [[ -n "$project_root" && -f "$project_root/.argos/policy.yaml" ]]; then
    resolved="$project_root/.argos/policy.yaml"
  # 2. Fallback to explicit policy file
  elif [[ -n "$policy_file" && -f "$policy_file" ]]; then
    resolved="$policy_file"
  fi

  if [[ -z "$resolved" ]]; then
    echo '{}'
    return 1
  fi

  python3 -c "
import yaml, json, sys
with open(sys.argv[1]) as f:
    print(json.dumps(yaml.safe_load(f)))
" "$resolved"
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

get_floor_for_path() {
  local filepath="$1"
  local max_floor=0
  local entries
  entries=$(jq -r '.floors.paths // {} | to_entries[] | "\(.key)\t\(.value)"')
  while IFS=$'\t' read -r pattern level; do
    [[ -z "$pattern" ]] && continue
    # shellcheck disable=SC2254
    case "$filepath" in
      $pattern)
        [[ "$level" -gt "$max_floor" ]] && max_floor="$level"
        ;;
    esac
  done <<< "$entries"
  echo "$max_floor"
}

get_floor_for_type() {
  local issue_type="$1"
  jq -r --arg t "$issue_type" '.floors.types[$t] // 0'
}

get_floor_for_author() {
  local author="$1"
  jq -r --arg a "$author" '
    if (.floors.authors.trusted // [] | any(. == $a)) then 0
    else .floors.authors.unknown // 0
    end
  '
}

get_minimum_floor() {
  jq -r '.floors.minimum // 0'
}

apply_floors() {
  local ai_level="$1" issue_type="$2" author="$3" affected_paths="$4"
  local policy_json
  policy_json=$(cat)
  local max_level="$ai_level"

  local min_floor
  min_floor=$(echo "$policy_json" | get_minimum_floor)
  [[ "$min_floor" -gt "$max_level" ]] && max_level="$min_floor"

  local type_floor
  type_floor=$(echo "$policy_json" | get_floor_for_type "$issue_type")
  [[ "$type_floor" -gt "$max_level" ]] && max_level="$type_floor"

  local author_floor
  author_floor=$(echo "$policy_json" | get_floor_for_author "$author")
  [[ "$author_floor" -gt "$max_level" ]] && max_level="$author_floor"

  while IFS= read -r fpath; do
    [[ -z "$fpath" ]] && continue
    local path_floor
    path_floor=$(echo "$policy_json" | get_floor_for_path "$fpath")
    [[ "$path_floor" -gt "$max_level" ]] && max_level="$path_floor"
  done <<< "$affected_paths"

  echo "$max_level"
}

is_action_denied() {
  local action="$1"
  jq -e --arg a "$action" '.deny.actions // [] | any(. == $a)' > /dev/null 2>&1
}

is_path_denied() {
  local filepath="$1"
  local patterns
  patterns=$(jq -r '.deny.paths // [] | .[]')
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    # shellcheck disable=SC2254
    case "$filepath" in
      $pattern) return 0 ;;
    esac
  done <<< "$patterns"
  return 1
}

check_policy_format() {
  # Returns 0 if policy uses new format (floors), 1 if old format (actions), 2 if empty/invalid
  local input
  input=$(cat)
  if echo "$input" | jq -e '.floors' > /dev/null 2>&1; then
    return 0
  elif echo "$input" | jq -e '.actions' > /dev/null 2>&1; then
    return 1
  else
    return 2
  fi
}

get_pr_enabled() {
  jq -r '.prs.enabled // false'
}

get_pr_ignore_authors() {
  jq -r '[.prs.ignore_authors // [] | .[]] | join(",")'
}

get_pr_ignore_labels() {
  jq -r '[.prs.ignore_labels // [] | .[]] | join(",")'
}

get_pr_noise_budget() {
  jq -r '.prs.review.noise_budget // 10'
}

get_pr_auto_approve() {
  jq -r '.prs.review.auto_approve // false'
}

get_pr_lenses() {
  jq -r '[.prs.review.lenses // [] | .[]] | join(",")'
}

get_channel_type() {
  local channel_name="$1"
  jq -r --arg name "$channel_name" '
    .notifications.channels // [] | map(select(.name == $name)) | .[0].type // "internal"
  '
}

get_channels_by_type() {
  local channel_type="$1"
  jq -r --arg t "$channel_type" '
    .notifications.channels // [] | map(select(.type == $t)) | .[].name
  '
}
