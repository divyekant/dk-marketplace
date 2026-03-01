# Hermes Design Document

**Date:** 2026-02-28
**Status:** Approved
**Phase:** v0.1.0

## Design Decisions

### 1. Single-file skill (skill.md)
Following Delphi's pattern. One markdown file containing all instructions, templates, and mode logic. Portable, no dependencies.

### 2. Multi-mode with selective generation (Approach B)
Three sub-modes (`internal`, `external`, `marketing`) that can run independently or together. Each mode pulls different source data and uses different voice/templates. Avoids all-or-nothing generation.

### 3. Tiered input — Carto-enhanced, not Carto-dependent
Checks for Carto index first, falls back to direct codebase reading. Context files always layer on top. This makes Hermes useful for any project.

### 4. Dual output — repo files + Memories
Markdown files in `docs/generated/` for humans. Memory entries under `hermes/{project}/` for AI consumption. Every doc has YAML frontmatter for programmatic parsing.

### 5. State tracking via .hermes.md
Disk-based state file tracks what was generated, when, from what input. Enables resume and delta generation.

### 6. Feature Brief as keystone
Marketing docs cascade from the Feature Brief. Generate the brief first, derive one-pagers and announcements from it.

## Implementation Plan

### Phase 1: Skill Skeleton (v0.1.0)

#### Step 1: Create skill.md with mode detection
**File:** `skills/hermes/skill.md`

- YAML frontmatter: name, description, triggers
- Mode detection logic (generate/update/internal/external/marketing/publish)
- Input resolution: Carto check → codebase fallback → context file discovery
- State file (.hermes.md) read/write
- Output directory structure creation
- Conductor integration config

#### Step 2: Input Resolution Engine
Within skill.md, define the input resolution procedure:

1. **Carto check:** Search Memories for `carto/{project}/` — if found, pull atoms, blueprint, zones, patterns. Announce: "Using Carto index."
2. **Direct codebase fallback:** Glob project for key files (README, CLAUDE.md, package.json, src/, lib/, api/). Read source files. Parse git log. Announce: "Reading codebase directly."
3. **Context file discovery:** Scan `docs/plans/`, `docs/decisions/`, `.apollo.yaml`. Accept user-specified files. Layer on top of Tier 1 or 2.
4. **Change detection (for update mode):** Read `.hermes.md` for last generation timestamp. Run `git log --since=<timestamp>` to find changes. Identify affected files/features.

#### Step 3: Internal — Feature Handoff Generator
**Template:** `fh-{NNN}-{feature-slug}.md`

```markdown
---
id: fh-{NNN}
type: feature-handoff
audience: internal
topic: {feature-name}
status: draft
generated: {date}
source-tier: {carto|direct|context}
hermes-version: 0.1.0
---

# Feature Handoff: {Feature Name}

## What It Does
{1-2 paragraph summary of the feature's purpose and behavior}

## How It Works
{Technical explanation — what happens under the hood, key components involved}

## User-Facing Behavior
{What the end user sees/experiences — UI changes, API changes, workflow changes}

## Configuration
{Config options, feature flags, environment variables that affect behavior}

## Edge Cases & Limitations
{Known limitations, boundary conditions, what it doesn't handle}

## Common Questions
{Anticipated questions from CS/Support with answers}

## Troubleshooting
{Known issues, error scenarios, diagnostic steps}

## Related
{Links to related features, docs, design docs}
```

#### Step 4: Internal — Release Notes Generator
**Template:** `rn-v{version}.md`

```markdown
---
id: rn-{version}
type: release-notes
audience: internal
version: {version}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 0.1.0
---

# Internal Release Notes — v{version}

**Date:** {date}
**Commits:** {count} since v{previous}

## Breaking Changes
{List of breaking changes with migration steps}

## New Features
{Each feature with: what it does, how it works, config, who it affects}

## Improvements
{Enhancements to existing features}

## Bug Fixes
{Bugs fixed with: symptom, root cause, resolution}

## Configuration Changes
{New/changed config options, env vars, feature flags}

## Known Issues
{Known problems shipping with this release}

## Internal Notes
{Anything CS/Support needs to know that isn't in the above}
```

#### Step 5: External — Changelog Generator
**Template:** `changelog.md` (appended per version)

```markdown
## [{version}] - {date}

### Added
- {new feature descriptions in user-facing language}

### Changed
- {modifications to existing behavior}

### Deprecated
- {features marked for future removal}

### Removed
- {features removed in this version}

### Fixed
- {bug fixes in user-facing language}

### Security
- {security-related fixes}
```

Generated from git history. Groups commits by type (conventional commits) or by semantic analysis of commit messages. Translates engineering language to user-facing language.

#### Step 6: Marketing — Feature Brief Generator
**Template:** `fb-{NNN}-{feature-slug}.md`

```markdown
---
id: fb-{NNN}
type: feature-brief
audience: marketing
topic: {feature-name}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 0.1.0
---

# Feature Brief: {Feature Name}

## One-Liner
{Single sentence: what it is and why it matters}

## What It Is
{2-3 sentences explaining the feature in non-technical language}

## Who It's For
{Target personas/segments — who benefits most}

## The Problem It Solves
{Pain point this addresses — in the customer's language}

## Key Benefits
- {Benefit 1 — outcome-focused, not feature-focused}
- {Benefit 2}
- {Benefit 3}

## How It Works (Simplified)
{Non-technical explanation of the mechanism — enough for marketing to understand}

## Competitive Context
{How this compares to alternatives — only if context files provide competitive info}

## Proof Points
{Metrics, benchmarks, or evidence of value — if available from context}

## Suggested Messaging
{2-3 key messages marketing can use in announcements, landing pages, emails}
```

#### Step 7: Marketing — Product Datasheet Generator
**Template:** `datasheet.md`

```markdown
---
id: ds-001
type: datasheet
audience: marketing
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 0.1.0
---

# {Product Name} — Product Datasheet

## Overview
{2-3 sentence product description}

## Key Capabilities
{Bulleted list of major features/capabilities}

## Technical Specifications
- **Language/Runtime:** {from package manifest}
- **Supported Platforms:** {from code/config}
- **Dependencies:** {key dependencies}
- **API:** {REST/GraphQL/gRPC — if applicable}

## Integrations
{List of supported integrations, derived from code}

## Deployment Options
{How it can be deployed — Docker, cloud, self-hosted, etc.}

## Security & Compliance
{Security features, encryption, auth methods, compliance certs — if available}

## System Requirements
{Minimum requirements — from docs or config}
```

#### Step 8: Output Writer
- Write generated docs to `docs/generated/` following the directory structure
- Store summaries in Memories under `hermes/{project}/{audience}` prefixes
- Update `.hermes.md` with generation state:
  ```
  Last generated: {timestamp}
  Source tier: {tier}
  Documents generated: {count by type}
  Mode: {full|update}
  Version: {if release-scoped}
  ```

#### Step 9: Index Generator
**File:** `docs/generated/index.md`

Auto-generated master index listing all generated docs with metadata:
```markdown
# Hermes Documentation Index

Generated: {timestamp} | Source: {tier} | Hermes v0.1.0

## Internal ({count} docs)
| ID | Type | Topic | Generated |
|----|------|-------|-----------|
| fh-001 | Feature Handoff | Auth System | 2026-02-28 |

## External ({count} docs)
| ID | Type | Topic | Generated |
|----|------|-------|-----------|
| changelog | Changelog | All | 2026-02-28 |

## Marketing ({count} docs)
| ID | Type | Topic | Generated |
|----|------|-------|-----------|
| fb-001 | Feature Brief | Auth System | 2026-02-28 |
```

#### Step 10: Conductor Integration
Add Hermes to conductor's pipeline vocabulary:

```yaml
skills:
  hermes:
    source: external
    phase: communicate
    type: phase

pipelines:
  feature:
    phases: [explore, plan, build, verify, communicate, review, finish]
    skills:
      communicate:
        - hermes
```

### Phase 2: Depth (v0.2.0) — Planned
- Use Case Docs (internal)
- Internal FAQ (internal)
- API Reference (external)
- Feature Docs (external)
- Release Announcement (marketing)

### Phase 3: Completeness (v0.3.0) — Planned
- Troubleshooting Guide (internal)
- Glossary (internal)
- Getting Started (external)
- Config Reference (external)
- Error Reference (external)
- Migration Guide (external)
- Sales One-Pager (marketing)

### Phase 4: Product (v1.0.0) — Planned
- Web UI for non-dev browsing
- CI/CD auto-generation hook
- Doc diff view
- Review workflow
