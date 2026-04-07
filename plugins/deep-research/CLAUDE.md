# deep-research

## Overview

A Claude Code skill for multi-step web research that goes beyond shallow single-query search. Orchestrates parallel agents with query variance, source-type filtering, and iterative deepening to produce cited, triangulated findings.

## Problem

Current web research in CC is one-shot: a single WebSearch call, skim the snippets, done. This misses depth, contradictions, and source diversity. The skill forces a structured retrieval pipeline using existing primitives (WebSearch + WebFetch) without requiring new MCP servers.

## Architecture

```
SCOPE   → Understand the question, classify research type
PLAN    → Generate query variants x source-type filters
RETRIEVE → Dispatch parallel agents (WebSearch → WebFetch top results)
TRIANGULATE → Cross-reference, flag contradictions, identify gaps
DEEPEN  → Follow-up queries targeting gaps (second agent wave)
SYNTHESIZE → Structured output with citations and confidence
```

## Available Primitives

| Tool | Controls | Variance Lever |
|---|---|---|
| WebSearch | query, allowed_domains, blocked_domains | Query phrasing, domain filtering |
| WebFetch | url, prompt | Extraction prompt (facts vs opinions vs code) |
| Agent | parallel subagents | Each agent = independent search+read pipeline |

## Key Design Decisions

- **No new MCP required** — orchestrates existing WebSearch + WebFetch
- **Parallel agents for variance** — different query angles + source types run concurrently
- **WebFetch is mandatory** — actually read the top results, don't just skim snippets
- **Two retrieval waves** — initial search, then gap-targeted follow-ups
- **Domain filtering for source diversity** — official docs, community (Reddit/HN), code (GitHub), academic, news
- **Does NOT duplicate council** — this is retrieval + synthesis, not deliberation. Pipe output to /council if a decision is needed.

## Install Target

`~/.claude/skills/research/SKILL.md` — user-level skill, available across all projects.

## Commands

```bash
# Dev: test the skill locally
claude --skill ./SKILL.md "research topic here"

# Install: symlink to skills dir
ln -sf $(pwd)/SKILL.md ~/.claude/skills/research/SKILL.md
```

## Stack

- Pure markdown skill (no dependencies)
- Uses: WebSearch, WebFetch, Agent (subagents), Write (output)

## Conventions

- Skill follows superpowers frontmatter format (name, description, allowed-tools, context, etc.)
- Output goes to `RESEARCH/[topic-slug]/` directory with findings.md + sources.md
- Each source gets a confidence tag: confirmed (2+ sources), single-source, contested
