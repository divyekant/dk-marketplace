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
actions:
  auto:
    - label
    - comment_triage
  approve:
    - open_pr
  deny:
    - merge_pr
approval_modes:
  open_pr:
    mode: wait
guardrails:
  max_actions_per_hour: 10
  max_open_prs: 3
  max_files_changed: 10
  protected_paths:
    - ".env*"
YAML

# Test: load_policy reads YAML
POLICY_JSON=$(load_policy "$TEMP_DIR/test-policy.yaml")
REPO=$(echo "$POLICY_JSON" | jq -r '.repo')
if [[ "$REPO" != "owner/repo" ]]; then
  echo "FAIL: expected repo=owner/repo, got $REPO"
  exit 1
fi
echo "PASS: load_policy reads YAML"

# Test: get_action_tier returns correct tier
TIER=$(echo "$POLICY_JSON" | get_action_tier "label")
if [[ "$TIER" != "auto" ]]; then
  echo "FAIL: expected tier=auto for label, got $TIER"
  exit 1
fi
echo "PASS: get_action_tier returns auto for label"

TIER=$(echo "$POLICY_JSON" | get_action_tier "open_pr")
if [[ "$TIER" != "approve" ]]; then
  echo "FAIL: expected tier=approve for open_pr, got $TIER"
  exit 1
fi
echo "PASS: get_action_tier returns approve for open_pr"

TIER=$(echo "$POLICY_JSON" | get_action_tier "merge_pr")
if [[ "$TIER" != "deny" ]]; then
  echo "FAIL: expected tier=deny for merge_pr, got $TIER"
  exit 1
fi
echo "PASS: get_action_tier returns deny for merge_pr"

# Test: unlisted action is implicitly denied
TIER=$(echo "$POLICY_JSON" | get_action_tier "unknown_action")
if [[ "$TIER" != "deny" ]]; then
  echo "FAIL: expected tier=deny for unlisted action, got $TIER"
  exit 1
fi
echo "PASS: unlisted actions are implicitly denied"

# Test: get_approval_mode
MODE=$(echo "$POLICY_JSON" | get_approval_mode "open_pr")
if [[ "$MODE" != "wait" ]]; then
  echo "FAIL: expected mode=wait for open_pr, got $MODE"
  exit 1
fi
echo "PASS: get_approval_mode returns correct mode"

# Test: is_path_protected
if ! echo "$POLICY_JSON" | is_path_protected ".env.production"; then
  echo "FAIL: .env.production should be protected"
  exit 1
fi
echo "PASS: is_path_protected catches .env files"

if echo "$POLICY_JSON" | is_path_protected "src/main.go"; then
  echo "FAIL: src/main.go should not be protected"
  exit 1
fi
echo "PASS: is_path_protected allows normal files"

echo ""
echo "All policy tests passed."
