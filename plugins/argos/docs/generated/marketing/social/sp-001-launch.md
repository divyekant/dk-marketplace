# Social Posts: Argos Launch

## Twitter / X (under 280 characters)

### Option A
Argos: a Claude Code plugin that watches your GitHub repos for new issues, investigates your local codebase, and acts within boundaries you define. Local-first. Policy-governed. Zero tokens when idle.

### Option B
Stop triaging issues manually. Argos monitors your GitHub repos, classifies bugs, posts diagnostics, and opens PRs -- all locally, all within rules you set. One command: /watch owner/repo

### Option C
What if your AI assistant watched your repo while you slept? Argos polls for new GitHub issues, investigates using your local codebase, and takes action within configurable tiers. Local-first, learns over time.

---

## LinkedIn

### Post

We built Argos -- a Claude Code plugin that turns issue triage from a daily chore into a background process.

The problem is universal: issues accumulate, triage is repetitive, and by the time someone investigates a bug report, the context has gone cold. Server-side tools can label and auto-close, but they cannot read your codebase or learn from past resolutions.

Argos runs locally inside Claude Code. It polls your GitHub repos for new issues, investigates them against your full local codebase, and takes action within boundaries you define in a YAML policy file:

- Auto: label, triage, assign, close duplicates
- Approve: diagnostics, branches, PRs (queued for your sign-off)
- Deny: force push, merge, delete (never happens)

It uses Memories MCP to learn across sessions -- spotting duplicates faster, routing assignments better, and identifying codebase hotspots over time.

Hard guardrails ensure safety: rate limits, protected file paths, max open PRs, and dry-run mode.

One command to start: /watch owner/repo

MIT licensed. Local-first. Your code stays on your machine.

#OpenSource #DeveloperTools #AI #GitHub #ClaudeCode #DevProductivity #Automation

---

## Hacker News

### Title
Argos: Claude Code plugin that watches GitHub repos and acts on issues within configurable boundaries

### Text
We built Argos because we were tired of context-switching into triage mode every morning. It is a Claude Code plugin that polls GitHub repos for new issues and takes action -- locally, within policy boundaries you define.

Key design decisions:

1. Local-first. Argos runs inside Claude Code on your machine. It reads your local codebase for investigation, not just the issue text. This means it can trace call stacks, identify affected files, and post diagnostic comments that a server-side tool cannot.

2. Policy-driven autonomy. A YAML file defines three tiers: auto (label, triage), approve (PRs, branches -- queued for review), and deny (force push, merge -- never). Three approval modes: wait (block), timeout (skip), default (proceed). Actions not listed are implicitly denied.

3. Zero-cost idle. Polling is bash + gh CLI. No LLM tokens consumed until an issue needs attention.

4. Cross-session learning. Memories MCP persists resolution history, codebase hotspots, and duplicate patterns. Gets better over time.

5. Hard guardrails. Rate limits, protected paths, max open PRs, dry-run mode. These apply regardless of policy configuration.

Architecture is simple: /loop 5m invokes a bash poll script. If new issues exist, the Argos skill is invoked with full CC context. State is local JSON; learning is Memories MCP.

We chose CC plugin over a standalone daemon because it inherits the entire CC ecosystem for free: skills, hooks, MCP servers, and the conversation context.

Trade-off: requires CC running. Not a headless service. We think that is the right call for v1 -- local-first with full context beats server-side with partial context.

MIT licensed. Design doc in the repo.
