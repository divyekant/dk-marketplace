---
id: fb-002
type: feature-brief
audience: marketing
topic: tiered-input-resolution
status: draft
generated: 2026-02-28
source-tier: direct
context-files: [docs/VISION.md]
hermes-version: 1.0.0
---

# Feature Brief: Tiered Input Resolution

## One-Liner

Hermes works on any project from day one — and gets smarter when you give it more context.

## What It Is

Hermes automatically determines the best available source of knowledge about your codebase and uses it to generate documentation. No configuration needed. It checks for a rich code index first (Carto), falls back to direct file reading, and always incorporates business context files when available. The result is documentation quality that scales with the context you provide, but never requires setup to get started.

## Who It's For

- **Primary:** Development teams adopting Hermes for the first time who want useful docs without upfront investment
- **Secondary:** Teams already using Carto for code indexing who want maximum documentation quality

## The Problem It Solves

Documentation tools typically require explicit setup: you need to configure what to document, point to the right files, set up schemas. This creates an adoption barrier — the tool that is supposed to save time requires time to set up. Teams delay adoption because "we'll set it up properly later," and later never comes.

## Key Benefits

- **Zero-setup start:** Point Hermes at any project and get useful documentation immediately. No configuration, no schema definitions, no file manifests.
- **Quality that scales:** Start with basic docs from Tier 2, then unlock richer docs by adding Carto indexing or business context files. You invest when you are ready, not upfront.
- **Automatic optimization:** Hermes always uses the best available input without you choosing. It checks for a Carto index first, falls back gracefully, and layers context on top.

## How It Works (Simplified)

When you ask Hermes to generate docs, it first checks if your project has been deeply indexed by Carto. If yes, it uses that rich understanding. If not, it reads your source files, README, and git history directly. Either way, it also picks up any design docs or vision statements it finds. You always get docs — the question is just how detailed they are.

## Competitive Context

Competitive positioning requires additional context — provide competitive analysis docs to populate this section.

## Proof Points

- Three tiers of input quality, all handled automatically
- Falls back gracefully — never fails due to missing setup
- Context files auto-discovered from standard project locations

## Suggested Messaging

- **Announcement:** "Hermes now works on any project without setup — and gets even better when paired with Carto indexing."
- **Sales pitch:** "No configuration required. Hermes reads your codebase directly and produces useful docs from the first run."
- **One-liner:** "Documentation from day one, richer docs over time."
