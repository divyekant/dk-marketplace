---
id: fh-002
type: feature-handoff
audience: internal
topic: tiered-input-resolution
status: draft
generated: 2026-02-28
source-tier: direct
context-files: [docs/VISION.md, docs/plans/2026-02-28-hermes-design.md]
hermes-version: 1.0.0
---

# Feature Handoff: Tiered Input Resolution

## What It Does

Tiered Input Resolution is Hermes's mechanism for gathering source material from any project, regardless of whether that project has been indexed by Carto. It defines three tiers of input — Carto index (best quality), direct codebase reading (good quality), and context files (supplementary) — and resolves them in priority order to build a comprehensive understanding of what needs to be documented.

This design makes Hermes universally applicable. It works on any codebase without prior setup, while delivering richer output when Carto indexing is available.

## How It Works

The resolution process runs at the start of every Hermes invocation and proceeds through three stages:

**Tier 1 — Carto Index (checked first):**
- Searches Memories MCP for entries with source prefix `carto/{project-name}/`
- If found, pulls atoms (function-level understanding), blueprint (system architecture), zones (feature groupings), and patterns (recurring design patterns)
- Sets `source-tier: carto` in all generated doc frontmatter
- Announces: "Found Carto index for {project} — using full code understanding."

**Tier 2 — Direct Codebase (fallback if no Carto):**
- Globs the project for key files: `package.json`, `README.md`, `CLAUDE.md`, `.apollo.yaml`, source directories (`src/`, `lib/`, `api/`), API specs (`openapi.yaml`, `swagger.*`)
- Reads key files to understand project purpose, structure, and capabilities
- Parses `git log --oneline -30` for recent history
- Parses `git tag -l --sort=-version:refname | head -5` for version information
- Sets `source-tier: direct` in all generated doc frontmatter
- Announces: "No Carto index — reading codebase directly."

**Tier 3 — Context Files (always runs, layers on top):**
- Auto-discovers: `docs/plans/*.md`, `docs/decisions/*.md`, `.apollo.yaml`, `CHANGELOG.md`, `docs/VISION.md`
- Accepts user-specified files as additional context
- Adds business context (competitive positioning, design rationale, vision) that code alone cannot provide
- Announces: "Also using {N} context files: {file list}"

For update mode, a fourth stage runs:
- Reads `.hermes.md` for last generation timestamp
- Runs `git log --oneline --since="{timestamp}"` and `git diff --stat` to identify changes
- Maps changed files back to features for targeted regeneration

## User-Facing Behavior

Users see an announcement at the start of Hermes indicating which tier is being used. This is purely informational — users do not configure tiers. The tier is auto-detected based on what is available:

- "Found Carto index for hermes — using full code understanding."
- "No Carto index — reading codebase directly."
- "Also using 3 context files: VISION.md, hermes-design.md, .apollo.yaml"

The source tier is recorded in the YAML frontmatter of every generated document, providing traceability for how each doc was produced.

## Configuration

| Option | Type | Default | Effect |
|--------|------|---------|--------|
| Tier selection | auto-detected | Tier 2 if no Carto | Determines input quality and completeness |
| Context files | auto-discovered + user-specified | docs/plans/, docs/decisions/, .apollo.yaml, VISION.md | Additional business context layered on any tier |

There are no manual overrides to force a specific tier. The system always uses the best available input.

## Edge Cases & Limitations

- **Carto project name mismatch** — Tier 1 lookup uses the project directory name as the key. If Carto indexed the project under a different name (e.g., the directory was renamed after indexing), the lookup will fail and Hermes falls back to Tier 2.
- **Large codebases without Carto** — Tier 2 reads key files but cannot analyze every source file. For projects with hundreds of source files, some features may be missed during discovery. Carto provides a complete inventory.
- **Context file discovery is path-dependent** — Auto-discovery only looks in `docs/plans/`, `docs/decisions/`, and root-level files. Context files in non-standard locations are not found unless the user specifies them.
- **Git history required for update mode** — Projects without git history (or with squashed/rebased history) cannot use change detection for update mode.

## Common Questions

**Q: How do I get Tier 1 (Carto) quality?**
A: Run Carto on the project first: "Index this project with Carto." Carto stores its index in Memories MCP, and Hermes will automatically detect and use it on the next run.

**Q: Does Tier 2 produce bad docs?**
A: No — Tier 2 produces good docs. Tier 1 produces better docs because Carto provides function-level understanding, dependency graphs, and domain groupings. Tier 2 relies on file structure and naming conventions, which works well for most projects but may miss subtle relationships.

**Q: Can I add my own context files?**
A: Yes. Mention specific files when invoking Hermes: "Generate docs for this project, also use competitive-analysis.md and product-roadmap.md." Hermes reads any file you reference.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Hermes says "No Carto index" even though Carto was run | Project name mismatch between Carto and Hermes | Search Memories for `carto/` to find the stored project name; ensure it matches the directory name |
| Context files not discovered | Files in non-standard locations | Specify files explicitly in the invocation or move them to `docs/plans/` |
| Update mode says "no changes found" | Last generation timestamp in `.hermes.md` is in the future | Delete `.hermes.md` and run a fresh generation |

## Related

- [Multi-Audience Generation](fh-001-multi-audience-generation.md) — the core generation feature
- [State Tracking & Resume](fh-004-state-tracking.md) — how `.hermes.md` tracks generation state
