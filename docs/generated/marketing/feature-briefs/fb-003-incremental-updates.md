---
id: fb-003
type: feature-brief
audience: marketing
topic: incremental-updates
status: draft
generated: 2026-02-28
source-tier: direct
context-files: [docs/VISION.md]
hermes-version: 1.0.0
---

# Feature Brief: Incremental Documentation Updates

## One-Liner

Hermes keeps documentation current by generating only what changed — so your docs evolve with your code, not weeks behind it.

## What It Is

After the initial documentation generation, Hermes tracks what it has produced and when. On subsequent runs, it analyzes git history to identify which features changed, then regenerates only the affected docs. Unchanged features are skipped entirely. This means keeping docs up to date takes seconds, not hours — run it on every release or every meaningful merge, and your docs stay perpetually current.

## Who It's For

- **Primary:** Teams with active codebases where features change frequently and docs fall behind within days of being written
- **Secondary:** Release managers who need changelogs, release notes, and marketing materials generated at release time without manual effort

## The Problem It Solves

Documentation is a depreciating asset. The moment it is written, it starts becoming stale. Every commit, every refactor, every feature addition widens the gap between what the code does and what the docs say. Teams that write docs manually fall behind immediately. Teams that use doc generators must re-run the entire process, which is slow and overwrites any manual edits.

## Key Benefits

- **Docs that keep up with code:** Run Hermes on every release and only changed features are re-documented. No full regeneration needed.
- **Release artifacts in seconds:** Changelogs, internal release notes, and marketing release announcements are generated from git history at the moment of release.
- **Respect for manual edits:** Docs for unchanged features are never touched, preserving any human refinements made after initial generation.
- **Smart change detection:** Hermes maps git changes to features, not files. A refactored utility file does not trigger regeneration of every feature doc — only features that actually changed.

## How It Works (Simplified)

Hermes saves a timestamp after each generation run. When you say "update docs," it checks what commits happened since that timestamp, figures out which features those commits affected, and regenerates docs only for those features. Everything else stays as-is.

## Competitive Context

Competitive positioning requires additional context — provide competitive analysis docs to populate this section.

## Proof Points

- Delta-based generation: only changed features are re-documented
- State tracking via `.hermes.md` enables accurate change detection
- Git-based change mapping connects commits to features, not just files

## Suggested Messaging

- **Announcement:** "Hermes now supports incremental updates — only regenerate docs for what actually changed."
- **Sales pitch:** "Your docs should evolve with your code. Hermes tracks changes and regenerates only what is needed, keeping documentation perpetually current."
- **One-liner:** "Update mode: docs that keep pace with your code."
