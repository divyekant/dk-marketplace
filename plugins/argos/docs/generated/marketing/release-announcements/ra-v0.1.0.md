# Argos v0.1.0: Your GitHub Issues Now Get Investigated Before You Wake Up

**Release Date:** 2026-03-06

---

Argos v0.1.0 is the first release of the All-Seeing Issue Guardian -- a Claude Code plugin that watches your GitHub repositories for new issues and acts on them within boundaries you configure.

## What This Means For You

Starting today, you can run `/watch owner/repo` and walk away. Argos polls for new issues in the background, classifies them, investigates your local codebase for root causes, and takes action -- labeling, commenting, creating branches, or opening PRs -- all governed by a YAML policy you control.

Issues that used to sit untouched for hours now get triaged in minutes. Duplicate reports get caught and closed. Bug reports get diagnostic comments identifying affected files and likely causes. Your morning issue review becomes a quick scan of work already done, not a stack of unknowns.

## Highlights

### Local-First Investigation
Argos runs inside Claude Code on your machine. It reads your actual codebase -- not just the issue text -- to investigate reports. It can trace through your code, identify the specific files and functions involved, and post a diagnostic comment that gives you a head start on the fix.

### Tiered Autonomy
You define what Argos can do automatically (label, triage, assign), what needs your approval (create branches, open PRs), and what it must never do (force push, merge). A single YAML policy file controls everything. Actions not listed are denied by default.

### Cross-Session Learning
Argos uses Memories MCP to remember patterns across sessions. It learns which issues are duplicates, which files are hotspots, and which team members handle which areas. It gets more accurate and more useful over time.

### Zero-Cost Idle
Polling is pure bash via the GitHub CLI. No LLM tokens are consumed until an issue actually needs attention. Watch as many repos as you want without burning through your budget on empty polls.

### Safety Guardrails
Hard limits apply regardless of policy: max 10 actions per hour, max 3 open PRs, protected file paths for secrets and production configs, and a dry-run mode for testing policies without consequences.

## What's Included

- `/watch` and `/unwatch` commands for repository monitoring
- `/argos-status` for observing queue depth and recent actions
- `/argos-approve` for reviewing and approving pending actions
- Guided onboarding flow with dry-run verification
- Three notification adapters: GitHub comments, macOS system notifications, session context injection
- Full policy engine with action tiers, approval modes, issue filters, and guardrails

## Requirements

- Claude Code with `/loop` support
- GitHub CLI (`gh`), authenticated
- Memories MCP
- jq, python3, pyyaml

## Get Started

```
/watch owner/repo
```

Argos walks you through policy setup on first run. Start with conservative defaults, run a dry cycle, then let it work.

## What's Next

- Multi-repo support in a single configuration
- Email, Telegram, and Slack notification adapters
- PR review monitoring (not just issues)
- Auto-learning policies that suggest tier promotions based on your approval history
- Integration with Delphi for automatic test generation on fixes

---

**License:** MIT
