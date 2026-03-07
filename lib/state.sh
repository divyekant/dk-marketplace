#!/bin/bash
# lib/state.sh — State management for Argos
# Manages per-repo state: seen issues, pending approvals, action counts

ARGOS_STATE_DIR="${ARGOS_STATE_DIR:-$HOME/.claude/argos/state}"

_state_file() {
  local repo="$1"
  local safe_name="${repo//\//-}"
  echo "$ARGOS_STATE_DIR/$safe_name.json"
}

init_state() {
  local repo="$1"
  local state_file
  state_file=$(_state_file "$repo")
  mkdir -p "$(dirname "$state_file")"
  if [[ ! -f "$state_file" ]]; then
    cat > "$state_file" <<'INIT'
{
  "last_poll": null,
  "last_issue_seen": 0,
  "pending_approvals": [],
  "actions_this_hour": 0,
  "actions_hour_start": null
}
INIT
  fi
}

get_last_issue_seen() {
  local repo="$1"
  jq -r '.last_issue_seen // 0' "$(_state_file "$repo")"
}

set_last_issue_seen() {
  local repo="$1" issue_num="$2"
  local state_file
  state_file=$(_state_file "$repo")
  local tmp="${state_file}.tmp.$$"
  jq --argjson num "$issue_num" '.last_issue_seen = $num | .last_poll = (now | todate)' "$state_file" > "$tmp"
  mv "$tmp" "$state_file"
}

add_pending_approval() {
  local repo="$1" issue_num="$2" action="$3" mode="$4" summary="$5"
  local state_file
  state_file=$(_state_file "$repo")
  local tmp="${state_file}.tmp.$$"
  jq --argjson num "$issue_num" \
     --arg action "$action" \
     --arg mode "$mode" \
     --arg summary "$summary" \
     '.pending_approvals += [{
       "issue": $num,
       "action": $action,
       "proposed_at": (now | todate),
       "mode": $mode,
       "summary": $summary
     }]' "$state_file" > "$tmp"
  mv "$tmp" "$state_file"
}

remove_pending_approval() {
  local repo="$1" issue_num="$2" action="${3:-}"
  local state_file
  state_file=$(_state_file "$repo")
  local tmp="${state_file}.tmp.$$"
  if [[ -n "$action" ]]; then
    jq --argjson num "$issue_num" --arg action "$action" \
       '.pending_approvals = [.pending_approvals[] | select(.issue != $num or .action != $action)]' "$state_file" > "$tmp"
  else
    jq --argjson num "$issue_num" \
       '.pending_approvals = [.pending_approvals[] | select(.issue != $num)]' "$state_file" > "$tmp"
  fi
  mv "$tmp" "$state_file"
}

get_pending_count() {
  local repo="$1"
  jq '.pending_approvals | length' "$(_state_file "$repo")"
}

get_pending_approvals() {
  local repo="$1"
  jq -r '.pending_approvals' "$(_state_file "$repo")"
}

increment_actions_count() {
  local repo="$1"
  local state_file
  state_file=$(_state_file "$repo")
  local tmp="${state_file}.tmp.$$"
  local current_hour
  current_hour=$(date -u +"%Y-%m-%dT%H")
  local stored_hour
  stored_hour=$(jq -r '.actions_hour_start // ""' "$state_file")
  if [[ "$stored_hour" != "$current_hour" ]]; then
    jq --arg hour "$current_hour" \
       '.actions_this_hour = 1 | .actions_hour_start = $hour' "$state_file" > "$tmp"
  else
    jq '.actions_this_hour += 1' "$state_file" > "$tmp"
  fi
  mv "$tmp" "$state_file"
}

get_actions_this_hour() {
  local repo="$1"
  local state_file
  state_file=$(_state_file "$repo")
  local current_hour
  current_hour=$(date -u +"%Y-%m-%dT%H")
  local stored_hour
  stored_hour=$(jq -r '.actions_hour_start // ""' "$state_file")
  if [[ "$stored_hour" != "$current_hour" ]]; then
    echo "0"
  else
    jq -r '.actions_this_hour // 0' "$state_file"
  fi
}

check_rate_limit() {
  local repo="$1" max="$2"
  local count
  count=$(get_actions_this_hour "$repo")
  [[ "$count" -lt "$max" ]]
}
