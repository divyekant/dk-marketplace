---
id: feat-001
type: feature-doc
audience: external
topic: multi-audience-generation
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Multi-Audience Documentation Generation

## Overview

Hermes generates structured documentation for three audiences from a single codebase: internal teams (CS, Support, Engineering), external users (developers, end users), and marketing (product marketing, sales). You write code once, and Hermes translates it into the right language for each audience — eliminating the manual translation work that slows down every non-engineering team.

## How to Use It

1. **Navigate to your project directory** in a Claude Code session
2. **Invoke Hermes:** Say "Generate docs for this project"
3. **Review the feature map:** Hermes presents the features it discovered. Confirm which ones to document.
4. **Wait for generation:** Hermes processes Internal, then External, then Marketing docs in order
5. **Find your docs** in `docs/generated/` — organized by audience with a master index at `docs/generated/index.md`

## Configuration

| Option | Description | Default |
|--------|-------------|---------|
| Audience scope | Which audiences to generate for | All three (internal, external, marketing) |
| Feature scope | Which features to document | All discovered features |
| Context files | Additional business context files | Auto-discovered from docs/plans/ |

You configure these through natural language, not config files:
- "Generate internal docs only" — scopes to one audience
- "Generate docs, also use my-prd.md" — adds context files
- During feature map review, you can scope to specific features

## Examples

### Example: Full project documentation
```
You: Generate docs for this project
Hermes: No Carto index — reading codebase directly.
        Also using 2 context files: VISION.md, design.md

        Feature Map:
        - authentication (5 components) — UI + API
        - dashboard (3 components) — UI
        - notifications (2 components) — API + Worker

        Generate docs for all features?

You: Yes, all features

Hermes: [generates 17+ docs across 3 audiences]
        Generated 23 documents across 3 audiences.
        See docs/generated/index.md for the full index.
```

### Example: Single audience generation
```
You: Generate marketing docs for this project
Hermes: [generates Feature Briefs, One-Pagers, Datasheet, Release Announcement]
        Generated 6 marketing documents.
```

### Example: Incremental update
```
You: Update docs — what changed since last generation?
Hermes: 5 commits since last generation affecting: authentication, notifications
        Update docs for these features?

You: Yes

Hermes: Updated 8 documents. Changelog updated through latest commit.
```

## Limitations

- Generated docs have `status: draft` — they should be reviewed before publishing
- Marketing docs with Competitive Context and Proof Points sections require business context files (competitive analyses, customer feedback) to be fully populated
- The changelog generator depends on git commit message quality — projects with descriptive commits produce better changelogs
- Hermes generates markdown only — hosting and rendering is handled separately

## Related

- [Getting Started](../getting-started.md) — quick start guide
- [Tiered Input Resolution](feat-002-tiered-input-resolution.md) — how Hermes gathers source material
- [Mode System](feat-003-mode-system.md) — the five operational modes
