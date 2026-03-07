#!/bin/bash
# tests/test-policy.sh — verify policy loading and checking
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/policy.sh"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create a test policy
cat > "$TEMP_DIR/test-policy.yaml" <<'YAML'
repo: owner/repo
poll_interval: 5m
floors:
  paths:
    "src/auth/**": 3
    "src/payments/**": 4
    "config/production.*": 5
  types:
    enhancement: 4
    question: 5
  authors:
    trusted: ["maintainer1"]
    unknown: 4
  minimum: 2
deny:
  actions:
    - close_issue
    - merge_pr
  paths:
    - ".env*"
    - "*.secret"
guardrails:
  max_actions_per_hour: 10
  max_open_prs: 3
  max_files_changed: 10
notifications:
  channels:
    - name: github_comment
      type: external
    - name: system
      type: internal
    - name: session
      type: internal
YAML

# ── load_policy ──────────────────────────────────────────────────────
POLICY_JSON=$(load_policy "$TEMP_DIR/test-policy.yaml")
REPO=$(echo "$POLICY_JSON" | jq -r '.repo')
if [[ "$REPO" != "owner/repo" ]]; then
  echo "FAIL: expected repo=owner/repo, got $REPO"
  exit 1
fi
echo "PASS: load_policy reads YAML and repo=owner/repo"

# ── get_floor_for_path ───────────────────────────────────────────────
FLOOR=$(echo "$POLICY_JSON" | get_floor_for_path "src/auth/login.js")
if [[ "$FLOOR" != "3" ]]; then
  echo "FAIL: expected floor=3 for src/auth/login.js, got $FLOOR"
  exit 1
fi
echo "PASS: get_floor_for_path src/auth/login.js returns 3"

FLOOR=$(echo "$POLICY_JSON" | get_floor_for_path "src/payments/stripe.js")
if [[ "$FLOOR" != "4" ]]; then
  echo "FAIL: expected floor=4 for src/payments/stripe.js, got $FLOOR"
  exit 1
fi
echo "PASS: get_floor_for_path src/payments/stripe.js returns 4"

FLOOR=$(echo "$POLICY_JSON" | get_floor_for_path "src/main.js")
if [[ "$FLOOR" != "0" ]]; then
  echo "FAIL: expected floor=0 for src/main.js, got $FLOOR"
  exit 1
fi
echo "PASS: get_floor_for_path src/main.js returns 0 (no match)"

# ── get_floor_for_type ───────────────────────────────────────────────
FLOOR=$(echo "$POLICY_JSON" | get_floor_for_type "enhancement")
if [[ "$FLOOR" != "4" ]]; then
  echo "FAIL: expected floor=4 for enhancement, got $FLOOR"
  exit 1
fi
echo "PASS: get_floor_for_type enhancement returns 4"

FLOOR=$(echo "$POLICY_JSON" | get_floor_for_type "question")
if [[ "$FLOOR" != "5" ]]; then
  echo "FAIL: expected floor=5 for question, got $FLOOR"
  exit 1
fi
echo "PASS: get_floor_for_type question returns 5"

FLOOR=$(echo "$POLICY_JSON" | get_floor_for_type "bug")
if [[ "$FLOOR" != "0" ]]; then
  echo "FAIL: expected floor=0 for bug, got $FLOOR"
  exit 1
fi
echo "PASS: get_floor_for_type bug returns 0 (no match)"

# ── get_floor_for_author ─────────────────────────────────────────────
FLOOR=$(echo "$POLICY_JSON" | get_floor_for_author "maintainer1")
if [[ "$FLOOR" != "0" ]]; then
  echo "FAIL: expected floor=0 for trusted author maintainer1, got $FLOOR"
  exit 1
fi
echo "PASS: get_floor_for_author maintainer1 (trusted) returns 0"

FLOOR=$(echo "$POLICY_JSON" | get_floor_for_author "random-user")
if [[ "$FLOOR" != "4" ]]; then
  echo "FAIL: expected floor=4 for unknown author random-user, got $FLOOR"
  exit 1
fi
echo "PASS: get_floor_for_author random-user (unknown) returns 4"

# ── get_minimum_floor ────────────────────────────────────────────────
FLOOR=$(echo "$POLICY_JSON" | get_minimum_floor)
if [[ "$FLOOR" != "2" ]]; then
  echo "FAIL: expected minimum floor=2, got $FLOOR"
  exit 1
fi
echo "PASS: get_minimum_floor returns 2"

# ── apply_floors ─────────────────────────────────────────────────────
# Case 1: AI assigns level 1, type "bug", author "random-user", paths "src/main.js"
# Path floor=0, type floor=0, author floor=4, minimum=2 → max(1,0,0,4,2)=4
RESULT=$(echo "$POLICY_JSON" | apply_floors 1 "bug" "random-user" "src/main.js")
if [[ "$RESULT" != "4" ]]; then
  echo "FAIL: apply_floors case 1 expected 4, got $RESULT"
  exit 1
fi
echo "PASS: apply_floors escalates to 4 (unknown author floor)"

# Case 2: AI assigns level 1, type "enhancement", author "maintainer1", paths "src/auth/login.js"
# Path floor=3, type floor=4, author floor=0, minimum=2 → max(1,3,4,0,2)=4
RESULT=$(echo "$POLICY_JSON" | apply_floors 1 "enhancement" "maintainer1" "src/auth/login.js")
if [[ "$RESULT" != "4" ]]; then
  echo "FAIL: apply_floors case 2 expected 4, got $RESULT"
  exit 1
fi
echo "PASS: apply_floors escalates to 4 (max of type=4, path=3)"

# Case 3: AI assigns level 3, type "bug", author "maintainer1", paths "src/main.js"
# Path floor=0, type floor=0, author floor=0, minimum=2 → max(3,0,0,0,2)=3
RESULT=$(echo "$POLICY_JSON" | apply_floors 3 "bug" "maintainer1" "src/main.js")
if [[ "$RESULT" != "3" ]]; then
  echo "FAIL: apply_floors case 3 expected 3, got $RESULT"
  exit 1
fi
echo "PASS: apply_floors stays at 3 (AI level > minimum floor 2)"

# ── is_action_denied ─────────────────────────────────────────────────
if ! echo "$POLICY_JSON" | is_action_denied "close_issue"; then
  echo "FAIL: close_issue should be denied"
  exit 1
fi
echo "PASS: is_action_denied close_issue returns true"

if ! echo "$POLICY_JSON" | is_action_denied "merge_pr"; then
  echo "FAIL: merge_pr should be denied"
  exit 1
fi
echo "PASS: is_action_denied merge_pr returns true"

if echo "$POLICY_JSON" | is_action_denied "label"; then
  echo "FAIL: label should not be denied"
  exit 1
fi
echo "PASS: is_action_denied label returns false"

# ── is_path_denied ───────────────────────────────────────────────────
if ! echo "$POLICY_JSON" | is_path_denied ".env.production"; then
  echo "FAIL: .env.production should be denied"
  exit 1
fi
echo "PASS: is_path_denied .env.production returns true"

if ! echo "$POLICY_JSON" | is_path_denied "test.secret"; then
  echo "FAIL: test.secret should be denied"
  exit 1
fi
echo "PASS: is_path_denied test.secret returns true"

if echo "$POLICY_JSON" | is_path_denied "src/main.js"; then
  echo "FAIL: src/main.js should not be denied"
  exit 1
fi
echo "PASS: is_path_denied src/main.js returns false"

# ── get_channel_type ─────────────────────────────────────────────────
TYPE=$(echo "$POLICY_JSON" | get_channel_type "github_comment")
if [[ "$TYPE" != "external" ]]; then
  echo "FAIL: expected type=external for github_comment, got $TYPE"
  exit 1
fi
echo "PASS: get_channel_type github_comment returns external"

TYPE=$(echo "$POLICY_JSON" | get_channel_type "system")
if [[ "$TYPE" != "internal" ]]; then
  echo "FAIL: expected type=internal for system, got $TYPE"
  exit 1
fi
echo "PASS: get_channel_type system returns internal"

TYPE=$(echo "$POLICY_JSON" | get_channel_type "unknown_channel")
if [[ "$TYPE" != "internal" ]]; then
  echo "FAIL: expected type=internal (default) for unknown_channel, got $TYPE"
  exit 1
fi
echo "PASS: get_channel_type unknown_channel returns internal (default)"

# ── get_channels_by_type ─────────────────────────────────────────────
CHANNELS=$(echo "$POLICY_JSON" | get_channels_by_type "internal")
if ! echo "$CHANNELS" | grep -q "system"; then
  echo "FAIL: internal channels should include system"
  exit 1
fi
if ! echo "$CHANNELS" | grep -q "session"; then
  echo "FAIL: internal channels should include session"
  exit 1
fi
echo "PASS: get_channels_by_type internal returns system and session"

CHANNELS=$(echo "$POLICY_JSON" | get_channels_by_type "external")
if ! echo "$CHANNELS" | grep -q "github_comment"; then
  echo "FAIL: external channels should include github_comment"
  exit 1
fi
echo "PASS: get_channels_by_type external returns github_comment"

# ── get_poll_interval (unchanged function) ───────────────────────────
INTERVAL=$(echo "$POLICY_JSON" | get_poll_interval)
if [[ "$INTERVAL" != "5m" ]]; then
  echo "FAIL: expected poll_interval=5m, got $INTERVAL"
  exit 1
fi
echo "PASS: get_poll_interval returns 5m"

# ── get_guardrail (unchanged function) ───────────────────────────────
GUARDRAIL=$(echo "$POLICY_JSON" | get_guardrail "max_actions_per_hour")
if [[ "$GUARDRAIL" != "10" ]]; then
  echo "FAIL: expected max_actions_per_hour=10, got $GUARDRAIL"
  exit 1
fi
echo "PASS: get_guardrail max_actions_per_hour returns 10"

# ── check_policy_format ─────────────────────────────────────────────
# Test with new format (has floors key)
if echo "$POLICY_JSON" | check_policy_format; then
  echo "PASS: check_policy_format returns 0 for new format (floors)"
else
  echo "FAIL: check_policy_format should return 0 for new format"
  exit 1
fi

# Test with old format (has actions key)
OLD_POLICY='{"actions":{"auto":["label","comment"],"approve":["commit"],"deny":["close"]}}'
RETVAL=0
echo "$OLD_POLICY" | check_policy_format || RETVAL=$?
if [[ "$RETVAL" == "1" ]]; then
  echo "PASS: check_policy_format returns 1 for old format (actions)"
else
  echo "FAIL: check_policy_format expected return 1 for old format, got $RETVAL"
  exit 1
fi

# Test with empty/invalid JSON
EMPTY_POLICY='{}'
RETVAL=0
echo "$EMPTY_POLICY" | check_policy_format || RETVAL=$?
if [[ "$RETVAL" == "2" ]]; then
  echo "PASS: check_policy_format returns 2 for empty policy"
else
  echo "FAIL: check_policy_format expected return 2 for empty, got $RETVAL"
  exit 1
fi

echo ""
echo "All policy tests passed."
