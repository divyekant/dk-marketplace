---
id: fb-001
type: feature-brief
audience: marketing
topic: argos
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Feature Brief: Argos

## One-Liner

Argos watches your GitHub repos for new issues and acts on them automatically -- on your machine, within boundaries you define.

## What It Is

Argos is a Claude Code plugin that continuously monitors GitHub repositories for new issues, triages them, and takes action -- all running locally. It classifies incoming issues, applies labels, posts diagnostic comments, creates branches, opens pull requests, and closes duplicates. Every action follows a policy you configure: some things happen automatically, some wait for your approval, some are explicitly forbidden.

It runs as a background loop inside Claude Code, polling via the GitHub CLI. When nothing is happening, it costs zero tokens. When an issue lands, it brings the full power of Claude Code to bear -- local codebase access, Memories for cross-session learning, MCP servers, and skills -- to investigate and respond.

## Who It's For

- **Solo developers** who maintain open-source projects and want issues triaged without constant context-switching.
- **Small teams** where nobody owns issue triage full-time but response time matters.
- **Engineering leads** who want a first-pass investigation on every incoming bug report before assigning it to a human.
- **Anyone using Claude Code** who wants their AI assistant to be proactive, not just reactive.

## Problem It Solves

Issues pile up. Triage is tedious. By the time someone looks at a bug report, the context is stale and the reporter has moved on. Server-side automation tools can label and auto-close, but they cannot investigate your codebase, understand your architecture, or learn from past resolutions. Developers end up doing the same diagnostic work repeatedly -- checking which files are affected, whether the issue is a duplicate, and what a fix might look like.

Argos eliminates that first-pass work entirely. It watches, investigates, and acts -- or asks for permission first -- so developers engage with issues that already have context, diagnosis, and sometimes a ready PR.

## Key Benefits

1. **Zero-effort triage.** Issues get classified, labeled, and assigned without human intervention. Duplicates are caught and closed automatically.

2. **Local-first privacy.** Your code never leaves your machine. Argos runs inside Claude Code, not on a remote server. No source code is sent to third-party infrastructure beyond what Claude Code itself handles.

3. **Configurable autonomy.** You decide what is automatic, what needs approval, and what is forbidden. Three tiers (auto/approve/deny) with three approval modes (wait/timeout/default) give precise control.

4. **Deep investigation, not just labeling.** Argos can read your codebase, trace through call stacks, identify affected files, and post a diagnostic comment -- the kind of investigation a senior developer would do.

5. **Gets smarter over time.** Memories MCP persists patterns, resolution history, and codebase hotspots across sessions. Argos learns which files break together, which issues are recurring, and which team members handle what.

6. **Hard guardrails.** Rate limits, protected file paths, max open PRs, and a dry-run mode ensure Argos cannot go rogue regardless of policy configuration.

## Competitive Context

| Capability | Argos | GitHub Agentic Workflows | Copilot Coding Agent | claude-code-action |
|---|---|---|---|---|
| Runs locally | Yes | No (server-side) | No (server-side) | No (server-side) |
| Proactive monitoring | Yes | Yes | No (reactive) | No (reactive) |
| Full codebase context | Yes (local files) | No (limited to PR diff) | Partial | No |
| Tiered autonomy | Yes (auto/approve/deny) | No | No | No |
| Cross-session learning | Yes (Memories MCP) | No | No | No |
| Customizable actions | Fully configurable YAML | Limited | Limited | Limited |
| Zero-cost idle | Yes (bash polling) | N/A (event-driven) | N/A | N/A |

**Key differentiator:** Argos is the only solution that combines proactive issue monitoring with local codebase access and user-defined autonomy boundaries. Competitors either run server-side (losing local context and privacy) or react only when explicitly triggered (losing the proactive advantage).

## Suggested Messaging

**Headline options:**
- "Your issues, handled -- before you even look at them."
- "The AI teammate that watches your repo while you ship."
- "Proactive issue triage that runs on your machine, plays by your rules."

**Positioning statement:**
Argos brings proactive, intelligent issue management to Claude Code. It watches your GitHub repos, investigates new issues using your full local codebase, and takes action within boundaries you define -- so you spend less time triaging and more time building.

**Key phrases to use:**
- Local-first (privacy angle)
- Configurable boundaries (trust/control angle)
- Gets smarter over time (long-term value angle)
- Zero-cost idle (efficiency angle)

**Key phrases to avoid:**
- "Fully autonomous" (implies no control)
- "Replaces developers" (wrong framing -- it augments)
- "Set and forget" (undersells the configurability that is the product's strength)
