#!/bin/bash
# tests/test-e2e.sh — end-to-end dry run test
# Simulates a full Argos cycle with mock data
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

export ARGOS_STATE_DIR="$TEMP_DIR/state"
export ARGOS_ADAPTER_DIR="$TEMP_DIR/adapters"

source "$SCRIPT_DIR/../lib/state.sh"
source "$SCRIPT_DIR/../lib/poll.sh"
source "$SCRIPT_DIR/../lib/policy.sh"
source "$SCRIPT_DIR/../lib/notify.sh"

REPO="test/repo"

# 1. Init state
init_state "$REPO"
echo "PASS: State initialized"

# 2. Load policy
POLICY=$(load_policy "$SCRIPT_DIR/../config/default-policy.yaml")
echo "PASS: Policy loaded"

# 3. Simulate new issues
MOCK_ISSUES='[
  {"number": 1, "title": "Login broken", "labels": [{"name": "bug"}], "createdAt": "2026-03-06T10:00:00Z", "url": "https://github.com/test/repo/issues/1", "author": {"login": "user1"}, "body": "Cannot log in"},
  {"number": 2, "title": "Add dark mode", "labels": [{"name": "enhancement"}], "createdAt": "2026-03-06T11:00:00Z", "url": "https://github.com/test/repo/issues/2", "author": {"login": "user2"}, "body": "Please add dark mode"}
]'

PARSED=$(echo "$MOCK_ISSUES" | parse_issues)
FILTERED=$(echo "$PARSED" | filter_new_issues 0)
COUNT=$(echo "$FILTERED" | jq 'length')
if [[ "$COUNT" != "2" ]]; then
  echo "FAIL: expected 2 new issues, got $COUNT"
  exit 1
fi
echo "PASS: Found $COUNT new issues"

# 4. Check action tier for 'label'
TIER=$(echo "$POLICY" | get_action_tier "label")
if [[ "$TIER" != "auto" ]]; then
  echo "FAIL: label should be auto tier"
  exit 1
fi
echo "PASS: label action is auto tier"

# 5. Check action tier for 'open_pr'
TIER=$(echo "$POLICY" | get_action_tier "open_pr")
if [[ "$TIER" != "approve" ]]; then
  echo "FAIL: open_pr should be approve tier"
  exit 1
fi
echo "PASS: open_pr action is approve tier"

# 6. Check action tier for 'merge_pr' (denied)
TIER=$(echo "$POLICY" | get_action_tier "merge_pr")
if [[ "$TIER" != "deny" ]]; then
  echo "FAIL: merge_pr should be deny tier"
  exit 1
fi
echo "PASS: merge_pr action is deny tier"

# 7. Check guardrail - rate limit
if ! check_rate_limit "$REPO" 10; then
  echo "FAIL: should be under rate limit"
  exit 1
fi
echo "PASS: Rate limit check passes"

# 8. Check approval mode for open_pr
MODE=$(echo "$POLICY" | get_approval_mode "open_pr")
if [[ "$MODE" != "wait" ]]; then
  echo "FAIL: open_pr approval mode should be wait, got $MODE"
  exit 1
fi
echo "PASS: open_pr approval mode is wait"

# 9. Add a pending approval and verify
add_pending_approval "$REPO" 1 "open_pr" "wait" "Fix login broken"
COUNT=$(get_pending_count "$REPO")
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 pending approval, got $COUNT"
  exit 1
fi
echo "PASS: Pending approval added"

# 10. Build and dispatch notification (mock adapter)
mkdir -p "$ARGOS_ADAPTER_DIR"
cat > "$ARGOS_ADAPTER_DIR/mock.sh" << 'MOCK'
#!/bin/bash
cat > "${ARGOS_ADAPTER_DIR}/mock-received.json"
MOCK
chmod +x "$ARGOS_ADAPTER_DIR/mock.sh"

notify "auto_action_taken" "$REPO" 1 "Login broken" "label" "Applied label: bug" "mock"
if [[ ! -f "$ARGOS_ADAPTER_DIR/mock-received.json" ]]; then
  echo "FAIL: notification not dispatched"
  exit 1
fi
EVENT=$(jq -r '.event' "$ARGOS_ADAPTER_DIR/mock-received.json")
if [[ "$EVENT" != "auto_action_taken" ]]; then
  echo "FAIL: notification event mismatch"
  exit 1
fi
echo "PASS: Notification dispatched correctly"

# 11. Update state
set_last_issue_seen "$REPO" 2
LAST=$(get_last_issue_seen "$REPO")
if [[ "$LAST" != "2" ]]; then
  echo "FAIL: last_issue_seen should be 2"
  exit 1
fi
echo "PASS: State updated with last seen issue"

# 12. Increment action count and verify
increment_actions_count "$REPO"
ACTIONS=$(get_actions_this_hour "$REPO")
if [[ "$ACTIONS" != "1" ]]; then
  echo "FAIL: expected 1 action this hour, got $ACTIONS"
  exit 1
fi
echo "PASS: Action counter incremented"

# 13. Check protected path guardrail
if ! echo "$POLICY" | is_path_protected ".env.local"; then
  echo "FAIL: .env.local should be protected"
  exit 1
fi
echo "PASS: Protected path guardrail works"

# 14. Filter by labels
FILTERED=$(echo "$PARSED" | filter_by_labels '["bug"]')
COUNT=$(echo "$FILTERED" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 bug issue, got $COUNT"
  exit 1
fi
echo "PASS: Label filtering works"

# 15. Check dry_run default is false
DRY=$(echo "$POLICY" | is_dry_run)
if [[ "$DRY" != "false" ]]; then
  echo "FAIL: dry_run should be false by default"
  exit 1
fi
echo "PASS: Dry run is false by default"

echo ""
echo "All end-to-end tests passed. (15/15)"
