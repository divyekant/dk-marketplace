#!/bin/bash
# tests/test-poll.sh — verify polling functions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/poll.sh"

# Test: parse_issues extracts fields from gh JSON
MOCK_JSON='[
  {"number": 42, "title": "Bug in login", "labels": [{"name": "bug"}], "createdAt": "2026-03-06T10:00:00Z", "url": "https://github.com/owner/repo/issues/42", "author": {"login": "user1"}},
  {"number": 43, "title": "Add feature", "labels": [{"name": "enhancement"}], "createdAt": "2026-03-06T11:00:00Z", "url": "https://github.com/owner/repo/issues/43", "author": {"login": "user2"}}
]'

PARSED=$(echo "$MOCK_JSON" | parse_issues)
COUNT=$(echo "$PARSED" | jq 'length')
if [[ "$COUNT" != "2" ]]; then
  echo "FAIL: expected 2 parsed issues, got $COUNT"
  exit 1
fi
echo "PASS: parse_issues extracts correct count"

# Test: filter_by_labels keeps matching issues
FILTERED=$(echo "$MOCK_JSON" | filter_by_labels '["bug"]')
COUNT=$(echo "$FILTERED" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 filtered issue, got $COUNT"
  exit 1
fi
echo "PASS: filter_by_labels filters correctly"

# Test: filter_by_labels with empty list passes all issues through
FILTERED=$(echo "$MOCK_JSON" | filter_by_labels '[]')
COUNT=$(echo "$FILTERED" | jq 'length')
if [[ "$COUNT" != "2" ]]; then
  echo "FAIL: expected 2 issues with empty filter, got $COUNT"
  exit 1
fi
echo "PASS: filter_by_labels with empty list passes all through"

# Test: filter_by_labels with ignore list
FILTERED=$(echo "$MOCK_JSON" | filter_ignore_labels '["enhancement"]')
COUNT=$(echo "$FILTERED" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 issue after ignore filter, got $COUNT"
  exit 1
fi
echo "PASS: filter_ignore_labels filters correctly"

# Test: filter_new_issues filters by issue number
FILTERED=$(echo "$MOCK_JSON" | filter_new_issues 42)
COUNT=$(echo "$FILTERED" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: expected 1 new issue (>42), got $COUNT"
  exit 1
fi
echo "PASS: filter_new_issues filters by last seen number"

echo ""
echo "All poll tests passed."
