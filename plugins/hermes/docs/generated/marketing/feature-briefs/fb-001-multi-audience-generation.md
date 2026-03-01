---
id: fb-001
type: feature-brief
audience: marketing
topic: multi-audience-generation
status: draft
generated: 2026-02-28
source-tier: direct
context-files: [docs/VISION.md]
hermes-version: 1.0.0
---

# Feature Brief: Multi-Audience Documentation Generation

## One-Liner

Hermes generates documentation for CS, developers, and marketing teams simultaneously from a single codebase — ending the translation tax that delays every release.

## What It Is

Hermes reads your codebase and produces three sets of documentation from the same source: detailed feature handoffs for customer support, user-facing guides for developers, and benefit-focused briefs for marketing. Each set uses the right language, structure, and level of detail for its audience. No more reverse-engineering features from Slack threads or asking engineering "what does this do?"

## Who It's For

- **Primary:** Software teams where CS, marketing, and docs fall behind engineering releases. Typically mid-size companies (50-500 people) where the gap between "feature shipped" and "everyone else knows about it" is measured in weeks, not hours.
- **Secondary:** Developer tools and open-source projects that need high-quality user docs and changelogs without a dedicated technical writing team.

## The Problem It Solves

Every time engineering ships a feature, a translation tax kicks in. CS finds out about the feature from a customer asking "what does this do?" Marketing scrambles to write about it from Slack threads and Jira tickets. The docs team reverse-engineers behavior from the code because nobody wrote it down. Sales promises capabilities they heard about in a standup.

The knowledge exists — it is in the code, the design docs, the git history. But it is locked in engineering-speak. Every other team manually translates it into their own language, their own format, their own context. This translation is expensive, slow, error-prone, and almost always incomplete.

The result: internal teams are perpetually behind. Documentation is stale. Marketing copy does not match reality. CS answers questions with "let me check with engineering."

## Key Benefits

- **Eliminate the engineering-to-CS gap:** Feature handoffs are generated automatically, so CS can answer customer questions about new features without waiting for engineering to write documentation
- **Ship marketing materials at release speed:** Feature briefs and one-pagers are ready within minutes of a release, not days of reverse-engineering
- **Keep docs perpetually current:** Update mode generates delta documentation from git history, so docs evolve with the code instead of falling behind
- **No new tools to learn:** Hermes runs inside existing Claude Code sessions via natural language — no dashboards, no editors, no learning curve
- **Works on any project:** No prior setup required. Hermes reads your codebase directly and produces useful docs from day one. Optionally enhanced with Carto indexing for deeper analysis.

## How It Works (Simplified)

Hermes analyzes your project's code, documentation, and git history to understand what was built. It then generates three tailored document sets: internal docs for support teams (explaining how things work, edge cases, troubleshooting), external docs for users (how to use it, configuration, examples), and marketing docs for go-to-market teams (what it is, why it matters, messaging). Everything is generated as reviewable markdown files with tracking metadata.

## Competitive Context

The market has tools that understand code (Swagger, TypeDoc, JSDoc) and tools that understand audiences (MadCap Flare, Mintlify, GitBook). Nobody combines code-aware, audience-aware, and AI-generated documentation.

- **vs. Swagger/TypeDoc:** These generate developer API reference only — one audience, one format. Hermes generates for three audiences.
- **vs. Mintlify/GitBook:** These are doc hosting platforms that require manual writing. Hermes generates the content automatically.
- **vs. DocuWriter/Swimm:** These generate developer docs from code — still one audience. Hermes adds internal (CS) and marketing audiences.

Hermes occupies an empty intersection: code-aware + audience-aware + AI-generated.

## Proof Points

- Generates 17+ structured documents from a single codebase analysis
- Supports incremental updates — only changed features are regenerated
- Works without any prior project setup (Tier 2 input)
- Production-quality docs from the first run (not placeholder stubs)

## Suggested Messaging

- **Announcement:** "Hermes turns your codebase into documentation for every team — CS, developers, and marketing — from a single source. No more translation tax."
- **Sales pitch:** "Your CS team finds out about features from customers. Your marketing team writes from Slack threads. Hermes fixes that by generating audience-specific docs the moment you ship."
- **One-liner:** "One codebase. Three audiences. Zero manual translation."
