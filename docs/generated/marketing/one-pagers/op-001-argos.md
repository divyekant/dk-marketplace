# Argos: The All-Seeing Issue Guardian

**Your GitHub issues, handled -- before you even open the tab.**

---

## The Problem

Every development team knows the pattern: issues pile up, triage falls behind, and by the time someone investigates a bug report, the context is cold. You spend 20 minutes reproducing what the reporter described, tracing through files, checking if it is a duplicate -- work that repeats for every single issue.

Server-side automation can label and auto-close, but it cannot read your codebase. It does not know which files are fragile, which bugs are recurring, or what a fix might look like. The investigation still falls on you.

## The Solution

Argos is a Claude Code plugin that watches your GitHub repos and acts on new issues -- on your machine, within rules you define.

It polls for new issues in the background. When one arrives, it reads the issue, investigates your local codebase, classifies the problem, and takes action: labeling, commenting with a diagnosis, creating a branch, or opening a PR. You control exactly which actions are automatic, which need your approval, and which are forbidden.

## Key Benefits

- **Eliminates first-pass triage.** Issues arrive pre-classified, labeled, and often with a diagnostic comment identifying affected files and likely root cause.

- **Runs locally, stays private.** Your source code never leaves your machine. No third-party servers, no data exfiltration risk beyond your existing Claude Code setup.

- **You set the boundaries.** YAML policy files define three tiers -- auto, approve, deny -- with configurable approval timeouts. Hard guardrails cap actions per hour, limit open PRs, and protect sensitive files.

- **Learns from every resolution.** Argos uses Memories MCP to persist patterns across sessions. It gets better at spotting duplicates, identifying hotspots, and routing assignments over time.

- **Zero cost when idle.** Polling is pure bash. No LLM tokens are consumed until an issue actually needs attention.

## How It Works

```
/watch owner/repo
```

One command. Argos begins polling, triaging, and acting -- all within your configured policy.

## Proof Points

- Hard guardrails: max 10 actions/hour, max 3 open PRs, protected file paths, dry-run mode.
- Built on Claude Code: skills, hooks, MCP servers, Memories.
- MIT licensed.

## Get Started

Run `/watch owner/repo`. Argos handles the triage; you handle the code.
