---
description: "Approve or reject a pending Argos action"
argument-hint: "#issue_number [reject]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/lib/*:*)"]
---

# Argos Approve

The user wants to approve or reject a pending action.

## Arguments

The user provided: `$ARGUMENTS`

Parse:
- Issue number (e.g., `#42` or `42`)
- Optional `reject` keyword (if present, reject instead of approve)

## Find the Pending Approval

Search across all state files for this issue number:
```bash
for state_file in ~/.claude/argos/state/*.json; do
  MATCH=$(jq --argjson num ISSUE_NUM '.pending_approvals[] | select(.issue == $num)' "$state_file" 2>/dev/null)
  if [[ -n "$MATCH" ]]; then
    echo "Found in $state_file"
    echo "$MATCH"
    break
  fi
done
```

If not found: "No pending approval found for issue #N. Run `/argos-status` to see pending items."

## If Approving

1. Show the user what will be executed:
   "Approving: level [N] action on [repo]#[issue] -- [summary]"

2. The pending approval entry stores a `level_N` action field. Execute based on the level:
   - For **level 3** (thorough review): The fix is already on a branch. Open the PR linking to the issue.
   - For **level 4** (needs approval): Proceed with the recommended approach — create branch, implement the fix, run tests, push, and open PR.

3. Remove from pending approvals:
   ```bash
   source lib/state.sh
   remove_pending_approval "$REPO" ISSUE_NUM
   ```

4. Send notification via configured channels

5. Store calibration memory so Argos learns from human decisions:
   ```
   memory_add: "argos/<owner>/<repo>/calibration: level <N> for <issue-type> — human approved. Reason: <if given>"
   ```

## If Rejecting

1. Confirm: "Rejecting: level [N] action on [repo]#[issue]"
2. Remove from pending approvals
3. Optionally post a GitHub comment noting the action was reviewed and declined
4. Store calibration memory so Argos learns what gets rejected:
   ```
   memory_add: "argos/<owner>/<repo>/calibration: level <N> for <issue-type> — human rejected. Reason: <if given>"
   ```
