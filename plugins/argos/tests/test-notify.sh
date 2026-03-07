#!/bin/bash
# tests/test-notify.sh — verify notification dispatch
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/notify.sh"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Test: build_payload creates valid JSON
PAYLOAD=$(build_payload "auto_action_taken" "owner/repo" 42 "Bug title" "label" "Applied label: bug")
EVENT=$(echo "$PAYLOAD" | jq -r '.event')
if [[ "$EVENT" != "auto_action_taken" ]]; then
  echo "FAIL: expected event=auto_action_taken, got $EVENT"
  exit 1
fi
echo "PASS: build_payload creates valid JSON"

# Test: dispatch routes to correct adapters
export ARGOS_ADAPTER_DIR="$TEMP_DIR/adapters"
mkdir -p "$ARGOS_ADAPTER_DIR"
# Create a mock adapter that writes to a file
cat > "$ARGOS_ADAPTER_DIR/mock.sh" << 'MOCK'
#!/bin/bash
cat > "$ARGOS_ADAPTER_DIR/mock-received.json"
MOCK
chmod +x "$ARGOS_ADAPTER_DIR/mock.sh"

PAYLOAD=$(build_payload "test_event" "owner/repo" 1 "Test" "test" "Test details")
echo "$PAYLOAD" | dispatch_to_adapter "mock"
if [[ ! -f "$ARGOS_ADAPTER_DIR/mock-received.json" ]]; then
  echo "FAIL: mock adapter was not called"
  exit 1
fi
echo "PASS: dispatch_to_adapter routes to adapter script"

# Test: dispatch rejects adapter names with path traversal
OUTPUT=$(echo '{}' | dispatch_to_adapter "../../etc/evil" 2>&1 || true)
if echo "$OUTPUT" | grep -q "invalid adapter name"; then
  echo "PASS: dispatch_to_adapter rejects path traversal in adapter name"
else
  echo "FAIL: dispatch_to_adapter did not reject path traversal"
  exit 1
fi

# Test: dispatch rejects adapter names with dots
OUTPUT=$(echo '{}' | dispatch_to_adapter "evil.payload" 2>&1 || true)
if echo "$OUTPUT" | grep -q "invalid adapter name"; then
  echo "PASS: dispatch_to_adapter rejects dots in adapter name"
else
  echo "FAIL: dispatch_to_adapter did not reject dots"
  exit 1
fi

echo ""
echo "All notify tests passed."
