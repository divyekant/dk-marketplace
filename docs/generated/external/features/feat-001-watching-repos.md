---
type: feature
id: feat-001
title: Watching Repos
audience: external
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Watching Repos

## What It Does

Argos monitors GitHub repositories for new issues by polling at a configurable interval. You start watching a repo with `/watch` and stop with `/unwatch`. While watching, Argos detects new issues, classifies them, and takes action based on your policy -- all within boundaries you control.

The polling mechanism is lightweight: when no new issues exist, the check is a single `gh` CLI call with zero LLM token cost.

## How to Use It

### Start Watching

```
/watch owner/repo
```

If you have not watched this repo before, Argos runs an interactive onboarding flow that creates a policy file for the repo (see [Policy Configuration](feat-002-policy-configuration.md)). If a policy already exists, Argos loads it and performs a dry run to show you what it would do with current open issues.

After confirmation, Argos tells you to start the monitoring loop:

```
/loop 5m invoke the argos skill for owner/repo
```

The interval (`5m` in this example) comes from the `poll_interval` you set during onboarding.

### Stop Watching

```
/unwatch owner/repo
```

Argos asks whether you want to:

- **Keep the policy file** -- useful if you plan to re-watch later. Your configuration and settings are preserved.
- **Delete the policy file** -- clean removal, as if you never watched the repo.

The state file (tracking which issues have been seen) can also be preserved or removed.

**Important:** You must manually stop the `/loop` that was started for this repo. Claude Code does not yet have a `/loop stop` API, so end the loop yourself.

### Check Status

```
/argos-status
```

This shows a dashboard with:

- **Active watches** -- every repo being monitored, its poll interval, last poll time, and number of issues seen.
- **Pending approvals** -- actions waiting for your sign-off, with issue number, action type, when it was proposed, approval mode, and expiration.
- **Recent actions** -- the last 10 actions Argos took across all watched repos.
- **Guardrail status** -- current usage against limits (e.g., "Actions this hour: 3/10").

## Configuration Options

These options in your policy YAML control the watching behavior:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `repo` | string | (required) | The `owner/repo` being watched |
| `poll_interval` | string | `5m` | How often Argos checks for new issues. Accepts: `2m`, `5m`, `15m`, `30m` |
| `filters.only_new` | boolean | `true` | Only process issues opened after watching started |
| `filters.max_age` | string | `7d` | Ignore issues older than this duration |
| `filters.labels` | list | `["bug", "enhancement", "help-wanted"]` | Only act on issues with these labels (unlabeled issues always included) |
| `filters.ignore_labels` | list | `["wontfix", "on-hold", "discussion"]` | Skip issues carrying any of these labels |

## Examples

### Watch a repo with default settings

```
/watch myorg/api-server
```

Argos walks you through onboarding, creates a policy, runs a dry run, then you start the loop.

### Watch with a relaxed polling interval

During onboarding, select `15m` (Relaxed) when asked about the poll interval. This is ideal for lower-traffic repos where real-time response is not critical.

### Check what Argos is doing

```
/argos-status
```

Output:

```
Active Watches
| Repo            | Poll Interval | Last Poll | Issues Seen |
|-----------------|---------------|-----------|-------------|
| myorg/api-server| 5m            | 2 min ago | 142         |

Pending Approvals
| # | Issue                  | Action    | Proposed | Mode | Expires       |
|---|------------------------|-----------|----------|------|---------------|
| 1 | #42 "Fix auth bug"     | open_pr   | 30m ago  | wait | never (manual)|

Recent Actions (last 10)
[auto_actions] myorg/api-server#143: label -- bug
[auto_actions] myorg/api-server#143: comment_triage -- acknowledged

Guardrail Status
  Actions this hour: 3/10
  Open PRs by Argos: 1/3
```

### Stop watching

```
/unwatch myorg/api-server
```

Argos confirms and reminds you to stop the associated `/loop`.

## How It Works Under the Hood

1. **Polling** -- `lib/poll.sh` calls `gh issue list` to fetch the 50 most recent open issues for the repo.
2. **Filtering** -- Issues are filtered by the `last_issue_seen` watermark (so already-processed issues are skipped), label filters, ignore labels, and max age.
3. **State** -- `lib/state.sh` maintains a per-repo JSON file at `~/.claude/argos/state/owner-repo.json` tracking the last seen issue number, pending approvals, and rate limit counters.
4. **Zero-cost idle** -- If no new issues pass the filters, Argos exits immediately. No LLM calls, no API mutations, no cost.
