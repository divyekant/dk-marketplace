# Argos Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude Code plugin that watches GitHub repos for new issues and acts on them within configurable tiered-autonomy boundaries.

**Architecture:** Pure CC plugin using `/loop` for scheduling, `gh` CLI for GitHub API, bash scripts for polling/state/notifications, SKILL.md as the agent brain, and Memories MCP for persistent cross-session learning.

**Tech Stack:** Bash (lib scripts, adapters, hooks), YAML (policy config), JSON (state files, plugin manifest), Markdown (commands, skill), `gh` CLI, `jq`

**Design doc:** `docs/plans/2026-03-06-argos-design.md`

---

### Task 1: Plugin Scaffold

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `README.md`

**Step 1: Create plugin.json**

```json
{
  "name": "argos",
  "version": "0.1.0",
  "description": "The All-Seeing Issue Guardian — watches GitHub repos and acts on issues within configurable boundaries",
  "author": "Divyekant Keshri",
  "license": "MIT"
}
```

**Step 2: Create README.md**

Write a README with:
- Project name and one-line description
- Quick start (`/watch owner/repo`)
- Commands list
- Link to design doc
- Dependencies (gh, jq, Memories MCP)

**Step 3: Verify plugin structure**

Run: `ls -la .claude-plugin/plugin.json README.md`
Expected: Both files exist

**Step 4: Commit**

```bash
git add .claude-plugin/plugin.json README.md
git commit -m "feat: scaffold plugin with manifest and README"
```

---

### Task 2: Default Policy Template

**Files:**
- Create: `config/default-policy.yaml`

**Step 1: Create default policy YAML**

```yaml
repo: ""
poll_interval: 5m

actions:
  auto:
    - label
    - comment_triage
    - assign
    - close_duplicate
  approve:
    - comment_diagnosis
    - create_branch
    - push_commits
    - open_pr
  deny:
    - close_issue
    - merge_pr
    - force_push
    - delete_branch

approval_modes:
  comment_diagnosis:
    mode: timeout
    timeout: 2h
  create_branch:
    mode: default
    timeout: 4h
  push_commits:
    mode: wait
  open_pr:
    mode: wait

filters:
  labels: ["bug", "enhancement", "help-wanted"]
  ignore_labels: ["wontfix", "on-hold", "discussion"]
  only_new: true
  max_age: 7d

notifications:
  auto_actions:
    - github_comment
  approval_needed:
    - system
    - github_comment
  approval_expired:
    - system

guardrails:
  max_actions_per_hour: 10
  max_open_prs: 3
  require_tests: true
  max_files_changed: 10
  protected_paths:
    - ".env*"
    - "*.secret"
    - "config/production.*"
  dry_run: false
```

**Step 2: Verify YAML is valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('config/default-policy.yaml'))"`
Expected: No error

**Step 3: Commit**

```bash
git add config/default-policy.yaml
git commit -m "feat: add default policy template with tiered autonomy config"
```

---

### Task 3: State Management Library

**Files:**
- Create: `lib/state.sh`
- Create: `tests/test-state.sh`

**Step 1: Write the test script**

```bash
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

echo ""
echo "All state tests passed."
```

**Step 2: Run tests to verify they fail**

Run: `bash tests/test-state.sh`
Expected: FAIL — `lib/state.sh` doesn't exist yet

**Step 3: Implement lib/state.sh**

```bash
#!/bin/bash
# lib/state.sh — State management for Argos
# Manages per-repo state: seen issues, pending approvals, action counts

ARGOS_STATE_DIR="${ARGOS_STATE_DIR:-$HOME/.claude/argos/state}"

_state_file() {
  local repo="$1"
  local safe_name="${repo//\//-}"
  echo "$ARGOS_STATE_DIR/$safe_name.json"
}

init_state() {
  local repo="$1"
  local state_file
  state_file=$(_state_file "$repo")
  mkdir -p "$(dirname "$state_file")"
  if [[ ! -f "$state_file" ]]; then
    cat > "$state_file" <<'INIT'
{
  "last_poll": null,
  "last_issue_seen": 0,
  "pending_approvals": [],
  "actions_this_hour": 0,
  "actions_hour_start": null
}
INIT
  fi
}

get_last_issue_seen() {
  local repo="$1"
  jq -r '.last_issue_seen // 0' "$(_state_file "$repo")"
}

set_last_issue_seen() {
  local repo="$1" issue_num="$2"
  local state_file
  state_file=$(_state_file "$repo")
  local tmp="${state_file}.tmp.$$"
  jq --argjson num "$issue_num" '.last_issue_seen = $num | .last_poll = now | .last_poll = (now | todate)' "$state_file" > "$tmp"
  mv "$tmp" "$state_file"
}

add_pending_approval() {
  local repo="$1" issue_num="$2" action="$3" mode="$4" summary="$5"
  local state_file
  state_file=$(_state_file "$repo")
  local tmp="${state_file}.tmp.$$"
  jq --argjson num "$issue_num" \
     --arg action "$action" \
     --arg mode "$mode" \
     --arg summary "$summary" \
     '.pending_approvals += [{
       "issue": $num,
       "action": $action,
       "proposed_at": (now | todate),
       "mode": $mode,
       "summary": $summary
     }]' "$state_file" > "$tmp"
  mv "$tmp" "$state_file"
}

remove_pending_approval() {
  local repo="$1" issue_num="$2"
  local state_file
  state_file=$(_state_file "$repo")
  local tmp="${state_file}.tmp.$$"
  jq --argjson num "$issue_num" \
     '.pending_approvals = [.pending_approvals[] | select(.issue != $num)]' "$state_file" > "$tmp"
  mv "$tmp" "$state_file"
}

get_pending_count() {
  local repo="$1"
  jq '.pending_approvals | length' "$(_state_file "$repo")"
}

get_pending_approvals() {
  local repo="$1"
  jq -r '.pending_approvals' "$(_state_file "$repo")"
}

increment_actions_count() {
  local repo="$1"
  local state_file
  state_file=$(_state_file "$repo")
  local tmp="${state_file}.tmp.$$"
  local current_hour
  current_hour=$(date -u +"%Y-%m-%dT%H")
  local stored_hour
  stored_hour=$(jq -r '.actions_hour_start // ""' "$state_file")
  if [[ "$stored_hour" != "$current_hour" ]]; then
    jq --arg hour "$current_hour" \
       '.actions_this_hour = 1 | .actions_hour_start = $hour' "$state_file" > "$tmp"
  else
    jq '.actions_this_hour += 1' "$state_file" > "$tmp"
  fi
  mv "$tmp" "$state_file"
}

get_actions_this_hour() {
  local repo="$1"
  local state_file
  state_file=$(_state_file "$repo")
  local current_hour
  current_hour=$(date -u +"%Y-%m-%dT%H")
  local stored_hour
  stored_hour=$(jq -r '.actions_hour_start // ""' "$state_file")
  if [[ "$stored_hour" != "$current_hour" ]]; then
    echo "0"
  else
    jq -r '.actions_this_hour // 0' "$state_file"
  fi
}

check_rate_limit() {
  local repo="$1" max="$2"
  local count
  count=$(get_actions_this_hour "$repo")
  [[ "$count" -lt "$max" ]]
}
```

**Step 4: Run tests to verify they pass**

Run: `bash tests/test-state.sh`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/state.sh tests/test-state.sh
git commit -m "feat: add state management library with tests"
```

---

### Task 4: Polling Library

**Files:**
- Create: `lib/poll.sh`
- Create: `tests/test-poll.sh`

**Step 1: Write the test script**

```bash
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
```

**Step 2: Run tests to verify they fail**

Run: `bash tests/test-poll.sh`
Expected: FAIL — `lib/poll.sh` doesn't exist yet

**Step 3: Implement lib/poll.sh**

```bash
#!/bin/bash
# lib/poll.sh — GitHub issue polling via gh CLI
# Fetches new issues and provides filtering functions

fetch_issues() {
  local repo="$1"
  local since="${2:-}"
  local args=(issue list --repo "$repo" --state open --json "number,title,labels,createdAt,url,author,body" --limit 50)
  if [[ -n "$since" ]]; then
    args+=(--search "created:>=$since")
  fi
  gh "${args[@]}" 2>/dev/null || echo "[]"
}

parse_issues() {
  jq '[.[] | {
    number: .number,
    title: .title,
    labels: [.labels[]?.name],
    created_at: .createdAt,
    url: .url,
    author: .author.login,
    body: (.body // "")
  }]'
}

filter_by_labels() {
  local wanted_labels="$1"
  jq --argjson wanted "$wanted_labels" '
    [.[] | select(
      (.labels | length == 0) or
      (.labels as $l | $wanted | any(. as $w | $l | any(. == $w)))
    )]
  '
}

filter_ignore_labels() {
  local ignore_labels="$1"
  jq --argjson ignore "$ignore_labels" '
    [.[] | select(
      .labels as $l | ($ignore | all(. as $ig | $l | all(. != $ig)))
    )]
  '
}

filter_new_issues() {
  local last_seen="$1"
  jq --argjson last "$last_seen" '[.[] | select(.number > $last)]'
}

filter_max_age() {
  local max_age_days="$1"
  local cutoff
  cutoff=$(date -u -v-"${max_age_days}"d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
           date -u -d "${max_age_days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  if [[ -n "$cutoff" ]]; then
    jq --arg cutoff "$cutoff" '[.[] | select(.created_at >= $cutoff)]'
  else
    cat
  fi
}

has_new_issues() {
  local repo="$1" last_seen="$2"
  local count
  count=$(fetch_issues "$repo" | parse_issues | filter_new_issues "$last_seen" | jq 'length')
  [[ "$count" -gt 0 ]]
}
```

**Step 4: Run tests to verify they pass**

Run: `bash tests/test-poll.sh`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/poll.sh tests/test-poll.sh
git commit -m "feat: add polling library with issue fetching and filtering"
```

---

### Task 5: Notification System

**Files:**
- Create: `lib/notify.sh`
- Create: `lib/adapters/github-comment.sh`
- Create: `lib/adapters/system.sh`
- Create: `lib/adapters/session.sh`
- Create: `tests/test-notify.sh`

**Step 1: Write the test script**

```bash
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

echo ""
echo "All notify tests passed."
```

**Step 2: Run tests to verify they fail**

Run: `bash tests/test-notify.sh`
Expected: FAIL

**Step 3: Implement lib/notify.sh**

```bash
#!/bin/bash
# lib/notify.sh — Notification dispatcher for Argos
# Routes notifications to pluggable adapters based on policy config

ARGOS_PLUGIN_ROOT="${ARGOS_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ARGOS_ADAPTER_DIR="${ARGOS_ADAPTER_DIR:-$ARGOS_PLUGIN_ROOT/lib/adapters}"

build_payload() {
  local event="$1" repo="$2" issue="$3" title="$4" action="$5" details="$6"
  jq -n \
    --arg event "$event" \
    --arg repo "$repo" \
    --argjson issue "$issue" \
    --arg title "$title" \
    --arg action "$action" \
    --arg details "$details" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
      event: $event,
      repo: $repo,
      issue: $issue,
      title: $title,
      action: $action,
      details: $details,
      timestamp: $timestamp
    }'
}

dispatch_to_adapter() {
  local adapter_name="$1"
  local adapter_script="$ARGOS_ADAPTER_DIR/${adapter_name}.sh"
  if [[ -x "$adapter_script" ]]; then
    cat | bash "$adapter_script"
  else
    echo "Warning: adapter '$adapter_name' not found at $adapter_script" >&2
  fi
}

notify() {
  local event="$1" repo="$2" issue="$3" title="$4" action="$5" details="$6"
  shift 6
  local adapters=("$@")
  local payload
  payload=$(build_payload "$event" "$repo" "$issue" "$title" "$action" "$details")
  for adapter in "${adapters[@]}"; do
    echo "$payload" | dispatch_to_adapter "$adapter" &
  done
  wait
}
```

**Step 4: Implement lib/adapters/github-comment.sh**

```bash
#!/bin/bash
# lib/adapters/github-comment.sh — Post a comment on the GitHub issue
set -euo pipefail

PAYLOAD=$(cat)
REPO=$(echo "$PAYLOAD" | jq -r '.repo')
ISSUE=$(echo "$PAYLOAD" | jq -r '.issue')
EVENT=$(echo "$PAYLOAD" | jq -r '.event')
ACTION=$(echo "$PAYLOAD" | jq -r '.action')
DETAILS=$(echo "$PAYLOAD" | jq -r '.details')
TIMESTAMP=$(echo "$PAYLOAD" | jq -r '.timestamp')

COMMENT="**Argos** ($EVENT)

**Action:** $ACTION
**Details:** $DETAILS
**Time:** $TIMESTAMP"

gh issue comment "$ISSUE" --repo "$REPO" --body "$COMMENT" 2>/dev/null || true
```

**Step 5: Implement lib/adapters/system.sh**

```bash
#!/bin/bash
# lib/adapters/system.sh — macOS native notification
set -euo pipefail

PAYLOAD=$(cat)
TITLE=$(echo "$PAYLOAD" | jq -r '"Argos: " + .repo')
BODY=$(echo "$PAYLOAD" | jq -r '.action + " on #" + (.issue | tostring) + ": " + .title')
EVENT=$(echo "$PAYLOAD" | jq -r '.event')

if [[ "$(uname)" == "Darwin" ]]; then
  osascript -e "display notification \"$BODY\" with title \"$TITLE\" subtitle \"$EVENT\"" 2>/dev/null || true
fi
```

**Step 6: Implement lib/adapters/session.sh**

```bash
#!/bin/bash
# lib/adapters/session.sh — Write to session context file for CC SessionStart hook
set -euo pipefail

ARGOS_SESSION_FILE="${ARGOS_SESSION_FILE:-$HOME/.claude/argos/session-context.txt}"
mkdir -p "$(dirname "$ARGOS_SESSION_FILE")"

PAYLOAD=$(cat)
REPO=$(echo "$PAYLOAD" | jq -r '.repo')
ISSUE=$(echo "$PAYLOAD" | jq -r '.issue')
ACTION=$(echo "$PAYLOAD" | jq -r '.action')
DETAILS=$(echo "$PAYLOAD" | jq -r '.details')
EVENT=$(echo "$PAYLOAD" | jq -r '.event')

echo "[$EVENT] $REPO#$ISSUE: $ACTION — $DETAILS" >> "$ARGOS_SESSION_FILE"
```

**Step 7: Run tests to verify they pass**

Run: `bash tests/test-notify.sh`
Expected: All tests pass

**Step 8: Commit**

```bash
git add lib/notify.sh lib/adapters/ tests/test-notify.sh
git commit -m "feat: add notification system with pluggable adapters"
```

---

### Task 6: Policy Loader

**Files:**
- Create: `lib/policy.sh`
- Create: `tests/test-policy.sh`

**Step 1: Write the test script**

```bash
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
```

**Step 2: Run tests to verify they fail**

Run: `bash tests/test-policy.sh`
Expected: FAIL

**Step 3: Implement lib/policy.sh**

```bash
#!/bin/bash
# lib/policy.sh — Policy loading and boundary checking for Argos
# Reads YAML policy files and provides functions to check action tiers,
# approval modes, and guardrails.

load_policy() {
  local policy_file="$1"
  if [[ ! -f "$policy_file" ]]; then
    echo '{}'
    return 1
  fi
  python3 -c "
import yaml, json, sys
with open(sys.argv[1]) as f:
    print(json.dumps(yaml.safe_load(f)))
" "$policy_file"
}

get_action_tier() {
  local action="$1"
  jq -r --arg action "$action" '
    if (.actions.auto // [] | any(. == $action)) then "auto"
    elif (.actions.approve // [] | any(. == $action)) then "approve"
    elif (.actions.deny // [] | any(. == $action)) then "deny"
    else "deny"
    end
  '
}

get_approval_mode() {
  local action="$1"
  jq -r --arg action "$action" '
    .approval_modes[$action].mode // "wait"
  '
}

get_approval_timeout() {
  local action="$1"
  jq -r --arg action "$action" '
    .approval_modes[$action].timeout // "24h"
  '
}

get_poll_interval() {
  jq -r '.poll_interval // "5m"'
}

get_filter_labels() {
  jq -r '.filters.labels // []'
}

get_ignore_labels() {
  jq -r '.filters.ignore_labels // []'
}

get_max_age() {
  jq -r '.filters.max_age // "7d"' | sed 's/d//'
}

is_dry_run() {
  jq -r '.guardrails.dry_run // false'
}

get_guardrail() {
  local key="$1"
  jq -r --arg key "$key" '.guardrails[$key] // ""'
}

is_path_protected() {
  local filepath="$1"
  local protected_patterns
  protected_patterns=$(jq -r '.guardrails.protected_paths // [] | .[]')
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    # Use bash pattern matching for glob-style checks
    # shellcheck disable=SC2254
    case "$filepath" in
      $pattern) return 0 ;;
    esac
  done <<< "$protected_patterns"
  return 1
}

get_notification_channels() {
  local event_type="$1"
  jq -r --arg event "$event_type" '.notifications[$event] // [] | .[]'
}
```

**Step 4: Run tests to verify they pass**

Run: `bash tests/test-policy.sh`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/policy.sh tests/test-policy.sh
git commit -m "feat: add policy loader with tier checking and guardrails"
```

---

### Task 7: Core Skill (SKILL.md)

**Files:**
- Create: `skills/argos/SKILL.md`

**Step 1: Write the skill file**

This is the agent's brain — the prompt that tells CC how to triage, investigate, and act. It should:
- Describe the full workflow (poll → classify → check policy → act/defer/skip)
- Define how to classify issues (bug vs enhancement vs duplicate)
- Define each action type and how to execute it
- Enforce guardrails and security rules (sanitize issue content, respect protected paths)
- Integrate with Memories MCP for learning
- Handle approval flow (log pending, check existing pending)
- Include dry-run mode behavior

The skill should reference lib scripts for state/policy/notify but handle classification and investigation itself via CC's capabilities.

Key sections:
1. Overview & trigger conditions
2. Workflow steps
3. Issue classification rules
4. Action definitions (label, comment_triage, assign, close_duplicate, comment_diagnosis, create_branch, push_commits, open_pr)
5. Security rules (prompt injection defense, protected paths)
6. Memories integration (what to remember, what prefix to use)
7. Dry-run behavior

**Step 2: Verify skill loads**

Run: `cat skills/argos/SKILL.md | head -5`
Expected: Shows the skill header

**Step 3: Commit**

```bash
git add skills/argos/SKILL.md
git commit -m "feat: add core Argos skill with triage and action logic"
```

---

### Task 8: Commands — /watch and /unwatch

**Files:**
- Create: `commands/watch.md`
- Create: `commands/unwatch.md`

**Step 1: Write watch.md**

The `/watch` command should:
1. Accept `owner/repo` as argument
2. Check prerequisites (gh authenticated, jq installed)
3. If no policy exists for this repo, trigger onboarding (guided policy creation)
4. If policy exists, start the `/loop` with Argos skill
5. Register the watch in state

```markdown
---
description: "Start watching a GitHub repo for new issues"
argument-hint: "owner/repo"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/lib/*:*)"]
---

# Watch Command

[Onboarding and loop-start logic here]
```

**Step 2: Write unwatch.md**

The `/unwatch` command should:
1. Accept `owner/repo` as argument
2. Stop the active `/loop` for that repo
3. Clean up state (optionally preserve memories)

**Step 3: Commit**

```bash
git add commands/watch.md commands/unwatch.md
git commit -m "feat: add /watch and /unwatch commands"
```

---

### Task 9: Commands — /argos-status and /argos-approve

**Files:**
- Create: `commands/argos-status.md`
- Create: `commands/argos-approve.md`

**Step 1: Write argos-status.md**

Shows:
- Active watches (repo, poll interval, last poll time)
- Pending approvals (issue #, action, proposed time, mode/timeout)
- Recent actions taken (last 10)
- Guardrail status (actions this hour / max)

**Step 2: Write argos-approve.md**

Accepts `#issue_number` or `#issue_number reject`:
- Loads pending approval from state
- If approved: executes the pending action, removes from pending, notifies
- If rejected: removes from pending, notifies, adds memory note

**Step 3: Commit**

```bash
git add commands/argos-status.md commands/argos-approve.md
git commit -m "feat: add /argos-status and /argos-approve commands"
```

---

### Task 10: Session Start Hook

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/session-start.sh`

**Step 1: Write hooks.json**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "'${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh'",
            "async": true,
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**Step 2: Write session-start.sh**

The hook should:
1. Check if any session-context.txt exists (written by session adapter)
2. Check for pending approvals across all watched repos
3. Check for expired timeouts and process them (auto-proceed or auto-skip)
4. Return JSON with `additional_context` summarizing pending items

```bash
#!/bin/bash
set -euo pipefail

ARGOS_STATE_DIR="$HOME/.claude/argos/state"
ARGOS_SESSION_FILE="$HOME/.claude/argos/session-context.txt"

# Collect pending approvals and recent actions
# Output as additional_context for CC session injection
```

**Step 3: Make executable and test**

Run: `chmod +x hooks/session-start.sh && bash hooks/session-start.sh`
Expected: Returns JSON (or exits silently if no state)

**Step 4: Commit**

```bash
git add hooks/hooks.json hooks/session-start.sh
git commit -m "feat: add session-start hook for pending approval injection"
```

---

### Task 11: Onboarding Flow

**Files:**
- Modify: `commands/watch.md` (add onboarding logic)

**Step 1: Add onboarding to watch command**

The onboarding section of `/watch` should guide the user through policy creation when no policy file exists:
1. Check prerequisites (gh, jq, memories MCP)
2. Ask about issue labels to watch (multiple choice)
3. Ask about auto actions (multiple choice)
4. Ask about approve actions (multiple choice)
5. Ask about approval modes per approve-action
6. Ask about poll interval
7. Ask about notification preferences
8. Generate policy YAML, show it, confirm
9. Run a dry-run cycle
10. Start the loop

**Step 2: Verify onboarding triggers**

Manual test: run `/watch test/repo` without a policy file
Expected: Onboarding conversation starts

**Step 3: Commit**

```bash
git add commands/watch.md
git commit -m "feat: add guided onboarding flow to /watch command"
```

---

### Task 12: Integration Test — End-to-End Dry Run

**Files:**
- Create: `tests/test-e2e.sh`

**Step 1: Write end-to-end test**

```bash
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

# 5. Check guardrail
if ! check_rate_limit "$REPO" 10; then
  echo "FAIL: should be under rate limit"
  exit 1
fi
echo "PASS: Rate limit check passes"

# 6. Update state
set_last_issue_seen "$REPO" 2
LAST=$(get_last_issue_seen "$REPO")
if [[ "$LAST" != "2" ]]; then
  echo "FAIL: last_issue_seen should be 2"
  exit 1
fi
echo "PASS: State updated with last seen issue"

echo ""
echo "All end-to-end tests passed."
```

**Step 2: Run e2e test**

Run: `bash tests/test-e2e.sh`
Expected: All tests pass

**Step 3: Commit**

```bash
git add tests/test-e2e.sh
git commit -m "test: add end-to-end integration test with mock data"
```

---

### Task 13: Final Verification & Cleanup

**Step 1: Run all tests**

Run: `for t in tests/test-*.sh; do echo "=== $t ===" && bash "$t" && echo ""; done`
Expected: All test suites pass

**Step 2: Verify plugin structure matches design**

Run: `find . -type f | grep -v '.git/' | sort`
Expected: All files from design doc section 3.2 exist

**Step 3: Update README with final structure**

Ensure README reflects actual implemented structure, commands, and usage.

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: final cleanup and README update"
```

---

## Task Dependency Order

```
Task 1 (scaffold)
  └→ Task 2 (policy template)
  └→ Task 3 (state lib)
  └→ Task 4 (poll lib)
  └→ Task 5 (notify system)
  └→ Task 6 (policy loader)
       └→ Task 7 (core skill)
       └→ Task 8 (watch/unwatch commands)
       └→ Task 9 (status/approve commands)
       └→ Task 10 (session hook)
       └→ Task 11 (onboarding)
            └→ Task 12 (e2e test)
                 └→ Task 13 (final verification)
```

Tasks 2-6 can be parallelized. Tasks 7-11 depend on the libs. Task 12-13 are sequential at the end.
