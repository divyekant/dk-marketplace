#!/bin/bash
# tests/test-notify.sh — verify audience-aware notification dispatch
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/notify.sh"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# ── Test a) build_payload creates valid JSON with both content fields ────────

PAYLOAD=$(build_payload "auto_action" "owner/repo" 42 "Bug title" "label" "Public: triaged as bug" "Internal: bug in auth.js:147, high confidence")

EVENT=$(echo "$PAYLOAD" | jq -r '.event')
if [[ "$EVENT" != "auto_action" ]]; then
  echo "FAIL: expected event=auto_action, got $EVENT"
  exit 1
fi

REPO=$(echo "$PAYLOAD" | jq -r '.repo')
if [[ "$REPO" != "owner/repo" ]]; then
  echo "FAIL: expected repo=owner/repo, got $REPO"
  exit 1
fi

ISSUE=$(echo "$PAYLOAD" | jq -r '.issue')
if [[ "$ISSUE" != "42" ]]; then
  echo "FAIL: expected issue=42, got $ISSUE"
  exit 1
fi

TITLE=$(echo "$PAYLOAD" | jq -r '.title')
if [[ "$TITLE" != "Bug title" ]]; then
  echo "FAIL: expected title='Bug title', got $TITLE"
  exit 1
fi

ACTION=$(echo "$PAYLOAD" | jq -r '.action')
if [[ "$ACTION" != "label" ]]; then
  echo "FAIL: expected action=label, got $ACTION"
  exit 1
fi

CONTENT_EXT=$(echo "$PAYLOAD" | jq -r '.content_external')
if [[ "$CONTENT_EXT" != "Public: triaged as bug" ]]; then
  echo "FAIL: expected content_external='Public: triaged as bug', got $CONTENT_EXT"
  exit 1
fi

CONTENT_INT=$(echo "$PAYLOAD" | jq -r '.content_internal')
if [[ "$CONTENT_INT" != "Internal: bug in auth.js:147, high confidence" ]]; then
  echo "FAIL: expected content_internal='Internal: bug in auth.js:147, high confidence', got $CONTENT_INT"
  exit 1
fi

echo "PASS: build_payload creates valid JSON with both content fields"

# ── Setup mock adapter for dispatch tests ────────────────────────────────────

export ARGOS_ADAPTER_DIR="$TEMP_DIR/adapters"
mkdir -p "$ARGOS_ADAPTER_DIR"

cat > "$ARGOS_ADAPTER_DIR/mock.sh" << 'MOCK'
#!/bin/bash
cat > "$ARGOS_ADAPTER_DIR/mock-received.json"
MOCK
chmod +x "$ARGOS_ADAPTER_DIR/mock.sh"

# ── Test b) dispatch_to_adapter with external type uses content_external ─────

PAYLOAD=$(build_payload "test_event" "owner/repo" 1 "Test" "test" "external details here" "internal details here")
rm -f "$ARGOS_ADAPTER_DIR/mock-received.json"
echo "$PAYLOAD" | dispatch_to_adapter "mock" "external"

if [[ ! -f "$ARGOS_ADAPTER_DIR/mock-received.json" ]]; then
  echo "FAIL: mock adapter was not called for external dispatch"
  exit 1
fi

RECEIVED_DETAILS=$(jq -r '.details' "$ARGOS_ADAPTER_DIR/mock-received.json")
if [[ "$RECEIVED_DETAILS" != "external details here" ]]; then
  echo "FAIL: expected details='external details here' for external channel, got '$RECEIVED_DETAILS'"
  exit 1
fi

echo "PASS: dispatch_to_adapter with external type uses content_external"

# ── Test c) dispatch_to_adapter with internal type uses content_internal ─────

rm -f "$ARGOS_ADAPTER_DIR/mock-received.json"
echo "$PAYLOAD" | dispatch_to_adapter "mock" "internal"

if [[ ! -f "$ARGOS_ADAPTER_DIR/mock-received.json" ]]; then
  echo "FAIL: mock adapter was not called for internal dispatch"
  exit 1
fi

RECEIVED_DETAILS=$(jq -r '.details' "$ARGOS_ADAPTER_DIR/mock-received.json")
if [[ "$RECEIVED_DETAILS" != "internal details here" ]]; then
  echo "FAIL: expected details='internal details here' for internal channel, got '$RECEIVED_DETAILS'"
  exit 1
fi

echo "PASS: dispatch_to_adapter with internal type uses content_internal"

# ── Test d) dispatch_to_adapter defaults to internal when no type given ──────

rm -f "$ARGOS_ADAPTER_DIR/mock-received.json"
echo "$PAYLOAD" | dispatch_to_adapter "mock"

if [[ ! -f "$ARGOS_ADAPTER_DIR/mock-received.json" ]]; then
  echo "FAIL: mock adapter was not called for default dispatch"
  exit 1
fi

RECEIVED_DETAILS=$(jq -r '.details' "$ARGOS_ADAPTER_DIR/mock-received.json")
if [[ "$RECEIVED_DETAILS" != "internal details here" ]]; then
  echo "FAIL: expected details='internal details here' for default (no type), got '$RECEIVED_DETAILS'"
  exit 1
fi

echo "PASS: dispatch_to_adapter defaults to internal when no type given"

# ── Test e) dispatch rejects path traversal in adapter name ──────────────────

OUTPUT=$(echo '{}' | dispatch_to_adapter "../../etc/evil" 2>&1 || true)
if echo "$OUTPUT" | grep -q "invalid adapter name"; then
  echo "PASS: dispatch_to_adapter rejects path traversal in adapter name"
else
  echo "FAIL: dispatch_to_adapter did not reject path traversal"
  exit 1
fi

# ── Test f) dispatch rejects dots in adapter name ────────────────────────────

OUTPUT=$(echo '{}' | dispatch_to_adapter "evil.payload" 2>&1 || true)
if echo "$OUTPUT" | grep -q "invalid adapter name"; then
  echo "PASS: dispatch_to_adapter rejects dots in adapter name"
else
  echo "FAIL: dispatch_to_adapter did not reject dots"
  exit 1
fi

# ── Test g) notify routes to channels with correct types ─────────────────────

rm -f "$ARGOS_ADAPTER_DIR/mock-received.json"
notify "test_event" "owner/repo" 1 "Test" "test" "external content" "internal content" "mock:external"

if [[ ! -f "$ARGOS_ADAPTER_DIR/mock-received.json" ]]; then
  echo "FAIL: mock adapter was not called by notify"
  exit 1
fi

RECEIVED_DETAILS=$(jq -r '.details' "$ARGOS_ADAPTER_DIR/mock-received.json")
if [[ "$RECEIVED_DETAILS" != "external content" ]]; then
  echo "FAIL: expected details='external content' from notify with mock:external, got '$RECEIVED_DETAILS'"
  exit 1
fi

echo "PASS: notify routes to channels with correct types"

# ── Test h) build_pr_payload creates valid PR notification JSON ───────────────

PR_PAYLOAD=$(build_pr_payload "owner/repo" 99 "Fix auth flow" "feature" 3 5 "https://github.com/owner/repo/pull/99.diff" "Found 5 issues: 2 security, 3 style")

ITEM_TYPE=$(echo "$PR_PAYLOAD" | jq -r '.item_type')
if [[ "$ITEM_TYPE" != "pr" ]]; then
  echo "FAIL: expected item_type=pr, got $ITEM_TYPE"
  exit 1
fi

PR_REPO=$(echo "$PR_PAYLOAD" | jq -r '.repo')
if [[ "$PR_REPO" != "owner/repo" ]]; then
  echo "FAIL: expected repo=owner/repo, got $PR_REPO"
  exit 1
fi

PR_NUMBER=$(echo "$PR_PAYLOAD" | jq -r '.number')
if [[ "$PR_NUMBER" != "99" ]]; then
  echo "FAIL: expected number=99, got $PR_NUMBER"
  exit 1
fi

PR_TITLE=$(echo "$PR_PAYLOAD" | jq -r '.title')
if [[ "$PR_TITLE" != "Fix auth flow" ]]; then
  echo "FAIL: expected title='Fix auth flow', got $PR_TITLE"
  exit 1
fi

PR_TYPE=$(echo "$PR_PAYLOAD" | jq -r '.pr_type')
if [[ "$PR_TYPE" != "feature" ]]; then
  echo "FAIL: expected pr_type=feature, got $PR_TYPE"
  exit 1
fi

PR_LEVEL=$(echo "$PR_PAYLOAD" | jq -r '.level')
if [[ "$PR_LEVEL" != "3" ]]; then
  echo "FAIL: expected level=3, got $PR_LEVEL"
  exit 1
fi

PR_FINDINGS=$(echo "$PR_PAYLOAD" | jq -r '.findings_count')
if [[ "$PR_FINDINGS" != "5" ]]; then
  echo "FAIL: expected findings_count=5, got $PR_FINDINGS"
  exit 1
fi

PR_DIFF=$(echo "$PR_PAYLOAD" | jq -r '.diff_url')
if [[ "$PR_DIFF" != "https://github.com/owner/repo/pull/99.diff" ]]; then
  echo "FAIL: expected diff_url, got $PR_DIFF"
  exit 1
fi

PR_SUMMARY=$(echo "$PR_PAYLOAD" | jq -r '.findings_summary')
if [[ "$PR_SUMMARY" != "Found 5 issues: 2 security, 3 style" ]]; then
  echo "FAIL: expected findings_summary, got $PR_SUMMARY"
  exit 1
fi

PR_TS=$(echo "$PR_PAYLOAD" | jq -r '.timestamp')
if [[ -z "$PR_TS" || "$PR_TS" == "null" ]]; then
  echo "FAIL: expected timestamp to be set, got $PR_TS"
  exit 1
fi

echo "PASS: build_pr_payload creates valid PR notification JSON with all fields"

echo ""
echo "All notify tests passed."
