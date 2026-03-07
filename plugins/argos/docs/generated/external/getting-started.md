---
type: getting-started
audience: external
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Getting Started with Argos

Argos is a Claude Code plugin that watches your GitHub repositories for new issues and acts on them automatically -- labeling, triaging, detecting duplicates, diagnosing bugs, and even opening pull requests -- all within boundaries you define.

## Prerequisites

Before you begin, make sure you have the following installed and configured:

- **Claude Code** with `/loop` support
- **GitHub CLI** (`gh`) -- authenticated via `gh auth login`
- **jq** -- JSON processor (`brew install jq` or equivalent)
- **python3** with **PyYAML** -- `pip3 install pyyaml`
- **Memories MCP** -- configured in your Claude Code environment for cross-session learning

## Step 1: Install the Plugin

Clone or copy the Argos plugin into your Claude Code plugins directory:

```bash
# From your Claude Code plugins location
git clone <argos-repo-url> argos
```

Claude Code will detect the plugin automatically via the `.claude-plugin/plugin.json` manifest.

## Step 2: Start Watching a Repo

In a Claude Code session, run:

```
/watch owner/repo
```

Replace `owner/repo` with your actual GitHub repository (e.g., `myorg/backend`).

If this is your first time watching this repo, Argos walks you through an interactive onboarding flow. It asks you about:

1. Which issue types to watch (bug, enhancement, etc.)
2. Which actions to run automatically vs. which need your approval
3. How approval timeouts should work
4. How often to poll for new issues
5. How to notify you about actions taken

At the end, Argos generates a policy YAML file and saves it to `~/.claude/argos/policies/owner-repo.yaml`.

## Step 3: Confirm with a Dry Run

Before going live, Argos fetches your repo's current open issues and shows you a table of what it **would** do -- without actually doing anything:

```
| Issue # | Title                  | Auto Actions          | Approve Actions                    |
|---------|------------------------|-----------------------|------------------------------------|
| #42     | Login crash on iOS 18  | label, comment_triage | comment_diagnosis, open_pr         |
| #38     | Add dark mode toggle   | label, comment_triage | comment_diagnosis, create_branch   |
```

Review the table and confirm to start watching for real.

## Step 4: Start the Loop

Once you confirm, Argos tells you how to activate continuous monitoring:

```
/loop 5m invoke the argos skill for owner/repo
```

This polls your repo every 5 minutes (or whatever interval you chose). When no new issues exist, the poll uses zero LLM tokens -- it is a lightweight `gh` CLI call.

## Step 5: Monitor and Approve

Use these commands to stay in control:

| Command | What it does |
|---------|-------------|
| `/argos-status` | See all watched repos, pending approvals, recent actions, and guardrail usage |
| `/argos-approve #42` | Approve a pending action (e.g., opening a PR for issue #42) |
| `/argos-approve #42 reject` | Reject a pending action |
| `/unwatch owner/repo` | Stop watching a repo |

## Understanding the Output

Argos communicates through the channels you configured during setup:

- **GitHub comments** -- Argos posts triage comments and action summaries directly on the issue, visible to your whole team.
- **System notifications** -- macOS Notification Center alerts for approval requests and important events.
- **Session context** -- When you start a new Claude Code session, Argos tells you about pending approvals and actions taken while you were away.

## What Happens Next

Once the loop is running, Argos works in the background:

1. It polls for new issues at your configured interval.
2. For each new issue, it classifies it (bug, enhancement, duplicate, question, or other).
3. It checks each possible action against your policy tiers:
   - **auto** actions execute immediately (e.g., applying labels, posting a triage comment).
   - **approve** actions are queued until you review them via `/argos-approve`.
   - **deny** actions are never performed.
4. Guardrails enforce hard limits (rate limiting, max open PRs, protected file paths).
5. Over time, Argos stores patterns in Memories MCP -- it gets better at detecting duplicates, recognizing hotspots, and understanding your codebase.

## Next Steps

- Read the [Policy Configuration](features/feat-002-policy-configuration.md) guide to fine-tune your boundaries.
- Check the [Config Reference](config-reference.md) for every available YAML option.
- Walk through the [First Watch Tutorial](tutorials/tut-001-first-watch.md) for a hands-on example with a real repo.
