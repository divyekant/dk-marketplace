---
id: fh-005
type: feature-handoff
audience: internal
topic: template-system
status: draft
generated: 2026-02-28
source-tier: direct
context-files: [skills/hermes/skill.md, docs/plans/2026-02-28-hermes-design.md]
hermes-version: 1.0.0
---

# Feature Handoff: Template System

## What It Does

Hermes defines 17 structured document templates across three audiences. Each template specifies the exact sections, voice guidelines, frontmatter schema, and generation rules for a document type. Templates ensure consistency across all generated docs and provide programmatic metadata via YAML frontmatter for downstream tooling.

The template system is embedded directly in the skill file (`skills/hermes/skill.md`), not in separate template files. This keeps the entire skill portable as a single document.

## How It Works

Each template defines:

1. **YAML frontmatter schema** — required fields like `id`, `type`, `audience`, `topic`, `status`, `generated`, `source-tier`, `hermes-version`
2. **Section structure** — the exact markdown headings and their expected content
3. **Voice guidelines** — audience-specific tone and perspective
4. **Generation rules** — specific instructions for how to populate each template from source material

**Templates by audience:**

| Audience | Doc Type | Template ID | Per-Feature? |
|----------|----------|-------------|-------------|
| Internal | Feature Handoff | fh-{NNN} | Yes |
| Internal | Use Case | uc-{NNN} | Yes |
| Internal | Troubleshooting | ts-{NNN} | Yes |
| Internal | Release Notes | rn-v{version} | No (per-version) |
| Internal | FAQ | faq | No (cross-feature) |
| Internal | Glossary | glossary | No (cross-feature) |
| External | Feature Docs | feat-{NNN} | Yes |
| External | Getting Started | getting-started | No (per-project) |
| External | API Reference | api-reference | No (per-project) |
| External | Config Reference | config-reference | No (per-project) |
| External | Error Reference | error-reference | No (per-project) |
| External | Changelog | changelog | No (per-project) |
| External | Migration Guide | v{from}-to-v{to} | No (per-version-pair) |
| Marketing | Feature Brief | fb-{NNN} | Yes |
| Marketing | Release Announcement | ra-v{version} | No (per-version) |
| Marketing | Product Datasheet | ds-001 | No (per-project) |
| Marketing | Sales One-Pager | op-{NNN} | Yes |

**Voice guidelines:**
- **Internal:** Practical, scenario-driven. "When a user does X, the system does Y." Written for CS agents and support engineers.
- **External:** Clear, second-person. "You can...", "To configure X, do Y." Written for developers and end users.
- **Marketing:** Value-driven, benefit-first. "Now you can Y — here's why that matters." Written for product marketers and sales teams.

**Frontmatter serves dual purposes:**
- Human-readable metadata at the top of every doc
- Machine-parseable data for indexing, filtering, and tracking generation lineage

## User-Facing Behavior

Users do not interact with templates directly. Templates are internal to the Hermes skill. Users see the output — structured docs that follow consistent patterns across every feature and audience.

The frontmatter is visible at the top of every generated file:
```yaml
---
id: fh-001
type: feature-handoff
audience: internal
topic: user-authentication
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---
```

## Configuration

Templates are not configurable. They are embedded in the skill file and follow a fixed structure. Customizing templates requires editing `skills/hermes/skill.md`.

## Edge Cases & Limitations

- **Templates cannot be extended per-project** — There is no mechanism to add custom sections to a template for a specific project. All projects use the same template structure.
- **Marketing docs depend on business context** — Templates like Feature Brief and Sales One-Pager have sections (Competitive Context, Proof Points) that require context files. Without them, these sections contain placeholder text indicating what context is needed.
- **No HTML or rich formatting** — Templates produce markdown only. Rich formatting (tables with images, embedded videos, interactive elements) is not supported.

## Common Questions

**Q: Can I add a new doc type?**
A: Not through configuration. New doc types require editing the skill file (`skills/hermes/skill.md`) to add a new template and generation rules.

**Q: Why is everything in one file?**
A: Hermes follows the single-file skill pattern (same as Delphi). This makes the skill portable — it can be copied to any project as a single markdown file with no dependencies.

**Q: Can I change the voice for a specific audience?**
A: Not per-project. Voice guidelines are embedded in the skill. However, the generated docs are drafts — you can edit them after generation.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Generated docs missing expected sections | Template was not followed completely | Check the template definition in `skill.md`; sections may have been skipped if source data was insufficient |
| Frontmatter has `source-tier: context` unexpectedly | Neither Carto nor direct codebase reading produced useful data | Ensure the project has recognizable structure (README, src/, package manifest) |

## Related

- [Multi-Audience Generation](fh-001-multi-audience-generation.md) — how templates are used in the generation pipeline
- [Mode System](fh-003-mode-system.md) — how modes select which templates to use
