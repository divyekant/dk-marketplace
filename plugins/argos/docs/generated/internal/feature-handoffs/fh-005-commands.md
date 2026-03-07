---
id: fh-005
type: feature-handoff
audience: internal
topic: Commands
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Feature Handoff: Commands

## What It Does

Argos exposes four slash commands within Claude Code that serve as the primary user interface. `/watch` starts monitoring a repo and guides the user through policy creation. `/unwatch` stops monitoring. `/argos-status` displays the current state of all watches. `/argos-approve` lets the user approve or reject pending actions. These commands are defined as Markdown files in the `commands/` directory, which CC loads as plugin commands.

## How It Works

### `/watch owner/repo`

**Purpose:** Start watching a GitHub repository for new issues.

**Flow:**
1. Parse the `owner/repo` argument from `$ARGUMENTS`.
2. Run prerequisite checks:
   - `gh auth status` -- verify GitHub CLI authentication
   - `jq --version` -- verify jq is installed
   - `gh repo view "$REPO"` -- verify the repo exists and is accessible
3. Check for an existing policy file at `~/.claude/argos/policies/<owner>-<repo>.yaml`.
4. **If no policy exists** -- run the onboarding flow (see below).
5. **If policy exists** -- proceed directly to the dry run.
6. **Dry run** -- fetch current open issues, evaluate each against the policy, and display a table showing what Argos would do (auto actions, approve actions, tier).
7. **Start watching** -- create the state directory, tell the user to run `/loop [interval] invoke the argos skill for [owner/repo]`.

**Onboarding Flow (9 steps):**

The onboarding is a guided, conversational policy creation process. One question at a time, with checkbox-style options and clearly marked defaults:

| Step | What It Asks | Default |
|------|-------------|---------|
| 1 | Issue types (filter labels) | `["bug", "enhancement"]` |
| 2 | Auto actions | `["label", "comment_triage", "close_duplicate"]` |
| 3 | Approve actions | `["comment_diagnosis", "create_branch", "push_commits", "open_pr"]` |
| 4 | Approval modes per approve-action | See table in watch.md |
| 5 | Poll interval | `5m` |
| 6 | Notification channels | `["github_comment", "system"]` |
| 7 | Guardrails (with adjustment option) | Conservative defaults |
| 8 | Generate and display policy YAML | -- |
| 9 | Confirm or iterate | -- |

The deny list (`close_issue`, `merge_pr`, `force_push`, `delete_branch`) is always included and cannot be removed during onboarding. Similarly, `ignore_labels` always includes `wontfix`, `on-hold`, `discussion`.

**Allowed tools:** `Bash(${CLAUDE_PLUGIN_ROOT}/lib/*:*)` and `Skill`.

### `/unwatch owner/repo`

**Purpose:** Stop watching a repository.

**Flow:**
1. Parse the `owner/repo` argument.
2. Identify the state file at `~/.claude/argos/state/<owner>-<repo>.json`.
3. Ask the user whether to preserve or delete the state history.
4. Inform the user to stop the `/loop` manually (CC does not have a `/loop stop` API).
5. Optionally ask whether to keep or remove the policy file.
6. Confirm: "Argos has stopped watching `owner/repo`."

**Allowed tools:** `Bash`.

### `/argos-status`

**Purpose:** Show a comprehensive status of all Argos watches.

**Flow:**
1. List all policy files in `~/.claude/argos/policies/*.yaml` to enumerate watched repos.
2. For each repo, read the state file to get: last poll time, last issue seen, pending approvals, actions this hour.
3. Read the session context log (`~/.claude/argos/session-context.txt`) for recent activity.
4. Display three sections:
   - **Active Watches** table: repo, poll interval, last poll, issues seen.
   - **Pending Approvals** table: issue number, action, proposed time, mode, expiry.
   - **Recent Actions** list (last 10 from session context).
   - **Guardrail Status**: actions this hour vs. max, open PRs vs. max.

**Allowed tools:** `Bash`.

### `/argos-approve #N [reject]`

**Purpose:** Approve or reject a pending action.

**Flow:**
1. Parse the issue number and optional `reject` keyword from `$ARGUMENTS`.
2. Search across all state files for a pending approval matching the issue number.
3. **If not found:** report "No pending approval found for issue #N."
4. **If approving:**
   - Show the user what will be executed: action, repo, issue, summary.
   - Source the relevant lib scripts and execute the action.
   - Remove from pending approvals via `remove_pending_approval`.
   - Send notifications via configured channels.
   - Store the action in Memories MCP.
5. **If rejecting:**
   - Confirm the rejection.
   - Remove from pending approvals.
   - Optionally post a GitHub comment noting the rejection.
   - Store the rejection in Memories MCP (for learning what gets rejected).

**Allowed tools:** `Bash(${CLAUDE_PLUGIN_ROOT}/lib/*:*)`.

## Configuration

Commands themselves are not configurable -- they are fixed behaviors. The data they operate on comes from:

| Data Source | Path | Content |
|-------------|------|---------|
| Policy files | `~/.claude/argos/policies/<owner>-<repo>.yaml` | Per-repo boundary configuration |
| State files | `~/.claude/argos/state/<owner>-<repo>.json` | Runtime state (watermarks, pending approvals) |
| Session context | `~/.claude/argos/session-context.txt` | Recent action log for `/argos-status` |

**Files involved:**
- `/Users/divyekant/Projects/argos/commands/watch.md`
- `/Users/divyekant/Projects/argos/commands/unwatch.md`
- `/Users/divyekant/Projects/argos/commands/argos-status.md`
- `/Users/divyekant/Projects/argos/commands/argos-approve.md`

## Edge Cases

1. **`/watch` called for a repo that is already being watched.** If a policy file already exists, onboarding is skipped and the dry run runs directly. The user is not warned about an existing watch -- this allows re-running `/watch` to see a fresh dry run.

2. **`/unwatch` called for a repo that is not being watched.** The command will find no state file and no policy file. It should handle this gracefully by reporting that the repo is not currently watched.

3. **`/argos-approve` with no pending approvals.** The search across state files finds nothing. The command reports "No pending approval found" and suggests running `/argos-status`.

4. **`/argos-status` with no watched repos.** No policy files exist in the policies directory. The command should report "No repos are currently being watched" rather than displaying empty tables.

5. **`/loop stop` not available.** CC does not currently provide a programmatic way to stop a `/loop`. The `/unwatch` command tells the user to stop the loop manually. This is a known limitation of v0.1.0.

## Common Questions

### Q1: Do I need to run `/watch` again after restarting Claude Code?

No. The policy file persists across sessions. However, you do need to restart the `/loop` command that drives Argos, since `/loop` does not survive CC session restarts. The `session-start.sh` hook will remind you about pending approvals.

### Q2: Can I watch multiple repos simultaneously?

Yes. Run `/watch` for each repo. Each gets its own policy file and state file. Multiple `/loop` instances can run concurrently. `/argos-status` displays all watches.

### Q3: What if I want to change my policy after onboarding?

Edit the YAML file directly at `~/.claude/argos/policies/<owner>-<repo>.yaml`. Changes take effect on the next poll cycle. Alternatively, you can delete the policy file and re-run `/watch` to go through onboarding again.

### Q4: Can `/argos-approve` approve actions for a specific repo only?

`/argos-approve` takes an issue number, not a repo. It searches across all state files. If the same issue number exists in multiple repos (unlikely but possible), it takes the first match. In v0.1.0, there is no repo-scoping parameter.

### Q5: What does the dry run in `/watch` actually show?

It fetches current open issues from the repo, applies the policy's label and ignore filters, and for each matching issue, displays a table showing: the issue number and title, which actions would be auto-executed, which would require approval, and the highest tier. No actions are taken during the dry run.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| `/watch` says `gh` is not authenticated | GitHub CLI token expired or not configured | Run `gh auth login` |
| Onboarding does not start | Policy file already exists for this repo | Delete `~/.claude/argos/policies/<owner>-<repo>.yaml` and re-run `/watch` |
| `/argos-status` shows stale "last poll" time | The `/loop` stopped or was never started | Re-run `/loop [interval] invoke the argos skill for [owner/repo]` |
| `/argos-approve` cannot find a pending approval | Issue was already approved, rejected, or timed out | Run `/argos-status` to see current pending approvals |
| `/unwatch` does not stop polling | `/loop` must be stopped manually | Stop the active `/loop` in the CC session |
| Dry run table is empty | No open issues match the policy filters | Adjust filter labels or max_age in the policy |
