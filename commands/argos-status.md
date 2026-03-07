---
description: "Show Argos watch status, pending approvals, and recent actions"
allowed-tools: ["Bash"]
---

# Argos Status

Show the user a comprehensive status of all Argos watches.

## Gather Information

1. List all policy files to find watched repos:
   ```bash
   ls ~/.claude/argos/policies/*.yaml 2>/dev/null
   ```

2. For each watched repo, read its state file and extract the minimum confidence level:
   ```bash
   SAFE_NAME="${REPO//\//-}"
   cat ~/.claude/argos/state/${SAFE_NAME}.json 2>/dev/null
   POLICY_FILE="$HOME/.claude/argos/policies/${SAFE_NAME}.yaml"
   POLICY_JSON=$(python3 -c "import yaml,json,sys; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))" "$POLICY_FILE" 2>/dev/null || echo '{}')
   MIN_LEVEL=$(echo "$POLICY_JSON" | jq -r '.floors.minimum // "not set"')
   ```

3. Read the session context log for recent activity:
   ```bash
   cat ~/.claude/argos/session-context.txt 2>/dev/null | tail -20
   ```

## Display Format

Present the status in a clear, readable format:

### Active Watches

| Repo | Poll Interval | Last Poll | Issues Seen | Min Level |
|------|--------------|-----------|-------------|-----------|
| owner/repo | 5m | 2 min ago | 142 | 3 |

### Pending Approvals

If any pending approvals exist, show them with issue number, confidence level, action, and what is awaited:

| # | Issue | Level | Action Pending | Awaiting |
|---|-------|-------|---------------|----------|
| 1 | #42 "Fix auth bug" | 3 (thorough review) | PR ready to open | Your review of the diff |
| 2 | #45 "Add logging" | 4 (needs approval) | Investigation complete | Your go/no-go decision |

If none: "No pending approvals."

### Recent Actions (last 10)

Show from session-context.txt. If empty: "No recent actions recorded."

### Guardrail Status

For each watched repo:
- Actions this hour: 3/10
- Open PRs by Argos: 1/3
