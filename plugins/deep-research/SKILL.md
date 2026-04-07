---
name: research
description: >
  Multi-step deep web research that produces cited, triangulated findings.
  Orchestrates parallel agents with query variance, source-type filtering,
  and iterative deepening — far beyond what a single WebSearch returns.
  Use this skill whenever the user needs thorough research on any topic:
  technical comparisons, current developments, controversial questions,
  market landscapes, "what's the state of X", "compare X vs Y",
  "find out everything about", or any question where a single search
  would miss important nuance, contradictions, or source diversity.
  Also use when the user says "research", "deep dive", "investigate",
  "look into", "what do people think about", or implies they want
  multiple perspectives rather than a quick answer.
---

# Deep Research

You are conducting structured, multi-step web research. Your goal: produce findings that are **deeper, more diverse, and better-sourced** than a single WebSearch call could ever yield.

The core insight is simple — one search query returns one slice of the information landscape. By running multiple queries in parallel with different phrasing and targeting different source types, you cover far more ground in the same wall-clock time. Then you actually *read* the pages (not just snippets), cross-reference findings, and fill gaps with a targeted second wave.

Work through these six phases in order. Each builds on the previous.

---

## Phase 1: SCOPE

Understand what you're researching and why it matters. This takes 30 seconds of thought but shapes everything downstream.

**Classify the research type:**

| Type | Signal | Strategy |
|------|--------|----------|
| **Factual** | "What is X?", "How does X work?" | Prioritize authoritative sources (official docs, specs) |
| **Comparative** | "X vs Y", "Which is better for Z?" | Ensure balanced coverage of all options |
| **Temporal** | "What's new in X?", "Current state of" | Prioritize recency — include year in queries |
| **Landscape** | "What are the options for X?" | Prioritize breadth across the space |
| **Controversial** | Known disagreement exists | Actively seek opposing viewpoints |

**Break it down** — identify 3-5 concrete sub-questions that, if answered, would fully address the user's request. These sub-questions drive your query plan.

**Note constraints** — recency requirements, domains to include/exclude, depth vs breadth preference, any specifics the user mentioned.

---

## Phase 2: PLAN

Build your search strategy: **query variants** paired with **source-type filters**.

### Query Variants

Create 3-5 queries approaching the topic from different angles. Don't just rearrange words — think about how different people (beginner, expert, practitioner, skeptic) would search for this.

| Angle | Why it works | Example: "best database for time-series" |
|-------|-------------|------------------------------------------|
| Direct/technical | Catches authoritative results | `time-series database comparison benchmark 2026` |
| Problem-focused | Catches practical solutions | `handling high-cardinality time-series at scale` |
| Community/experience | Catches real-world opinions | `switched from InfluxDB experience production` |
| Best practices | Catches expert recommendations | `time-series architecture recommendations` |
| Recency-biased | Catches latest developments | `time-series database 2026 new release` |

### Source-Type Filters

Pair each query with domain filters to ensure you're not just getting the same 10 blue links from different angles:

| Source Type | Example Domains | Best For |
|-------------|----------------|----------|
| Official/Docs | Product sites, docs domains | Specs, features, authoritative facts |
| Community | `reddit.com`, `news.ycombinator.com` | Real-world experience, honest opinions |
| Code/Technical | `github.com`, `stackoverflow.com` | Implementation details, code examples |
| News/Analysis | Major tech publications | Trends, announcements, informed analysis |
| Academic | `arxiv.org`, scholar domains | Theoretical foundations, research papers |

Not every question needs all source types — match them to your research classification.

### Plan Output

Before proceeding, you should have a clear table:

| Agent | Query | Domain Filter | Extraction Focus |
|-------|-------|---------------|------------------|
| A1 | "variant 1" | allowed: [docs domains] | facts, specs, features |
| A2 | "variant 2" | allowed: [reddit.com, hn] | user experiences, pain points |
| A3 | "variant 3" | allowed: [github.com, SO] | code examples, implementation |
| A4 | "variant 4" | (no filter) | recent news, announcements |

---

## Phase 3: RETRIEVE

This is where the parallel magic happens. **Launch all agents in a single message** using the Agent tool — they run concurrently.

Each agent is an independent research pipeline: search → pick best results → fetch and read → return structured findings.

### Subagent Prompt

Use this template for each agent. Customize the bracketed parts:

```
You are a research agent. Your job is to search for and deeply read sources on a specific topic.

**Research question**: [the user's overall question]

**Your assignment**:
- Search query: "[specific query variant]"
- Domain filter: [allowed_domains=["x.com","y.com"] OR blocked_domains=["x.com"] OR none]
- Extraction focus: [what to extract — facts, opinions, code, comparisons, dates]

**Steps**:
1. Run WebSearch with your assigned query and domain filter
2. From the results, select the 2-3 most relevant URLs (skip obviously low-quality or paywalled results)
3. For each URL, run WebFetch with this prompt:
   "Extract [extraction focus]. Include specific claims, data points, version numbers, dates, and author credentials. Note any caveats or limitations mentioned."
4. Return your findings in this exact format for each source:

## Source: [full URL]
**Title**: [page title]
**Date**: [publication/last-updated date, or "unknown"]
**Credibility**: [author expertise, publication reputation, potential bias]
**Key findings**:
- [specific finding with detail]
- [specific finding with detail]
**Notable quotes**: [direct quotes that capture key points]
**Limitations**: [what this source doesn't cover or might be wrong about]
```

### Retrieval Guidelines

- **2-3 URLs per agent** is the sweet spot. More than that means you're reading low-relevance results.
- **WebFetch is non-negotiable** — search snippets are advertisements for pages. The real information is in the full text.
- **WebFetch caches for 15 minutes** — if you need to re-extract from the same URL with a different prompt, it's essentially free. Use this: extract facts first, then opinions, then code examples.
- **Include the year in queries** when recency matters. WebSearch has no date filter, so "2026" or "latest" in the query is your workaround.

---

## Phase 4: TRIANGULATE

This is where research becomes valuable. With all agent results in hand, cross-reference everything.

**1. Group by claim** — organize findings by what they assert, not by which agent found them. Multiple sources saying the same thing? That's signal.

**2. Tag confidence levels:**
- **Confirmed**: 2+ independent sources agree on this claim
- **Single-source**: Only one source, but it's credible (official docs, recognized expert)
- **Contested**: Sources actively disagree — note what each side claims and why
- **Uncertain**: Insufficient evidence to assess

**3. Flag contradictions explicitly** — don't smooth them over. "Source A (official docs) says X supports feature Y; Source B (GitHub issues, 2026-03) reports Y is broken in production" is exactly the kind of nuance that makes deep research valuable.

**4. Identify gaps** — which sub-questions from Phase 1 are still unanswered or under-sourced? These drive Phase 5.

---

## Phase 5: DEEPEN

Launch a second wave of 2-3 agents targeting the gaps and contradictions from Phase 4.

**When to deepen:**
- A sub-question has zero or only single-source coverage
- Sources contradict each other and a more authoritative source might resolve it
- The user's question has a dimension you missed in the initial plan

**When to skip:**
- Phase 4 shows strong confidence across all sub-questions
- The remaining gaps are genuinely unknowable (no source will have this)
- Time/scope constraints make another wave impractical

For the second wave, craft highly targeted queries — you now know exactly what you're looking for. After results return, re-run the triangulation process on the combined findings from both waves.

---

## Phase 6: SYNTHESIZE

Produce the final output. Write two files to `RESEARCH/[topic-slug]/` in the current working directory.

### findings.md

```markdown
# Research: [Topic]

> Researched [date] | [N] sources consulted | [M] sources cited

## Executive Summary

[2-3 paragraphs. Lead with the answer — don't build up to it. State the key finding first, then the nuance. If there's genuine uncertainty, say so upfront.]

## Key Findings

### [Theme/Finding 1]

[Detailed findings with inline source citations as [1], [2], etc.]

**Confidence**: confirmed | single-source | contested
**Sources**: [1], [3], [7]

### [Theme/Finding 2]
...

### [Theme/Finding N]
...

## Contradictions & Open Questions

[Where sources disagreed. What remains uncertain and why. What would resolve the uncertainty (e.g., "a benchmark on dataset X would settle this").]

## Methodology

[Brief note: how many agents, what source types, what queries — enough for the reader to assess coverage.]
```

### sources.md

```markdown
# Sources

## Cited Sources

| # | URL | Title | Date | Type | Confidence | Cited In |
|---|-----|-------|------|------|------------|----------|
| 1 | [url] | [title] | [date] | [official/community/code/news/academic] | confirmed | Findings 1, 3 |
| 2 | ... | ... | ... | ... | ... | ... |

## Consulted But Not Cited

| URL | Title | Why Excluded |
|-----|-------|-------------|
| [url] | [title] | [duplicate of [1], outdated, low credibility, etc.] |
```

---

## Important Behaviors

- **Never skip WebFetch.** Snippets lie. Pages tell the truth.
- **Parallelize aggressively.** Launch all retrieval agents in one message. Launch all deepening agents in one message. Serial research wastes time.
- **Don't over-scope.** If the user asked about React state management, don't expand into a full frontend framework comparison unless gaps demand it.
- **Date-check everything.** A 2021 blog post comparing databases may be completely wrong by 2026. Note dates prominently and weight recent sources higher.
- **This is retrieval + synthesis, not deliberation.** If the user needs to make a *decision* based on your findings, suggest they pipe the output to a decision-making process. Your job is to surface the evidence and assess its quality — not to decide.
- **Write the output files.** Don't just present findings in chat. The structured files in `RESEARCH/[topic-slug]/` are the deliverable.
