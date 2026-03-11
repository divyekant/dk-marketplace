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

# 4. Check minimum floor
FLOOR=$(echo "$POLICY" | get_minimum_floor)
if [[ "$FLOOR" != "2" ]]; then
  echo "FAIL: minimum floor should be 2, got $FLOOR"
  exit 1
fi
echo "PASS: Minimum floor is 2"

# 5. Check denied action: merge_pr
if ! echo "$POLICY" | is_action_denied "merge_pr"; then
  echo "FAIL: merge_pr should be denied"
  exit 1
fi
echo "PASS: merge_pr is denied"

# 6. Check allowed action: label
if echo "$POLICY" | is_action_denied "label"; then
  echo "FAIL: label should not be denied"
  exit 1
fi
echo "PASS: label is not denied"

# 7. Check guardrail - rate limit
if ! check_rate_limit "$REPO" 10; then
  echo "FAIL: should be under rate limit"
  exit 1
fi
echo "PASS: Rate limit check passes"

# 8. Check denied path: .env.local
if ! echo "$POLICY" | is_path_denied ".env.local"; then
  echo "FAIL: .env.local should be denied"
  exit 1
fi
echo "PASS: .env.local path is denied"

# 9. Check floor for issue type: enhancement
TYPE_FLOOR=$(echo "$POLICY" | get_floor_for_type "enhancement")
if [[ "$TYPE_FLOOR" != "4" ]]; then
  echo "FAIL: enhancement floor should be 4, got $TYPE_FLOOR"
  exit 1
fi
echo "PASS: Enhancement floor is 4"

# 10. Check channel type: github_comment is external
CH_TYPE=$(echo "$POLICY" | get_channel_type "github_comment")
if [[ "$CH_TYPE" != "external" ]]; then
  echo "FAIL: github_comment channel type should be external, got $CH_TYPE"
  exit 1
fi
echo "PASS: github_comment channel type is external"

# 11. Check channel type: system is internal
CH_TYPE=$(echo "$POLICY" | get_channel_type "system")
if [[ "$CH_TYPE" != "internal" ]]; then
  echo "FAIL: system channel type should be internal, got $CH_TYPE"
  exit 1
fi
echo "PASS: system channel type is internal"

# 12. Add a pending approval and verify
add_pending_approval "$REPO" 1 "open_pr" "wait" "Fix login broken"
COUNT=$(get_pending_count "$REPO")
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 pending approval, got $COUNT"
  exit 1
fi
echo "PASS: Pending approval added"

# 13. Build and dispatch notification (mock adapter)
mkdir -p "$ARGOS_ADAPTER_DIR"
cat > "$ARGOS_ADAPTER_DIR/mock.sh" << 'MOCK'
#!/bin/bash
cat > "${ARGOS_ADAPTER_DIR}/mock-received.json"
MOCK
chmod +x "$ARGOS_ADAPTER_DIR/mock.sh"

notify "auto_action_taken" "$REPO" 1 "Login broken" "label" "Triaged as bug" "Bug in auth.js:147, high confidence" "mock:internal"
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

# 14. Update state
set_last_issue_seen "$REPO" 2
LAST=$(get_last_issue_seen "$REPO")
if [[ "$LAST" != "2" ]]; then
  echo "FAIL: last_issue_seen should be 2"
  exit 1
fi
echo "PASS: State updated with last seen issue"

# 15. Increment action count and verify
increment_actions_count "$REPO"
ACTIONS=$(get_actions_this_hour "$REPO")
if [[ "$ACTIONS" != "1" ]]; then
  echo "FAIL: expected 1 action this hour, got $ACTIONS"
  exit 1
fi
echo "PASS: Action counter incremented"

# 16. Filter by labels
FILTERED=$(echo "$PARSED" | filter_by_labels '["bug"]')
COUNT=$(echo "$FILTERED" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 bug issue, got $COUNT"
  exit 1
fi
echo "PASS: Label filtering works"

# 17. Check dry_run default is false
DRY=$(echo "$POLICY" | is_dry_run)
if [[ "$DRY" != "false" ]]; then
  echo "FAIL: dry_run should be false by default"
  exit 1
fi
echo "PASS: Dry run is false by default"

# 18. Policy cascade — project root wins
E2E_PROJECT="$TEMP_DIR/e2e-project"
mkdir -p "$E2E_PROJECT/.argos"
cat > "$E2E_PROJECT/.argos/policy.yaml" << 'INREPO'
repo: "test/e2e"
poll_interval: 5m
floors:
  minimum: 3
deny:
  actions: []
  paths: []
guardrails:
  dry_run: false
notifications:
  channels: []
INREPO

GLOBAL_POLICY="$TEMP_DIR/global-policy.yaml"
cat > "$GLOBAL_POLICY" << 'GLOBAL'
repo: "test/e2e"
poll_interval: 5m
floors:
  minimum: 1
deny:
  actions: []
  paths: []
guardrails:
  dry_run: false
notifications:
  channels: []
GLOBAL

CASCADE_POLICY=$(load_policy "$GLOBAL_POLICY" "$E2E_PROJECT")
CASCADE_MIN=$(echo "$CASCADE_POLICY" | get_minimum_floor)
if [[ "$CASCADE_MIN" != "3" ]]; then
  echo "FAIL: E2E 18 — cascade should prefer project root (minimum=3), got $CASCADE_MIN"
  exit 1
fi
echo "PASS: E2E 18 — Policy cascade: project root wins (minimum=3)"

# 19. State init with project path + PR watermark
E2E_REPO2="test/e2e-state"
export ARGOS_PROJECT_PATH="/tmp/e2e-project"
init_state "$E2E_REPO2"
STATE_FILE="$ARGOS_STATE_DIR/test-e2e-state.json"
STATE_PROJECT=$(jq -r '.project_path' "$STATE_FILE")
STATE_PR=$(jq -r '.last_pr_seen' "$STATE_FILE")
if [[ "$STATE_PROJECT" != "/tmp/e2e-project" ]]; then
  echo "FAIL: E2E 19 — project_path should be /tmp/e2e-project, got $STATE_PROJECT"
  exit 1
fi
if [[ "$STATE_PR" != "0" ]]; then
  echo "FAIL: E2E 19 — last_pr_seen should be 0, got $STATE_PR"
  exit 1
fi
unset ARGOS_PROJECT_PATH
echo "PASS: E2E 19 — State init with project path + PR watermark"

# 20. is_watched + pending approval type
E2E_REPO3="test/e2e-watched"
init_state "$E2E_REPO3"
if ! is_watched "$E2E_REPO3"; then
  echo "FAIL: E2E 20 — is_watched should return 0 for initialized repo"
  exit 1
fi
if is_watched "test/nonexistent-repo"; then
  echo "FAIL: E2E 20 — is_watched should return 1 for unknown repo"
  exit 1
fi
add_pending_approval "$E2E_REPO3" 10 "label" "wait" "Label issue" "issue"
add_pending_approval "$E2E_REPO3" 20 "open_pr" "wait" "Open PR" "pr"
add_pending_approval "$E2E_REPO3" 30 "label" "wait" "Label another" "issue"
ISSUE_COUNT=$(jq '[.pending_approvals[] | select(.type == "issue")] | length' "$ARGOS_STATE_DIR/test-e2e-watched.json")
PR_COUNT=$(jq '[.pending_approvals[] | select(.type == "pr")] | length' "$ARGOS_STATE_DIR/test-e2e-watched.json")
if [[ "$ISSUE_COUNT" != "2" ]]; then
  echo "FAIL: E2E 20 — expected 2 issue-type approvals, got $ISSUE_COUNT"
  exit 1
fi
if [[ "$PR_COUNT" != "1" ]]; then
  echo "FAIL: E2E 20 — expected 1 pr-type approval, got $PR_COUNT"
  exit 1
fi
echo "PASS: E2E 20 — is_watched + pending approval type filtering"

echo ""
echo "All end-to-end tests passed. (20/20)"
