#!/bin/bash
# tests/test-state.sh — verify state management functions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/state.sh"

TEMP_DIR=$(mktemp -d)
export ARGOS_STATE_DIR="$TEMP_DIR"
REPO="owner/repo"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Test: init_state creates state file
init_state "$REPO"
STATE_FILE="$TEMP_DIR/owner-repo.json"
if [[ ! -f "$STATE_FILE" ]]; then
  echo "FAIL: init_state did not create state file"
  exit 1
fi
echo "PASS: init_state creates state file"

# Test: get_last_issue_seen returns 0 for new state
LAST=$(get_last_issue_seen "$REPO")
if [[ "$LAST" != "0" ]]; then
  echo "FAIL: expected last_issue_seen=0, got $LAST"
  exit 1
fi
echo "PASS: get_last_issue_seen returns 0 for new state"

# Test: set_last_issue_seen updates value
set_last_issue_seen "$REPO" 42
LAST=$(get_last_issue_seen "$REPO")
if [[ "$LAST" != "42" ]]; then
  echo "FAIL: expected last_issue_seen=42, got $LAST"
  exit 1
fi
echo "PASS: set_last_issue_seen updates value"

# Test: add_pending_approval adds entry
add_pending_approval "$REPO" 42 "open_pr" "wait" "Fix auth bug"
COUNT=$(get_pending_count "$REPO")
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 pending approval, got $COUNT"
  exit 1
fi
echo "PASS: add_pending_approval adds entry"

# Test: remove_pending_approval removes entry
remove_pending_approval "$REPO" 42
COUNT=$(get_pending_count "$REPO")
if [[ "$COUNT" != "0" ]]; then
  echo "FAIL: expected 0 pending approvals, got $COUNT"
  exit 1
fi
echo "PASS: remove_pending_approval removes entry"

# Test: remove_pending_approval with action parameter removes only matching action
add_pending_approval "$REPO" 50 "create_branch" "default" "Create branch for fix"
add_pending_approval "$REPO" 50 "open_pr" "wait" "Open PR for fix"
COUNT=$(get_pending_count "$REPO")
if [[ "$COUNT" != "2" ]]; then
  echo "FAIL: expected 2 pending approvals for issue 50, got $COUNT"
  exit 1
fi
remove_pending_approval "$REPO" 50 "create_branch"
COUNT=$(get_pending_count "$REPO")
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 pending approval after action-specific removal, got $COUNT"
  exit 1
fi
echo "PASS: remove_pending_approval with action removes only matching"
# Clean up
remove_pending_approval "$REPO" 50

# Test: increment_actions_count and check guardrail
increment_actions_count "$REPO"
increment_actions_count "$REPO"
ACTIONS=$(get_actions_this_hour "$REPO")
if [[ "$ACTIONS" != "2" ]]; then
  echo "FAIL: expected 2 actions, got $ACTIONS"
  exit 1
fi
echo "PASS: action counting works"

# Test: check_rate_limit with max=10
if ! check_rate_limit "$REPO" 10; then
  echo "FAIL: should be under rate limit"
  exit 1
fi
echo "PASS: rate limit check passes under limit"

# Test: check_rate_limit fails when over limit
for i in $(seq 1 10); do increment_actions_count "$REPO"; done
if check_rate_limit "$REPO" 10; then
  echo "FAIL: should exceed rate limit at 12 actions (2 + 10)"
  exit 1
fi
echo "PASS: rate limit check fails when over limit"

# Test: is_watched returns 0 for initialized repo
WATCH_REPO="watch-test/is-watched"
init_state "$WATCH_REPO"
if ! is_watched "$WATCH_REPO"; then
  echo "FAIL: is_watched should return 0 for initialized repo"
  exit 1
fi
echo "PASS: is_watched returns 0 for initialized repo"

# Test: is_watched returns 1 for unknown repo
if is_watched "unknown-org/unknown-repo"; then
  echo "FAIL: is_watched should return 1 for unknown repo"
  exit 1
fi
echo "PASS: is_watched returns 1 for unknown repo"

# Test: init_state new fields — project_path, owner_repo, last_pr_seen
FIELDS_REPO="fields-test/new-fields"
export ARGOS_PROJECT_PATH="/tmp/test-project"
init_state "$FIELDS_REPO"
FIELDS_FILE="$TEMP_DIR/fields-test-new-fields.json"
PP=$(jq -r '.project_path' "$FIELDS_FILE")
if [[ "$PP" != "/tmp/test-project" ]]; then
  echo "FAIL: expected project_path=/tmp/test-project, got $PP"
  exit 1
fi
OR=$(jq -r '.owner_repo' "$FIELDS_FILE")
if [[ "$OR" != "fields-test/new-fields" ]]; then
  echo "FAIL: expected owner_repo=fields-test/new-fields, got $OR"
  exit 1
fi
LPR=$(jq -r '.last_pr_seen' "$FIELDS_FILE")
if [[ "$LPR" != "0" ]]; then
  echo "FAIL: expected last_pr_seen=0, got $LPR"
  exit 1
fi
unset ARGOS_PROJECT_PATH
echo "PASS: init_state sets project_path, owner_repo, last_pr_seen"

# Test: get/set_last_pr_seen
PR_REPO="pr-test/pr-seen"
init_state "$PR_REPO"
INIT_PR=$(get_last_pr_seen "$PR_REPO")
if [[ "$INIT_PR" != "0" ]]; then
  echo "FAIL: expected initial last_pr_seen=0, got $INIT_PR"
  exit 1
fi
set_last_pr_seen "$PR_REPO" 18
UPDATED_PR=$(get_last_pr_seen "$PR_REPO")
if [[ "$UPDATED_PR" != "18" ]]; then
  echo "FAIL: expected last_pr_seen=18, got $UPDATED_PR"
  exit 1
fi
echo "PASS: get/set_last_pr_seen works"

# Test: state backfill — old state file missing last_pr_seen defaults to 0
BACKFILL_REPO="backfill-test/old-state"
BACKFILL_FILE="$TEMP_DIR/backfill-test-old-state.json"
mkdir -p "$(dirname "$BACKFILL_FILE")"
cat > "$BACKFILL_FILE" <<'OLD'
{
  "last_poll": null,
  "last_issue_seen": 5,
  "pending_approvals": [],
  "actions_this_hour": 0,
  "actions_hour_start": null
}
OLD
BACKFILL_PR=$(get_last_pr_seen "$BACKFILL_REPO")
if [[ "$BACKFILL_PR" != "0" ]]; then
  echo "FAIL: expected backfill last_pr_seen=0, got $BACKFILL_PR"
  exit 1
fi
echo "PASS: state backfill defaults last_pr_seen to 0"

# Test: pending approval type — 6th param stores type
TYPE_REPO="type-test/approval-type"
init_state "$TYPE_REPO"
add_pending_approval "$TYPE_REPO" 100 "comment" "wait" "Issue comment" "issue"
ISSUE_TYPE=$(jq -r '.pending_approvals[0].type' "$(_state_file "$TYPE_REPO")")
if [[ "$ISSUE_TYPE" != "issue" ]]; then
  echo "FAIL: expected type=issue, got $ISSUE_TYPE"
  exit 1
fi
add_pending_approval "$TYPE_REPO" 101 "open_pr" "wait" "PR review" "pr"
PR_TYPE=$(jq -r '.pending_approvals[1].type' "$(_state_file "$TYPE_REPO")")
if [[ "$PR_TYPE" != "pr" ]]; then
  echo "FAIL: expected type=pr, got $PR_TYPE"
  exit 1
fi
SUMMARY_VAL=$(jq -r '.pending_approvals[1].summary' "$(_state_file "$TYPE_REPO")")
if [[ "$SUMMARY_VAL" != "PR review" ]]; then
  echo "FAIL: expected summary='PR review', got $SUMMARY_VAL"
  exit 1
fi
echo "PASS: pending approval type stored correctly, summary preserved"

# Test: init_state backfills project_path and owner_repo on existing state files
BACKFILL2_REPO="backfill-test/old-state"
export ARGOS_PROJECT_PATH="/tmp/test-project"
init_state "$BACKFILL2_REPO"
BACKFILL_PP=$(jq -r '.project_path' "$(_state_file "$BACKFILL2_REPO")")
BACKFILL_OR=$(jq -r '.owner_repo' "$(_state_file "$BACKFILL2_REPO")")
BACKFILL_PR2=$(jq -r '.last_pr_seen' "$(_state_file "$BACKFILL2_REPO")")
BACKFILL_LIS=$(jq -r '.last_issue_seen' "$(_state_file "$BACKFILL2_REPO")")
if [[ "$BACKFILL_PP" != "/tmp/test-project" ]]; then
  echo "FAIL: expected backfill project_path=/tmp/test-project, got $BACKFILL_PP"
  exit 1
fi
if [[ "$BACKFILL_OR" != "backfill-test/old-state" ]]; then
  echo "FAIL: expected backfill owner_repo=backfill-test/old-state, got $BACKFILL_OR"
  exit 1
fi
if [[ "$BACKFILL_PR2" != "0" ]]; then
  echo "FAIL: expected backfill last_pr_seen=0, got $BACKFILL_PR2"
  exit 1
fi
if [[ "$BACKFILL_LIS" != "5" ]]; then
  echo "FAIL: expected existing last_issue_seen=5 preserved, got $BACKFILL_LIS"
  exit 1
fi
echo "PASS: init_state backfills project_path, owner_repo, last_pr_seen on old state files"
unset ARGOS_PROJECT_PATH

echo ""
echo "All state tests passed."
