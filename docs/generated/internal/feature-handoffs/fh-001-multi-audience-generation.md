---
id: fh-001
type: feature-handoff
audience: internal
topic: multi-audience-generation
status: draft
generated: 2026-02-28
source-tier: direct
context-files: [docs/VISION.md, docs/plans/2026-02-28-hermes-design.md, .apollo.yaml]
hermes-version: 1.0.0
---

# Feature Handoff: Multi-Audience Documentation Generation

## What It Does

Hermes takes a single codebase and generates structured documentation for three distinct audiences: internal teams (CS/Support/Engineering), external users (developers/end users), and marketing (product marketing/sales). Each audience receives fundamentally different documents with different voice, structure, and level of detail. This eliminates the "translation tax" where every non-engineering team manually reverse-engineers what was built from commit messages, Slack threads, and Jira tickets.

The core principle is "same source, different lens." A single feature produces a technical Feature Handoff for CS, a user-facing Feature Doc for developers, and a benefit-focused Feature Brief for marketing — all generated from the same code analysis.

## How It Works

Hermes operates as a Claude Code skill defined in `skills/hermes/skill.md`. When invoked, it follows this pipeline:

1. **Input Resolution** — Checks for a Carto index in Memories MCP first (Tier 1). If unavailable, falls back to directly reading the codebase: README, CLAUDE.md, package manifests, source directories, and git history (Tier 2). Context files like design docs and vision statements always layer on top (Tier 3).

2. **Feature Discovery** — Scans the resolved input to identify documentable features. Groups related files into feature areas by directory structure, naming conventions, or Carto zones. Presents a feature map for user confirmation.

3. **Audience Routing** — Routes each confirmed feature through three generators in order: Internal first (forces deep understanding), External second (simplifies for users), Marketing third (reframes for value). Each generator applies audience-specific templates and voice guidelines.

4. **Output Writing** — Writes generated docs to `docs/generated/` following a strict directory structure. Updates `.hermes.md` state file for resume capability. Optionally stores summaries in Memories MCP under `hermes/{project}/` prefixes.

Key components:
- `skills/hermes/skill.md` — the entire skill definition, templates, and generation logic
- `.hermes.md` — disk-based state tracking for resume and delta generation
- `docs/generated/` — output directory with `internal/`, `external/`, `marketing/` subdirectories

## User-Facing Behavior

Users invoke Hermes through natural language within Claude Code:
- "Generate docs for this project" — full generation for all audiences
- "Generate internal docs" — internal docs only
- "Update docs" — delta generation since last run
- "Document what changed since v1.0" — version-scoped update

On invocation, Hermes announces the input tier it is using ("Using Carto index" or "Reading codebase directly"), presents a feature map for confirmation, then generates docs sequentially by audience. Progress is tracked in `.hermes.md` so interrupted runs can resume.

Output appears as markdown files in `docs/generated/` with YAML frontmatter on every document for programmatic consumption.

## Configuration

| Option | Type | Default | Effect |
|--------|------|---------|--------|
| Source tier | auto-detected | Tier 2 (direct) | Determines input quality: Carto (best), direct codebase (good), context-only (minimal) |
| Mode | string | generate | Controls scope: generate (full), update (delta), internal/external/marketing (single audience) |
| Context files | file list | auto-discovered | Additional files layered on top of code analysis (design docs, PRDs, vision docs) |
| Output directory | path | docs/generated/ | Where generated docs are written |

Hermes does not use environment variables or feature flags. All configuration is implicit through invocation keywords and the state file.

## Edge Cases & Limitations

- **No Carto index degrades quality** — Without Carto, Hermes relies on file structure and naming conventions to discover features. Projects with non-standard layouts may produce incomplete feature maps.
- **Markdown-only output** — Hermes generates markdown files. It does not produce HTML, PDF, or host documentation. A separate hosting solution is needed.
- **No image generation** — Screenshots, diagrams, and visual assets are not generated. Marketing docs suggest where visuals would be useful but don't create them.
- **Context file quality matters** — The marketing generator relies heavily on business context from design docs and vision statements. Without these, competitive context and proof points sections will be sparse.
- **Git history dependency** — Changelog and release notes generators parse git log. Projects with poor commit hygiene (e.g., "fix stuff", "WIP") will produce lower-quality changelogs.
- **Single-file skill limitation** — All logic lives in one markdown file. There is no programmatic API, no importable library, no standalone CLI.

## Common Questions

**Q: Does Hermes require Carto to work?**
A: No. Hermes is Carto-enhanced, not Carto-dependent. It works with any project by reading the codebase directly (Tier 2). Carto provides richer understanding (function-level atoms, dependency graphs) but is not required.

**Q: Can I generate docs for just one audience?**
A: Yes. Use "generate internal docs", "generate external docs", or "generate marketing docs" to target a single audience. The mode is detected from the invocation keywords.

**Q: What happens if I run Hermes again after docs already exist?**
A: Hermes checks `.hermes.md` for existing state. If docs are complete, it asks whether to regenerate from scratch or update with changes. It will not silently overwrite existing docs.

**Q: Can Hermes generate docs for a specific feature only?**
A: Yes. During feature discovery, Hermes presents a feature map and asks for confirmation. You can scope down to specific features at that point.

**Q: How does the update mode work?**
A: Update mode reads `.hermes.md` for the last generation timestamp, runs `git log --since` to find changes, identifies affected features, and regenerates only the docs for those features. Unchanged features are skipped.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| "No Carto index" message when Carto was run | Carto stored under different project name | Check Memories for `carto/` prefix entries; the project name must match |
| Empty feature map | Non-standard project layout, no recognizable source directories | Provide context files manually or restructure source into `src/`, `lib/`, or `api/` |
| Sparse marketing docs | No business context files available | Add design docs, PRDs, or vision statements to `docs/plans/` before running |
| Incomplete changelog | Poor commit messages in git history | Consider rewriting commit messages or providing a manual changelog as context |
| Resume not working | `.hermes.md` was deleted or corrupted | Delete `.hermes.md` and run a fresh generation |

## Related

- [Tiered Input Resolution](fh-002-tiered-input-resolution.md) — how Hermes gathers source material
- [Mode System](fh-003-mode-system.md) — the five operational modes
- [State Tracking & Resume](fh-004-state-tracking.md) — how `.hermes.md` enables resumable generation
- [Template System](fh-005-template-system.md) — the 17 document templates
- [VISION.md](../../VISION.md) — project vision and success criteria
