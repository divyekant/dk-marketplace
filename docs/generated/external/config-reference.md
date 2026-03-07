---
type: config-reference
audience: external
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Configuration Reference

This is a complete reference for every key in an Argos policy YAML file. Policy files are stored at `~/.claude/argos/policies/<owner>-<repo>.yaml` and control all of Argos's behavior for that repository.

## Top-Level Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `repo` | string | `""` (required) | The GitHub repository in `owner/repo` format. Must match the repo you passed to `/watch`. |
| `poll_interval` | string | `"5m"` | How often Argos checks for new issues. Accepted values: `2m` (aggressive), `5m` (recommended), `15m` (relaxed), `30m` (lazy). This value is used as the interval argument to `/loop`. |

---

## `actions`

Defines which tier each action belongs to. Every action must appear in exactly one tier. Actions not listed in any tier are implicitly denied.

### `actions.auto`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `actions.auto` | list of strings | `["label", "comment_triage", "assign", "close_duplicate"]` | Actions that execute immediately when triggered, with no human approval. |

### `actions.approve`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `actions.approve` | list of strings | `["comment_diagnosis", "create_branch", "push_commits", "open_pr"]` | Actions that are prepared and queued, but only executed after you approve them via `/argos-approve`. |

### `actions.deny`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `actions.deny` | list of strings | `["close_issue", "merge_pr", "force_push", "delete_branch"]` | Actions that are never performed. The four default values (`close_issue`, `merge_pr`, `force_push`, `delete_branch`) are hard-coded safety defaults and cannot be removed during onboarding. |

### All Available Actions

| Action Name | Description |
|-------------|-------------|
| `label` | Apply a classification label (bug, enhancement, duplicate, question, other, security-review) to the issue. Labels are validated against a whitelist. |
| `comment_triage` | Post an acknowledgment comment on the issue with the detected classification, planned next steps, and whether any actions need approval. |
| `assign` | Assign the issue to a team member based on label-to-owner mappings in the policy. Skipped if no mapping is configured. |
| `close_duplicate` | Detect duplicate issues via title similarity (>70% match). Post a comment linking to the original and close the duplicate. |
| `comment_diagnosis` | Search the local codebase for files related to the issue, analyze the code, and post a detailed root-cause analysis comment with likely cause, affected files, and suggested fix approach. |
| `create_branch` | Create a `fix/issue-N` branch from the default branch and push it to origin. |
| `push_commits` | Implement a fix using Claude Code's coding abilities. Respects `require_tests`, `max_files_changed`, and `protected_paths` guardrails. Stages files explicitly (never uses `git add -A`). |
| `open_pr` | Open a pull request linking back to the issue with a diagnosis summary and list of changes. Respects the `max_open_prs` guardrail. |
| `close_issue` | Close a non-duplicate issue. **Always denied by default.** |
| `merge_pr` | Merge a pull request. **Always denied by default.** |
| `force_push` | Force-push to a branch. **Always denied by default.** |
| `delete_branch` | Delete a branch. **Always denied by default.** |

---

## `approval_modes`

Configures how each `approve`-tier action behaves when you do not respond. Each action in the `approve` tier should have a corresponding entry here.

### Structure

```yaml
approval_modes:
  <action_name>:
    mode: <wait|timeout|default>
    timeout: <duration>    # Required for timeout and default modes
```

### Per-Action Defaults

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `approval_modes.<action>.mode` | string | `"wait"` | The approval behavior. One of: `wait` (block until approved), `timeout` (skip if no response), `default` (proceed if no response). |
| `approval_modes.<action>.timeout` | string | `"24h"` | Duration to wait before the mode's fallback behavior activates. Accepts: `30m`, `1h`, `2h`, `4h`, `24h`, `7d`, etc. Only used for `timeout` and `default` modes. Ignored for `wait`. |

### Default Approval Mode Configuration

| Action | Default Mode | Default Timeout | Behavior on Expiry |
|--------|-------------|----------------|-------------------|
| `comment_diagnosis` | `timeout` | `2h` | Skipped (no comment posted) |
| `create_branch` | `timeout` | `4h` | Skipped (no branch created) |
| `push_commits` | `wait` | -- | Blocks indefinitely |
| `open_pr` | `wait` | -- | Blocks indefinitely |

---

## `filters`

Controls which issues Argos processes. Issues that do not pass the filters are silently skipped.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `filters.labels` | list of strings | `["bug", "enhancement", "help-wanted"]` | Only process issues that have at least one of these labels. **Unlabeled issues are always included** so nothing slips through the cracks. If the list is empty, all issues are processed. |
| `filters.ignore_labels` | list of strings | `["wontfix", "on-hold", "discussion"]` | Skip any issue that has one or more of these labels. Takes priority over `filters.labels`. The defaults (`wontfix`, `on-hold`, `discussion`) are always included during onboarding. |
| `filters.only_new` | boolean | `true` | When `true`, only process issues opened after Argos started watching. Existing issues at the time of the first `/watch` are not retroactively triaged. |
| `filters.max_age` | string | `"7d"` | Ignore issues older than this duration. Accepts day units (e.g., `7d`, `14d`, `30d`). Prevents Argos from acting on stale issues. |

---

## `notifications`

Routes notifications to adapters based on event type. Each event type maps to a list of adapter names. Adapter names must match a script file in `lib/adapters/` (e.g., `github_comment` maps to `lib/adapters/github-comment.sh` -- note the underscore-to-hyphen conversion).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `notifications.auto_actions` | list of strings | `["github_comment"]` | Adapters notified when an auto-tier action is executed. |
| `notifications.approval_needed` | list of strings | `["system", "github_comment"]` | Adapters notified when an approve-tier action is queued and waiting for your review. |
| `notifications.approval_expired` | list of strings | `["system"]` | Adapters notified when a pending approval times out (either skipped or auto-proceeded, depending on the mode). |

### Built-In Adapters

| Adapter Name | Script | Description |
|-------------|--------|-------------|
| `github_comment` | `lib/adapters/github-comment.sh` | Posts a formatted comment on the GitHub issue via `gh issue comment`. |
| `system` | `lib/adapters/system.sh` | Sends a macOS Notification Center alert via `osascript`. No-op on non-macOS systems. |
| `session` | `lib/adapters/session.sh` | Appends to `~/.claude/argos/session-context.txt`, which is surfaced by the session-start hook when you open a new Claude Code session. |

---

## `guardrails`

Hard safety limits that apply regardless of action tier or approval status. These are your last line of defense against unintended behavior.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `guardrails.max_actions_per_hour` | integer | `10` | Maximum total actions (auto + approved) Argos can execute per hour for this repo. When the limit is reached, further actions are skipped and you are notified. The counter resets at the start of each UTC hour. |
| `guardrails.max_open_prs` | integer | `3` | Argos will not open a new pull request if this many Argos-authored PRs are already open on the repo. Checked via `gh pr list --author @me`. |
| `guardrails.require_tests` | boolean | `true` | When `true`, Argos will not open a PR unless the changes include modifications to test files. Enforced during the `push_commits` and `open_pr` actions. |
| `guardrails.max_files_changed` | integer | `10` | If a fix would touch more than this many files, Argos skips the issue and notifies you. Prevents overly broad automated changes. |
| `guardrails.protected_paths` | list of strings | `[".env*", "*.secret", "config/production.*"]` | Glob patterns for files that Argos must never modify. If any staged file matches a protected path, the commit is aborted and you are notified. Checked during `push_commits`. |
| `guardrails.dry_run` | boolean | `false` | When `true`, Argos logs every action it would take with full details but does not execute any GitHub-mutating commands. State is still updated (issues marked as seen). Notifications are still sent with a `[DRY RUN]` prefix. |

---

## Full Default Policy

This is the complete default policy generated by Argos when no custom values are provided:

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
    mode: timeout
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

---

## File Locations

| File | Path | Description |
|------|------|-------------|
| Policy files | `~/.claude/argos/policies/<owner>-<repo>.yaml` | Per-repo configuration |
| State files | `~/.claude/argos/state/<owner>-<repo>.json` | Runtime state (seen issues, pending approvals, rate limits) |
| Session context | `~/.claude/argos/session-context.txt` | Log of recent actions, read by the session-start hook |
| Default policy template | `<plugin-root>/config/default-policy.yaml` | Fallback when a policy file is missing or unparseable |
| Notification adapters | `<plugin-root>/lib/adapters/` | Shell scripts, one per adapter |
