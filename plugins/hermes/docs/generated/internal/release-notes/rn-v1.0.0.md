---
id: rn-v1.0.0
type: release-notes
audience: internal
version: 1.0.0
status: draft
generated: 2026-02-28
commit-range: f0e14cd..c34bb47
source-tier: direct
hermes-version: 1.0.0
---

# Internal Release Notes — v1.0.0

**Date:** 2026-02-28
**Commits:** 4 total
**Contributors:** Project maintainer

## Summary

Hermes v1.0.0 is the initial release of the audience-specific documentation generation skill. It delivers the complete skill definition with all 17 document templates across three audiences (internal, external, marketing), tiered input resolution (Carto/direct/context), five operational modes, disk-based state tracking, and resume capability. This release represents the full Phase 1-3 feature set shipped as a single-file Claude Code skill.

## Breaking Changes

None — this is the initial release.

## New Features

### Multi-Audience Documentation Generation
- **What:** Generates structured documentation for three audiences (internal, external, marketing) from a single codebase
- **How:** Analyzes code, docs, git history, and optionally Carto indexes to produce 17 document types with audience-specific voice and structure
- **Config:** No configuration required — mode detected from invocation keywords
- **Who it affects:** All teams — engineering, CS/Support, product marketing, sales
- **CS Notes:** This is the core feature. Users invoke it with "generate docs for this project." The most common first-run experience produces 17+ markdown files.

### Tiered Input Resolution
- **What:** Three-tier input system: Carto index (best), direct codebase (good), context files (supplementary)
- **How:** Checks Memories for Carto index first, falls back to file system globbing and git history, always layers context files on top
- **Config:** Auto-detected, no user configuration
- **Who it affects:** Doc quality scales with input quality. Projects with Carto get richer docs.
- **CS Notes:** If users report thin or inaccurate docs, recommend running Carto first or providing context files (design docs, PRDs).

### Five Operational Modes
- **What:** Generate (full), Update (delta), Internal, External, Marketing
- **How:** Mode detected from invocation keywords (e.g., "update docs", "generate internal docs")
- **Config:** Keyword-driven, no explicit flags
- **Who it affects:** All users — controls what documentation is generated
- **CS Notes:** Users should use "update docs" for incremental changes. Full generation is for first run or periodic refresh.

### State Tracking & Resume
- **What:** Disk-based `.hermes.md` state file tracks generation progress
- **How:** Written after feature discovery, updated after each audience completes. Enables resume on interrupted runs and delta detection for updates.
- **Config:** State file path is fixed at `docs/generated/.hermes.md`
- **Who it affects:** Users with large projects or limited context windows who may need multi-session generation
- **CS Notes:** If generation appears stuck, check `.hermes.md` for state. Deleting it forces a fresh start.

### 17 Document Templates
- **What:** Complete template set covering internal (6), external (7), and marketing (4) doc types
- **How:** Each template defines YAML frontmatter schema, section structure, voice guidelines, and generation rules
- **Config:** Templates are embedded in the skill file, not configurable per-project
- **Who it affects:** All doc consumers — each audience gets purpose-built documents
- **CS Notes:** Templates ensure consistency but generated docs are drafts — users should review and refine before publishing.

## Improvements

None — initial release.

## Bug Fixes

None — initial release.

## Configuration Changes

| Option | Change | Old Value | New Value | Notes |
|--------|--------|-----------|-----------|-------|
| .hermes.md | Added | N/A | State tracking file | Created automatically on first run |

## Known Issues

- Publish mode is designed but not yet implemented — docs must be manually committed to version control
- No web UI for non-developer browsing of generated docs
- Marketing docs (Competitive Context, Proof Points) produce placeholder text when no business context files are provided
- Very large projects without Carto may produce incomplete feature maps due to Tier 2 limitations

## Internal Notes

- Hermes is a single-file skill (`skills/hermes/skill.md`) with no runtime dependencies
- The skill follows the Delphi pattern: markdown-based, portable, no build step
- Part of the skill ecosystem: Apollo (scaffold) | Carto (index) | Delphi (test) | Conductor (orchestrate) | Hermes (communicate)
- Future versions will add CI/CD hooks, doc diff views, and a review workflow
