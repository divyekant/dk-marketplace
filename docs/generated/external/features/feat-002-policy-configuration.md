---
type: feature
id: feat-002
title: Policy Configuration
audience: external
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Policy Configuration

## What It Does

The policy file is the heart of Argos. It defines exactly what Argos can and cannot do for a given repository. Every action flows through the policy; every decision respects its boundaries.

Each watched repo has its own policy file stored at `~/.claude/argos/policies/<owner>-<repo>.yaml`. You can create a policy through the guided onboarding flow (via `/watch`) or write one by hand.

## How to Use It

### Guided Setup (Recommended)

Run `/watch owner/repo` on a repo that does not have a policy yet. Argos walks you through seven steps, one question at a time:

1. **Issue types** -- Which labels should Argos watch for?
2. **Auto actions** -- What can Argos do without asking?
3. **Approve actions** -- What should Argos propose and wait for your sign-off?
4. **Approval modes** -- How should each approval behave (wait forever, timeout and skip, or timeout and proceed)?
5. **Poll interval** -- How often to check for new issues?
6. **Notification channels** -- How should Argos notify you?
7. **Guardrails** -- Safety limits to prevent runaway behavior.

After you answer, Argos generates the YAML and shows it for your review. You can adjust any section before confirming.

### Manual Setup

Create a YAML file at `~/.claude/argos/policies/<owner>-<repo>.yaml`. Use the default policy as a starting point (see the [Config Reference](../config-reference.md) for every key).

### Editing an Existing Policy

Open the file directly and edit it:

```bash
nano ~/.claude/argos/policies/myorg-backend.yaml
```

Changes take effect on the next poll cycle -- no restart required.

## Configuration Options

### Action Tiers

Every action belongs to exactly one tier:

| Tier | Behavior |
|------|----------|
| **auto** | Execute immediately when triggered. No human in the loop. |
| **approve** | Prepare the action, notify you, and wait for approval via `/argos-approve`. |
| **deny** | Never perform this action, regardless of context. |

Actions not listed in any tier are implicitly denied.

#### Available Actions

| Action | Description | Recommended Tier |
|--------|-------------|-----------------|
| `label` | Apply a classification label to the issue | auto |
| `comment_triage` | Post an acknowledgment comment with classification and next steps | auto |
| `assign` | Assign the issue to a team member based on label-to-owner mapping | auto |
| `close_duplicate` | Detect and close duplicate issues with a link to the original | auto |
| `comment_diagnosis` | Post a root-cause analysis comment after investigating the codebase | approve |
| `create_branch` | Create a fix branch from the default branch | approve |
| `push_commits` | Write and push code changes to the fix branch | approve |
| `open_pr` | Open a pull request linking back to the issue | approve |

#### Hard-Denied Actions (Not Configurable)

These actions are always in the `deny` tier. You cannot move them to `auto` or `approve` during onboarding:

- `close_issue` -- Closing non-duplicate issues
- `merge_pr` -- Merging pull requests
- `force_push` -- Force-pushing to branches
- `delete_branch` -- Deleting branches

### Approval Modes

For each action in the `approve` tier, you choose a mode that controls what happens if you do not respond:

| Mode | Behavior | Best For |
|------|----------|----------|
| **wait** | Blocks indefinitely. The action only executes when you explicitly approve it via `/argos-approve`. | High-risk actions: `push_commits`, `open_pr` |
| **timeout** | If you do not respond within the timeout window, the action is **skipped** (not executed). | Advisory actions you want to review but are OK missing: `comment_diagnosis` |
| **default** | If you do not respond within the timeout window, the action **proceeds automatically**. | Low-risk actions you almost always approve: `create_branch` |

Default timeout values:

| Action | Default Mode | Default Timeout |
|--------|-------------|----------------|
| `comment_diagnosis` | timeout | 2h |
| `create_branch` | timeout | 4h |
| `push_commits` | wait | -- |
| `open_pr` | wait | -- |

### Guardrails

Guardrails are hard limits that apply regardless of action tier or approval status. They are your safety net.

| Guardrail | Default | Description |
|-----------|---------|-------------|
| `max_actions_per_hour` | 10 | Total actions (auto + approved) allowed per hour per repo |
| `max_open_prs` | 3 | Argos will not open new PRs if this many Argos-created PRs are already open |
| `require_tests` | true | Argos will not open a PR unless the changes include test modifications |
| `max_files_changed` | 10 | Skip issues whose fix would touch more than this many files |
| `protected_paths` | `.env*`, `*.secret`, `config/production.*` | Argos will never modify files matching these glob patterns |
| `dry_run` | false | When true, Argos logs what it would do but takes no mutating action |

### Dry Run Mode

Setting `guardrails.dry_run: true` is the safest way to test a policy. In dry run mode:

- Every action that **would** be taken is logged with full details.
- No GitHub-mutating commands are executed (no comments, no labels, no branches, no PRs).
- State is still updated (issues are marked as seen so they are not reprocessed).
- Notifications are still sent so you can review the plan.
- All notification details are prefixed with `[DRY RUN]`.

## Examples

### Conservative policy (approval required for everything)

```yaml
repo: myorg/backend
poll_interval: 5m

actions:
  auto:
    - label
  approve:
    - comment_triage
    - comment_diagnosis
    - assign
    - close_duplicate
    - create_branch
    - push_commits
    - open_pr
  deny:
    - close_issue
    - merge_pr
    - force_push
    - delete_branch

approval_modes:
  comment_triage:
    mode: default
    timeout: 1h
  comment_diagnosis:
    mode: wait
  assign:
    mode: default
    timeout: 2h
  close_duplicate:
    mode: wait
  create_branch:
    mode: wait
  push_commits:
    mode: wait
  open_pr:
    mode: wait
```

### Hands-off policy (maximize automation)

```yaml
repo: myorg/docs
poll_interval: 15m

actions:
  auto:
    - label
    - comment_triage
    - assign
    - close_duplicate
    - comment_diagnosis
    - create_branch
  approve:
    - push_commits
    - open_pr
  deny:
    - close_issue
    - merge_pr
    - force_push
    - delete_branch

approval_modes:
  push_commits:
    mode: default
    timeout: 4h
  open_pr:
    mode: default
    timeout: 4h

guardrails:
  max_actions_per_hour: 20
  max_open_prs: 5
  require_tests: false
  max_files_changed: 20
  dry_run: false
```

### Test a policy before going live

```yaml
guardrails:
  dry_run: true
```

Set `dry_run: true`, start the loop, and watch the notifications. When you are satisfied with the behavior, set it back to `false`.
