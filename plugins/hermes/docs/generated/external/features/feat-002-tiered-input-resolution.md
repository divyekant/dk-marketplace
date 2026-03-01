---
id: feat-002
type: feature-doc
audience: external
topic: tiered-input-resolution
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Tiered Input Resolution

## Overview

Hermes automatically determines the best available source of information about your project and uses it to generate documentation. You do not need to configure anything — Hermes checks for the richest input source first and falls back gracefully, ensuring it works with any project regardless of prior setup.

## How to Use It

You do not need to configure tiered input resolution. It runs automatically at the start of every Hermes invocation. Hermes announces which tier it is using:

- **Tier 1 (Carto index):** "Found Carto index for {project} — using full code understanding." This is the best quality. To get this tier, run Carto on your project first.
- **Tier 2 (Direct codebase):** "No Carto index — reading codebase directly." This is the default for most projects. Hermes reads your files, README, and git history.
- **Tier 3 (Context files):** "Also using {N} context files: {list}" This always layers on top of Tier 1 or 2.

## Configuration

| Option | Description | Default |
|--------|-------------|---------|
| Context files | Additional files to layer on top | Auto-discovered from docs/plans/, docs/decisions/, .apollo.yaml, VISION.md |

To add your own context files:
```
"Generate docs, also use product-roadmap.md and competitive-analysis.md"
```

## Examples

### Example: Getting Tier 1 (best quality)
```
You: Index this project with Carto     [run this first]
Carto: [indexes the project, stores in Memories]

You: Generate docs for this project
Hermes: Found Carto index for myproject — using full code understanding.
        Also using 1 context file: VISION.md
```

### Example: Adding business context
```
You: Generate marketing docs, also use docs/competitive-brief.md
Hermes: No Carto index — reading codebase directly.
        Also using 2 context files: VISION.md, competitive-brief.md
```

## Limitations

- Tier 1 requires running Carto first — it is not automatic
- Tier 2 relies on standard project conventions (src/, lib/, README.md). Non-standard layouts may produce incomplete feature discovery
- Context file auto-discovery only checks `docs/plans/`, `docs/decisions/`, and the project root. Files in other locations must be specified manually
- The source tier is recorded in every generated document's frontmatter, so you can always trace how a doc was produced

## Related

- [Multi-Audience Generation](feat-001-multi-audience-generation.md) — the core generation feature
- [Configuration Reference](../config-reference.md) — all configurable options
