---
id: faq-001
type: faq
audience: internal
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Argos FAQ

## Setup & Getting Started

### Q1: What do I need to install before using Argos?

Argos requires four external dependencies:
- **`gh` CLI** -- GitHub's official CLI, authenticated (`gh auth login`).
- **`jq`** -- JSON processor for parsing API responses.
- **`python3`** -- Used by the policy loader to convert YAML to JSON.
- **`pyyaml`** -- Python YAML library (`pip3 install pyyaml`).

Additionally, Argos expects the **Memories MCP** server to be available for cross-session learning. The `/watch` command checks these prerequisites automatically.

### Q2: How do I start watching a repository?

Run `/watch owner/repo` in a Claude Code session. If no policy exists for that repo, Argos guides you through a 9-step onboarding flow to create one. Once the policy is confirmed, Argos runs a dry run showing what it would do with current open issues. After confirmation, start the polling loop with:
```
/loop 5m invoke the argos skill for owner/repo
```

### Q3: Where does Argos store its data?

All data lives under `~/.claude/argos/`:
- `policies/<owner>-<repo>.yaml` -- per-repo policy configuration.
- `state/<owner>-<repo>.json` -- runtime state (watermarks, pending approvals, action counts).
- `session-context.txt` -- ephemeral log of recent actions, read by the session-start hook.

## Policy Configuration

### Q4: How do I change which actions require approval after initial setup?

Edit the policy YAML at `~/.claude/argos/policies/<owner>-<repo>.yaml`. Move actions between the `auto`, `approve`, and `deny` lists under the `actions` key. Changes take effect on the next poll cycle -- no restart needed (though the `/loop` continues on its existing interval).

### Q5: What is the difference between the three approval modes?

| Mode | On timeout | Use when... |
|------|-----------|-------------|
| `wait` | Nothing happens; stays pending forever | You always want to review before execution (safest) |
| `timeout` | Action is **skipped** (not executed) | Inaction is safer than action (e.g., advisory comments) |
| `default` | Action **proceeds automatically** | You usually approve and want to opt out rather than opt in |

### Q6: Can I use different tiers for different types of issues (e.g., auto-label bugs but approve-label enhancements)?

Not in v0.1.0. Tiers are defined per action, not per issue category. The `label` action is either auto, approve, or deny for all issues on a given repo. Per-category tier overrides are a planned future feature.

### Q7: What are the hard-coded deny actions and can I change them?

During onboarding, `close_issue`, `merge_pr`, `force_push`, and `delete_branch` are always placed in the deny tier. These represent high-risk destructive operations. The onboarding UI does not allow moving them. However, since the policy is a plain YAML file, a user can manually edit it to override this. The code does not enforce the deny list at runtime -- the policy file is the source of truth.

## Approval Workflow

### Q8: How do I approve a pending action?

Run `/argos-approve #42` where `42` is the issue number. Argos finds the pending approval across all watched repos, shows you what will be executed, and runs the action. To reject instead, run `/argos-approve #42 reject`.

### Q9: What happens if I do not respond to a pending approval?

It depends on the approval mode configured for that action:
- **`wait`** mode: the approval stays pending indefinitely until you approve or reject.
- **`timeout`** mode: after the timeout (e.g., `2h`), the action is skipped automatically.
- **`default`** mode: after the timeout (e.g., `4h`), the action proceeds automatically.

Expired approvals are processed by the `session-start.sh` hook when a new CC session starts.

### Q10: Can I approve all pending actions at once?

Not in v0.1.0. `/argos-approve` operates on one issue number at a time. Batch approval is not supported. Run `/argos-status` to see all pending items and approve each one individually.

## Rate Limits & Guardrails

### Q11: What happens when Argos hits the rate limit?

When `actions_this_hour` reaches `max_actions_per_hour` (default 10), further actions are skipped for the remainder of the current UTC clock hour. A notification is sent, and the blocked action is logged. Processing continues to the next issue -- the rate limit does not crash the loop or stop polling.

### Q12: Does the rate limit reset on a rolling window?

No. The counter resets at the start of each UTC clock hour (e.g., 14:00, 15:00). It is not a rolling 60-minute window. An attacker or high-velocity repo could theoretically get up to `2 * max_actions_per_hour` actions within a 60-minute span that crosses an hour boundary.

### Q13: What does `max_open_prs` actually block?

It blocks the `open_pr` action only. If Argos already has 3 (default) open PRs authored by `@me` on a repo, it will not create new PRs. Other actions (labeling, commenting, branching) are not affected. The check uses `gh pr list --author "@me" --state open`.

## Security

### Q14: What if a legitimate issue triggers the prompt injection detector?

The issue is flagged with a `security-review` label and all actions are skipped. A human must review the issue. To proceed, remove the `security-review` label manually. Note that Argos will not reprocess the issue automatically because the watermark has already advanced past it. If you want Argos to act on it, triage it manually or lower `last_issue_seen` in the state file.

### Q15: Can Argos accidentally commit secrets?

Multiple safeguards prevent this:
1. `guardrails.protected_paths` blocks files matching patterns like `.env*`, `*.secret`, `config/production.*`.
2. Argos never uses `git add -A`. Only specific files are staged.
3. Every staged file is checked against `is_path_protected` before commit; matching files are unstaged.

If a file matches a protected path pattern, the commit proceeds without that file, and a warning is logged.

### Q16: Does dry run mode use any LLM tokens?

Yes. Dry run prevents GitHub-mutating actions (no `gh issue edit`, no `gh issue comment`, no `git push`, no `gh pr create`), but the classification pipeline still runs, which consumes LLM tokens. State is updated, memories are stored, and notifications are sent (with a `[DRY RUN]` prefix).

## Troubleshooting

### Q17: Argos is not detecting any new issues. What should I check?

1. Verify `gh auth status` shows a valid login.
2. Verify the repo name is correct: `gh repo view owner/repo`.
3. Check the policy's `filters.labels` -- if the filter labels do not match any labels on open issues, they are filtered out (unlabeled issues still pass through).
4. Check `last_issue_seen` in the state file. If it is set to a high number, all existing issues are considered "already seen."
5. Verify the `/loop` is actually running.

### Q18: How do I completely reset Argos for a repo?

1. Stop the `/loop`.
2. Delete the state file: `rm ~/.claude/argos/state/<owner>-<repo>.json`
3. Optionally delete the policy: `rm ~/.claude/argos/policies/<owner>-<repo>.yaml`
4. Re-run `/watch owner/repo` to start fresh.
