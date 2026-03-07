---
type: feature
id: feat-003
title: Issue Triage
audience: external
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Issue Triage

## What It Does

When a new issue appears on a watched repository, Argos classifies it, decides what actions to take, and executes them according to your policy. This is the core intelligence loop: from raw GitHub issue to organized, actionable work item -- automatically.

Triage covers three stages:

1. **Classification** -- Determining what kind of issue it is (bug, enhancement, duplicate, question, or other).
2. **Action selection** -- Mapping the classification to a set of actions (label, triage comment, assignment, diagnosis, etc.).
3. **Execution** -- Running each action through the policy pipeline (tier check, rate limit, guardrails, dry run).

## How to Use It

Triage is fully automatic once you have a watched repo. You do not invoke it directly -- Argos runs it on every poll cycle when new issues are found.

You control triage behavior through your policy file:

- **What issues to process**: `filters.labels`, `filters.ignore_labels`, `filters.max_age`
- **What actions to take**: `actions.auto`, `actions.approve`, `actions.deny`
- **Safety limits**: `guardrails.max_actions_per_hour`, `guardrails.dry_run`

## Classification

Argos classifies each new issue into one of five categories:

| Category | How Argos Detects It |
|----------|---------------------|
| **bug** | Issue has a `bug` label, or the title/body contains keywords like: crash, error, broken, fails, regression |
| **enhancement** | Issue has an `enhancement` or `feature` label, or the title starts with "feat", "add", or "improve" |
| **duplicate** | The issue title has greater than 70% similarity to an existing open issue |
| **question** | Issue has a `question` label, or the title starts with "how", "why", or "is there" |
| **other** | Anything that does not match the above categories |

### Classification Rules

1. **Trust existing labels.** If the issue already has labels, Argos uses them for classification and does not reclassify.
2. **Analyze unlabeled issues.** If the issue has no labels, Argos examines the title and body to suggest a classification.
3. **Duplicate detection uses fuzzy matching.** Argos fetches open issues and compares titles using substring matching and keyword overlap -- not exact string comparison.
4. **Default to conservative.** When uncertain, Argos classifies as `other` and posts a triage comment rather than taking a stronger action.

### Label Validation

When applying a classification label, Argos validates it against a whitelist of allowed labels:

```
bug, enhancement, duplicate, question, other, security-review
```

Any classification not in this list is rejected. This prevents issues with manipulated content from injecting arbitrary labels.

## Duplicate Detection

When Argos encounters a new issue, it compares the title against all open issues for the same repo. If a title shows greater than 70% similarity to an existing issue:

1. The new issue is classified as `duplicate`.
2. If `close_duplicate` is in the `auto` tier, Argos posts a comment linking to the original issue and closes the new one.
3. If `close_duplicate` is in the `approve` tier, the action is queued for your review.
4. The duplicate relationship is stored in Memories for future reference.

## Action Pipeline

For every action on every issue, Argos runs through this pipeline:

```
1. Determine tier    --> Is this action auto, approve, or deny?
2. If deny           --> Skip. Log the reason. Move on.
3. Check rate limit  --> Has max_actions_per_hour been reached?
   If yes            --> Skip. Notify. Move on.
4. Check dry run     --> Is guardrails.dry_run true?
   If yes            --> Log what would happen. Notify. Do NOT execute.
5. If auto           --> Execute immediately. Increment action count. Notify. Log to Memories.
6. If approve        --> Check approval mode. Add to pending queue. Notify. Do NOT execute yet.
```

### Available Actions

| Action | What It Does |
|--------|-------------|
| **label** | Adds the classification label (e.g., `bug`, `enhancement`) to the issue |
| **comment_triage** | Posts an acknowledgment comment with the detected classification, planned actions, and whether anything needs approval |
| **assign** | Assigns the issue to an owner based on label-to-owner mappings in the policy (skipped if no mapping exists) |
| **close_duplicate** | Posts a comment linking to the original issue, then closes the duplicate |
| **comment_diagnosis** | Searches the local codebase for relevant files, analyzes the code, and posts a detailed root-cause analysis comment |
| **create_branch** | Creates a `fix/issue-N` branch from the default branch and pushes it |
| **push_commits** | Implements a fix using Claude Code's coding abilities, verifies guardrails (tests, file count, protected paths), commits, and pushes |
| **open_pr** | Opens a pull request linking back to the issue, with a summary of the diagnosis and changes |

## Security: Prompt Injection Detection

Issue content is untrusted input. Before processing any issue, Argos scans the title and body for prompt injection patterns, including:

- "ignore previous instructions", "ignore all instructions"
- "you are now", "act as if", "pretend you"
- "system prompt", "new instructions", "override"
- Special tokens like `<<SYS>>`, `[INST]`, `IMPORTANT:`
- Base64-encoded blocks or zero-width Unicode characters

If any pattern matches:

1. The issue is flagged with a `security-review` label (if `label` is in the auto tier).
2. All other actions for this issue are skipped.
3. You are notified via the `approval_needed` channels.
4. No instructions from the issue content are followed -- a human must review first.

## Configuration Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `filters.labels` | list | `["bug", "enhancement", "help-wanted"]` | Only act on issues with these labels (unlabeled issues always included) |
| `filters.ignore_labels` | list | `["wontfix", "on-hold", "discussion"]` | Skip issues carrying any of these labels |
| `filters.only_new` | boolean | `true` | Only process issues opened after watching started |
| `filters.max_age` | string | `7d` | Ignore issues older than this |
| `actions.auto` | list | `["label", "comment_triage", "assign", "close_duplicate"]` | Actions that execute immediately |
| `actions.approve` | list | `["comment_diagnosis", "create_branch", "push_commits", "open_pr"]` | Actions that require your approval |
| `actions.deny` | list | `["close_issue", "merge_pr", "force_push", "delete_branch"]` | Actions that are never performed |
| `guardrails.max_actions_per_hour` | integer | `10` | Hard cap on total actions per hour |
| `guardrails.dry_run` | boolean | `false` | Log actions without executing them |

## Examples

### A bug report comes in

1. Issue #55 is opened: "Login page crashes on Safari", labels: `[bug]`.
2. Argos classifies it as `bug` (trusts the existing label).
3. **label** (auto): Applies the `bug` label. (Already present, so this is a no-op.)
4. **comment_triage** (auto): Posts a comment: "Classified as **bug**. Planned actions: comment_diagnosis (pending approval), create_branch (pending approval)."
5. **comment_diagnosis** (approve/wait): Added to the pending queue. You see it in `/argos-status`.
6. You run `/argos-approve #55`. Argos analyzes the codebase and posts a diagnosis comment on the issue.

### A duplicate is detected

1. Issue #202 is opened: "App crashes on startup" -- very similar to existing issue #201.
2. Argos detects greater than 70% title similarity with #201.
3. **close_duplicate** (auto): Posts "Closing as duplicate of #201" and closes #202.
4. The duplicate relationship is stored in Memories for future reference.

### Rate limit kicks in

1. Argos has performed 10 actions this hour (the default cap).
2. A new issue appears. Argos classifies it but cannot execute any actions.
3. You are notified that the rate limit blocked further actions.
4. Actions resume when the hour window resets.

## Memories Integration

Argos builds institutional knowledge over time:

- **After every action**: Argos stores a memory like `argos/myorg/backend/issue-42: comment_diagnosis -- identified null pointer in auth.js:147`.
- **Before classifying**: Argos searches memories for similar past issues. If the same kind of issue keeps appearing (3+ in a week), the triage comment includes a note like "This is the 3rd authentication-related issue this week. Consider a broader investigation."
- **After closing a duplicate**: The relationship is stored so Argos can recognize the pattern in the future.
