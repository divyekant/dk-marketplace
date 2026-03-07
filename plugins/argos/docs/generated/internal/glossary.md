---
id: glossary-001
type: glossary
audience: internal
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Argos Glossary

**Action**
A discrete operation Argos can perform on a GitHub issue. Defined actions include: `label`, `comment_triage`, `assign`, `close_duplicate`, `comment_diagnosis`, `create_branch`, `push_commits`, and `open_pr`. Each action is assigned to a tier in the policy.

**Adapter**
A pluggable shell script in `lib/adapters/` that handles notification delivery for a specific channel. Built-in adapters: `github-comment`, `system`, `session`. Adapters receive a JSON payload on stdin and perform their channel-specific notification.

**Approval Mode**
The behavior applied to a pending approval when the user does not respond within the timeout window. Three modes exist: `wait` (block indefinitely), `timeout` (auto-skip), and `default` (auto-proceed).

**Auto Tier**
The policy tier for actions that execute immediately without human approval. Auto-tier actions fire as soon as they are determined by the triage pipeline and pass guardrail checks.

**Approve Tier**
The policy tier for actions that are proposed and queued but not executed until a human explicitly approves them via `/argos-approve`.

**Classification**
The category assigned to an issue during triage. One of: `bug`, `enhancement`, `duplicate`, `question`, or `other`. Determined by existing labels or heuristic analysis of the issue title and body.

**Deny Tier**
The policy tier for actions that are permanently blocked. Denied actions are never executed, regardless of context. Actions not listed in any tier are implicitly denied.

**Dry Run**
A mode controlled by `guardrails.dry_run` (default `false`) where Argos logs what it would do but performs no GitHub-mutating operations. Notifications are sent with a `[DRY RUN]` prefix. State and memories are still updated.

**Filter Labels**
The list of GitHub issue labels Argos watches for, defined in `filters.labels` in the policy YAML. Issues carrying at least one of these labels (or no labels at all) pass the filter.

**Guardrail**
A hard safety limit that applies regardless of tier or approval. Guardrails include `max_actions_per_hour`, `max_open_prs`, `require_tests`, `max_files_changed`, `protected_paths`, and `dry_run`.

**Ignore Labels**
The list of GitHub issue labels that cause an issue to be skipped entirely, defined in `filters.ignore_labels`. Default: `["wontfix", "on-hold", "discussion"]`.

**Injection Detection**
The security scanner that checks issue titles and bodies for prompt injection patterns before classification. Matched patterns cause the issue to be flagged with `security-review` and all actions to be skipped.

**Loop**
The Claude Code `/loop` command that drives Argos's polling schedule. Invoked as `/loop [interval] invoke the argos skill for [owner/repo]`. Runs until manually stopped.

**Memories MCP**
The Memories MCP server used for persistent, cross-session storage of action outcomes, error logs, duplicate records, and pattern data. Entries are prefixed with `argos/<owner>/<repo>/`.

**Onboarding Flow**
The guided, 9-step policy creation process triggered by `/watch` when no policy exists for the target repo. Walks the user through filter labels, action tiers, approval modes, poll interval, notification channels, and guardrails.

**Pending Approval**
An action in the `approve` tier that has been proposed but not yet executed. Stored in the repo's state file under `pending_approvals`. Each entry records the issue number, action, proposed timestamp, approval mode, and summary.

**Policy File**
A YAML configuration file at `~/.claude/argos/policies/<owner>-<repo>.yaml` that defines all boundaries for a watched repo: action tiers, approval modes, filters, notifications, and guardrails.

**Poll Interval**
How frequently `/loop` invokes the Argos skill, defined in the policy as `poll_interval`. Default: `5m`. Options presented during onboarding: `2m` (aggressive), `5m` (recommended), `15m` (relaxed), `30m` (lazy).

**Protected Paths**
Glob patterns in `guardrails.protected_paths` that identify files Argos must never modify or commit. Default patterns: `.env*`, `*.secret`, `config/production.*`.

**Rate Limit**
The `guardrails.max_actions_per_hour` cap on total actions (auto + approved) per UTC clock hour per repo. When reached, further actions are skipped until the next hour.

**Session Context**
A text file at `~/.claude/argos/session-context.txt` where the `session` adapter appends action summaries. Read and cleared by the `session-start.sh` hook at CC session startup.

**Session-Start Hook**
The `hooks/session-start.sh` script triggered by CC's SessionStart event. Summarizes pending approvals, processes expired timeouts, and injects an `additional_context` JSON message into the session.

**SKILL.md**
The Argos skill definition at `skills/argos/SKILL.md`. Contains the complete agent instructions: workflow steps, classification rules, action definitions, security rules, error handling, and Memories integration.

**State File**
A JSON file at `~/.claude/argos/state/<owner>-<repo>.json` that tracks per-repo runtime state: `last_poll`, `last_issue_seen` (watermark), `pending_approvals`, `actions_this_hour`, and `actions_hour_start`.

**Tier**
One of the three permission levels in the Argos policy: `auto` (immediate execution), `approve` (requires human sign-off), or `deny` (permanently blocked). Every action is assigned to exactly one tier.

**Triage**
The process of classifying a new issue and determining which actions to take based on the classification and policy tiers.

**Watermark**
The `last_issue_seen` value in the state file. Issues with a number at or below the watermark are considered already processed and are filtered out by `filter_new_issues`.
