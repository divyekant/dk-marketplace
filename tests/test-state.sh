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

echo ""
echo "All state tests passed."
