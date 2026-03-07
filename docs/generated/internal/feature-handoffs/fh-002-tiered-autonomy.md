---
id: fh-002
type: feature-handoff
audience: internal
topic: Tiered Autonomy
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Feature Handoff: Tiered Autonomy

## What It Does

Tiered Autonomy is the policy-driven permission system that governs what Argos is allowed to do. Every action Argos can take is assigned to one of three tiers -- `auto`, `approve`, or `deny` -- defined in a per-repo YAML policy file. The tier determines whether an action runs immediately, waits for explicit human approval, or is permanently blocked. This system ensures Argos never exceeds the boundaries the user configured.

## How It Works

### The Three Tiers

| Tier | Behavior |
|------|----------|
| `auto` | Action executes immediately with no human intervention. Notifications are sent after execution. |
| `approve` | Action is proposed and queued as a pending approval. Human must run `/argos-approve` to execute, or the approval mode determines what happens on timeout. |
| `deny` | Action is never performed, regardless of context. The action is skipped and logged. |

Any action not explicitly listed in `auto` or `approve` is implicitly denied. This fail-closed design ensures new or unknown actions cannot execute without being explicitly permitted.

### Policy File Structure

Each watched repo has a policy YAML at `~/.claude/argos/policies/<owner>-<repo>.yaml`. The `actions` section defines tiers:

```yaml
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
```

### Approval Modes

Actions in the `approve` tier have a secondary behavior defined in `approval_modes`:

| Mode | Behavior |
|------|----------|
| `wait` | Blocks indefinitely until the user approves via `/argos-approve`. Safest option. |
| `timeout` | If no response within the timeout window, the action is **skipped** (not executed). Safe for advisory actions. |
| `default` | If no response within the timeout window, the action **proceeds automatically**. Use for low-risk actions the user almost always approves. |

Example configuration:

```yaml
approval_modes:
  comment_diagnosis:
    mode: timeout
    timeout: 2h
  create_branch:
    mode: timeout
    timeout: 4h
  push_commits:
    mode: wait
  open_pr:
    mode: wait
```

### Action Execution Pipeline

For every action on every issue, the skill runs through this pipeline (SKILL.md section 5):

1. **Determine tier:** `get_action_tier "$ACTION"` checks the policy.
2. **If deny:** skip, log reason, continue to next action.
3. **Check rate limit:** `check_rate_limit "$REPO" "$MAX_ACTIONS_PER_HOUR"`. If blocked, skip and notify.
4. **Check dry_run:** If `guardrails.dry_run` is true, log what would happen but do not execute.
5. **If auto:** execute the action, increment action count, notify, log to Memories MCP.
6. **If approve:**
   a. Get approval mode: `get_approval_mode "$ACTION"`.
   b. Add to pending: `add_pending_approval "$REPO" "$NUMBER" "$ACTION" "$MODE" "$SUMMARY"`.
   c. Notify via `approval_needed` channels.
   d. Do not execute yet.

### Pending Approval Lifecycle

Pending approvals are stored in the repo's state file (`~/.claude/argos/state/<owner>-<repo>.json`) as an array of objects. Each entry records the issue number, action, proposed timestamp, mode, and summary.

The `session-start.sh` hook checks for expired approvals on every CC session start. For `timeout` mode, expired entries are auto-removed (action skipped). For `default` mode, expired entries trigger auto-execution. For `wait` mode, entries persist indefinitely.

### Hard-Coded Deny List

The onboarding flow enforces that `close_issue`, `merge_pr`, `force_push`, and `delete_branch` are always in the `deny` tier. The user cannot move these to `auto` or `approve` during onboarding. These represent destructive or high-risk operations that Argos should never perform autonomously.

## Configuration

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `actions.auto` | Policy YAML | `[label, comment_triage, assign, close_duplicate]` | Actions that execute without approval |
| `actions.approve` | Policy YAML | `[comment_diagnosis, create_branch, push_commits, open_pr]` | Actions that require approval |
| `actions.deny` | Policy YAML | `[close_issue, merge_pr, force_push, delete_branch]` | Actions that are permanently blocked |
| `approval_modes.<action>.mode` | Policy YAML | `wait` | One of: `wait`, `timeout`, `default` |
| `approval_modes.<action>.timeout` | Policy YAML | `24h` (fallback) | Duration string (e.g., `2h`, `4h`, `1d`) |

**Files involved:**
- `/Users/divyekant/Projects/argos/lib/policy.sh` -- `load_policy`, `get_action_tier`, `get_approval_mode`, `get_approval_timeout`
- `/Users/divyekant/Projects/argos/lib/state.sh` -- `add_pending_approval`, `remove_pending_approval`, `get_pending_approvals`
- `/Users/divyekant/Projects/argos/config/default-policy.yaml` -- default tier assignments
- `/Users/divyekant/Projects/argos/hooks/session-start.sh` -- expired approval processing

## Edge Cases

1. **Action not listed in any tier.** `get_action_tier` defaults to `"deny"` for any action not found in `auto`, `approve`, or `deny`. This fail-closed behavior is critical for safety.

2. **Multiple pending approvals for the same issue.** An issue can have multiple pending approvals (e.g., both `create_branch` and `open_pr`). Each is tracked as a separate entry in `pending_approvals`. Approving one does not approve the others. `remove_pending_approval` supports action-specific removal.

3. **Approval timeout expires between polls.** The `session-start.sh` hook processes expired approvals at session start, not at poll time. If a `timeout`-mode approval expires while Argos is actively running in a `/loop`, it will be processed on the next session start or the next Step 5 of the workflow (pending approval sweep).

4. **Policy file missing.** `load_policy` returns `{}` and returns exit code 1. The skill falls back to `config/default-policy.yaml` per error handling rules (SKILL.md section 9).

5. **User manually edits the policy YAML mid-run.** Policy is loaded fresh at the start of each poll cycle. Manual edits take effect on the next cycle without requiring a restart.

## Common Questions

### Q1: Can I move an action from `approve` to `auto` after watching for a while?

Yes. Edit the policy YAML at `~/.claude/argos/policies/<owner>-<repo>.yaml`. Move the action name from the `approve` list to the `auto` list. The change takes effect on the next poll cycle. No restart required.

### Q2: What is the difference between `timeout` and `default` approval modes?

Both have a time window. The difference is what happens when the window expires without a response:
- `timeout`: the action is **skipped** (conservative -- nothing happens).
- `default`: the action **proceeds automatically** (progressive -- assumes implicit approval).

Use `timeout` for actions where inaction is safer than action. Use `default` for actions you almost always approve.

### Q3: Can I approve multiple pending actions at once?

Currently, `/argos-approve` operates on a single issue number at a time. It approves all pending actions for that issue, or a specific action if specified. Batch approval across multiple issues is not supported in v0.1.0.

### Q4: What if I want different tiers for different issue types?

The current policy model applies tiers uniformly to all issues in a repo. Per-label or per-category tier overrides are not supported in v0.1.0. The classification system (bug, enhancement, etc.) determines what actions are relevant, but the tier for each action is the same regardless of classification.

### Q5: Are the hard-coded deny actions truly immutable?

During onboarding, yes -- the UI always includes `close_issue`, `merge_pr`, `force_push`, and `delete_branch` in the deny list. However, since the policy is a plain YAML file, a user could manually edit it to move these actions to other tiers. This is intentionally not prevented at the code level, since the policy file is the user's explicit expression of intent.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Action executes when it should require approval | Action is in the `auto` list in the policy YAML | Check policy file; move the action to the `approve` list |
| Pending approval never expires | Approval mode is set to `wait` | Change mode to `timeout` or `default` in `approval_modes` section |
| Action is skipped with no notification | Action is in the `deny` list or not listed at all | Add the action to the `auto` or `approve` list |
| Rate limit blocks actions unexpectedly | `max_actions_per_hour` is set too low for the repo's volume | Increase `guardrails.max_actions_per_hour` in the policy |
| Approval expired but action was still executed | Mode is `default`, which auto-proceeds on expiry | Change mode to `timeout` (auto-skip) or `wait` (never expire) |
| Policy changes not taking effect | Stale policy loaded from a previous cycle | Verify the file was saved; policy is re-read every cycle |
