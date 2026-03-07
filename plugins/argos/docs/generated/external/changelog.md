---
type: changelog
audience: external
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Changelog

All notable user-facing changes to Argos are documented here.

---

## v0.1.0 -- 2026-03-06

The initial release of Argos, the All-Seeing Issue Guardian.

### New Features

- **Repository watching** -- Use `/watch owner/repo` to start monitoring a GitHub repository for new issues. Argos polls at a configurable interval (2m, 5m, 15m, or 30m) and acts on new issues based on your policy.

- **Guided onboarding** -- The first time you watch a repo, Argos walks you through an interactive setup: choose which issue types to watch, which actions to automate, how approvals work, poll interval, notification preferences, and safety guardrails. The result is a policy YAML file saved to `~/.claude/argos/policies/`.

- **Tiered autonomy** -- Every action belongs to one of three tiers:
  - **auto** -- Executes immediately (labeling, triage comments, closing duplicates).
  - **approve** -- Queued for your review via `/argos-approve` (diagnosis comments, branches, code changes, pull requests).
  - **deny** -- Never performed (closing issues, merging PRs, force-pushing, deleting branches).

- **Per-action approval modes** -- For actions in the `approve` tier, choose how timeouts work:
  - **wait** -- Blocks until you explicitly approve.
  - **timeout** -- Skips the action if you do not respond in time.
  - **default** -- Proceeds automatically if you do not respond in time.

- **Issue classification** -- Argos classifies new issues as bug, enhancement, duplicate, question, or other based on labels, title keywords, and body content.

- **Duplicate detection** -- Detects duplicate issues by comparing titles against open issues using fuzzy matching (>70% similarity). Duplicates can be automatically closed with a link to the original.

- **Pluggable notifications** -- Three built-in notification adapters:
  - **github_comment** -- Posts action summaries directly on the issue.
  - **system** -- Sends macOS Notification Center alerts.
  - **session** -- Injects activity summaries into your next Claude Code session.

- **Session-start hook** -- When you open a new Claude Code session, Argos tells you about pending approvals and actions taken while you were away.

- **Commands**:
  - `/watch owner/repo` -- Start watching a repo (with onboarding if needed).
  - `/unwatch owner/repo` -- Stop watching a repo.
  - `/argos-status` -- Dashboard showing active watches, pending approvals, recent actions, and guardrail usage.
  - `/argos-approve #N` -- Approve (or reject) a pending action.

- **Safety guardrails** -- Hard limits to prevent runaway behavior:
  - Rate limiting (max actions per hour).
  - Max open PRs cap.
  - Require tests in PRs.
  - Max files changed per fix.
  - Protected file paths (never touch `.env`, secrets, or production configs).
  - Dry run mode for testing policies without side effects.

- **Memories integration** -- Argos stores action outcomes, duplicate relationships, and codebase patterns via Memories MCP. Over time, it recognizes repeat issues, learns which files are hotspots, and improves triage accuracy.

- **Dry run mode** -- Set `guardrails.dry_run: true` to see exactly what Argos would do without it taking any action. Notifications are still sent with a `[DRY RUN]` prefix.

### Security

- Issue content (titles and bodies) is treated as untrusted input throughout the system.
- Prompt injection detection scans for 12+ known patterns before processing any issue.
- Label classification is validated against a whitelist to prevent injection of arbitrary labels.
- Commit messages and PR titles are sanitized before shell interpolation.
- GitHub comment adapter uses `--body-file` piping to prevent shell expansion of untrusted content.
- Notification adapter names are validated against a strict regex to prevent path traversal.
- Session context file sanitizes details before writing to prevent stored prompt injection.
- Protected paths guardrail blocks commits that touch sensitive files.
- Explicit file staging replaces `git add -A` to avoid accidentally committing secrets.
