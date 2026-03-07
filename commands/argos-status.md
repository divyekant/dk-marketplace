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

2. For each watched repo, read its state file:
   ```bash
   SAFE_NAME="${REPO//\//-}"
   cat ~/.claude/argos/state/${SAFE_NAME}.json 2>/dev/null
   ```

3. Read the session context log for recent activity:
   ```bash
   cat ~/.claude/argos/session-context.txt 2>/dev/null | tail -20
   ```

## Display Format

Present the status in a clear, readable format:

### Active Watches

| Repo | Poll Interval | Last Poll | Issues Seen |
|------|--------------|-----------|-------------|
| owner/repo | 5m | 2 min ago | 142 |

### Pending Approvals

If any pending approvals exist, show them with issue number, action, proposed time, mode, and timeout:

| # | Issue | Action | Proposed | Mode | Expires |
|---|-------|--------|----------|------|---------|
| 1 | #42 "Fix auth bug" | open_pr | 30m ago | wait | never (manual) |
| 2 | #45 "Add logging" | create_branch | 2h ago | timeout 4h | in 2h |

If none: "No pending approvals."

### Recent Actions (last 10)

Show from session-context.txt. If empty: "No recent actions recorded."

### Guardrail Status

For each watched repo:
- Actions this hour: 3/10
- Open PRs by Argos: 1/3
