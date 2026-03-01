---
type: migration-guide
audience: external
from-version: 0.x
to-version: 1.0.0
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Migration Guide: v0.x to v1.0.0

## Overview

Hermes v1.0.0 is the first stable release. There are no prior versions to migrate from — this guide exists as a reference for projects that may have used early development builds of the skill.

## Breaking Changes

No breaking changes — v1.0.0 is the initial release. If you used a pre-release version of Hermes (v0.1.0 through v0.3.0 as outlined in the phased rollout), note the following consolidation:

### Template Completeness
**What changed:** Pre-release versions had a subset of templates. v1.0.0 includes all 17 document templates.
**Why:** Phased rollout is complete. All doc types are now available.
**Before (v0.1.0):** 5 templates (Feature Handoff, Release Notes, Changelog, Feature Brief, Datasheet)
**After (v1.0.0):** 17 templates (full set)
**Migration steps:**
1. Delete existing `docs/generated/` directory
2. Delete `.hermes.md` state file
3. Run Hermes again for a complete generation

### Frontmatter Version Field
**What changed:** The `hermes-version` field in YAML frontmatter now reads `1.0.0` instead of `0.1.0`.
**Why:** Reflects the stable release version.
**Before (v0.x):**
```yaml
hermes-version: 0.1.0
```
**After (v1.0.0):**
```yaml
hermes-version: 1.0.0
```
**Migration steps:**
1. No action needed — regenerating docs will update the version automatically

## Deprecated Features

No features are deprecated in v1.0.0.

## New Features

All features in v1.0.0 are new (relative to having no Hermes at all):
- **Multi-Audience Generation** — [docs](../features/feat-001-multi-audience-generation.md)
- **Tiered Input Resolution** — [docs](../features/feat-002-tiered-input-resolution.md)
- **Mode System** — [docs](../features/feat-003-mode-system.md)

## Checklist

- [ ] Ensure Claude Code is installed and configured
- [ ] Copy `skills/hermes/skill.md` to your project (or verify it is available in your skill ecosystem)
- [ ] If upgrading from pre-release: delete `docs/generated/` and `.hermes.md`
- [ ] Run "Generate docs for this project" for a clean first generation
- [ ] Verify: check `docs/generated/index.md` exists and lists all 17+ doc types
