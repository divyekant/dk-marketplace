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

# --- PR Polling Tests ---

# Test: parse_prs unwraps nested author.login and labels[].name to flat strings
PR_JSON='[{"number":18,"title":"fix: recall","author":{"login":"divyekant"},"createdAt":"2026-03-10","labels":[],"headRefName":"fix/recall","commits":[{"messageHeadline":"fix: recall"}]},{"number":17,"title":"feat: new","author":{"login":"bot"},"createdAt":"2026-03-09","labels":[{"name":"skip-argos"}],"headRefName":"feat/new","commits":[{"messageHeadline":"feat: new"}]}]'

PARSED_PRS=$(echo "$PR_JSON" | parse_prs)
COUNT=$(echo "$PARSED_PRS" | jq 'length')
if [[ "$COUNT" != "2" ]]; then
  echo "FAIL: parse_prs expected 2 PRs, got $COUNT"
  exit 1
fi
echo "PASS: parse_prs returns correct count"

FIRST_TITLE=$(echo "$PARSED_PRS" | jq -r '.[0].title')
if [[ "$FIRST_TITLE" != "fix: recall" ]]; then
  echo "FAIL: parse_prs first title expected 'fix: recall', got '$FIRST_TITLE'"
  exit 1
fi
echo "PASS: parse_prs first title correct"

FIRST_AUTHOR=$(echo "$PARSED_PRS" | jq -r '.[0].author')
if [[ "$FIRST_AUTHOR" != "divyekant" ]]; then
  echo "FAIL: parse_prs first author expected 'divyekant' (string), got '$FIRST_AUTHOR'"
  exit 1
fi
echo "PASS: parse_prs unwraps author to flat string"

SECOND_LABEL=$(echo "$PARSED_PRS" | jq -r '.[1].labels[0]')
if [[ "$SECOND_LABEL" != "skip-argos" ]]; then
  echo "FAIL: parse_prs second labels[0] expected 'skip-argos' (string), got '$SECOND_LABEL'"
  exit 1
fi
echo "PASS: parse_prs unwraps labels to flat strings"

# Test: filter_new_prs filters by PR number > last_seen
PR_THREE='[{"number":18,"title":"pr18"},{"number":17,"title":"pr17"},{"number":16,"title":"pr16"}]'
FILTERED_PRS=$(echo "$PR_THREE" | filter_new_prs 17)
COUNT=$(echo "$FILTERED_PRS" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: filter_new_prs expected 1 PR (>17), got $COUNT"
  exit 1
fi
FILTERED_NUM=$(echo "$FILTERED_PRS" | jq '.[0].number')
if [[ "$FILTERED_NUM" != "18" ]]; then
  echo "FAIL: filter_new_prs expected PR #18, got #$FILTERED_NUM"
  exit 1
fi
echo "PASS: filter_new_prs filters by last seen number"

# Test: filter_ignored_prs by author — filters out dependabot (flat author string)
PR_AUTHORS='[{"number":1,"title":"human pr","author":"divyekant","labels":[]},{"number":2,"title":"bot pr","author":"dependabot","labels":[]}]'
FILTERED_AUTH=$(echo "$PR_AUTHORS" | filter_ignored_prs "dependabot" "")
COUNT=$(echo "$FILTERED_AUTH" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: filter_ignored_prs by author expected 1 PR, got $COUNT"
  exit 1
fi
SURV_AUTHOR=$(echo "$FILTERED_AUTH" | jq -r '.[0].author')
if [[ "$SURV_AUTHOR" != "divyekant" ]]; then
  echo "FAIL: filter_ignored_prs expected divyekant to survive, got '$SURV_AUTHOR'"
  exit 1
fi
echo "PASS: filter_ignored_prs filters by author"

# Test: filter_ignored_prs by label — filters out skip-argos (flat label strings)
PR_LABELS='[{"number":1,"title":"clean pr","author":"dev","labels":["bug"]},{"number":2,"title":"skip pr","author":"dev","labels":["skip-argos"]}]'
FILTERED_LBL=$(echo "$PR_LABELS" | filter_ignored_prs "" "skip-argos")
COUNT=$(echo "$FILTERED_LBL" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: filter_ignored_prs by label expected 1 PR, got $COUNT"
  exit 1
fi
SURV_TITLE=$(echo "$FILTERED_LBL" | jq -r '.[0].title')
if [[ "$SURV_TITLE" != "clean pr" ]]; then
  echo "FAIL: filter_ignored_prs expected 'clean pr' to survive, got '$SURV_TITLE'"
  exit 1
fi
echo "PASS: filter_ignored_prs filters by label"

# Test: filter_ignored_prs exact match — "reno" survives when filtering "renovate"
PR_EXACT='[{"number":1,"title":"reno pr","author":"reno","labels":[]},{"number":2,"title":"renovate pr","author":"renovate","labels":[]}]'
FILTERED_EXACT=$(echo "$PR_EXACT" | filter_ignored_prs "renovate" "")
COUNT=$(echo "$FILTERED_EXACT" | jq 'length')
if [[ "$COUNT" != "1" ]]; then
  echo "FAIL: filter_ignored_prs exact match expected 1 PR, got $COUNT"
  exit 1
fi
SURV_EXACT=$(echo "$FILTERED_EXACT" | jq -r '.[0].author')
if [[ "$SURV_EXACT" != "reno" ]]; then
  echo "FAIL: filter_ignored_prs expected 'reno' to survive exact match, got '$SURV_EXACT'"
  exit 1
fi
echo "PASS: filter_ignored_prs uses exact match (reno survives renovate filter)"

echo ""
echo "All poll tests passed."
