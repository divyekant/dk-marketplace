---
type: changelog
audience: external
generated: 2026-02-28
hermes-version: 1.0.0
---

# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-02-28

### Added
- Multi-audience documentation generation from a single codebase — generates internal, external, and marketing docs simultaneously
- Tiered input resolution: automatically uses the best available source (Carto index, direct codebase reading, or context files)
- Five operational modes: Generate (full project), Update (incremental delta), Internal-only, External-only, and Marketing-only
- State tracking via `.hermes.md` state file for resume capability and incremental updates
- 17 structured document templates with YAML frontmatter:
  - Internal (6): Feature Handoff, Use Case, Troubleshooting Guide, Release Notes, FAQ, Glossary
  - External (7): Feature Docs, Getting Started, API Reference, Config Reference, Error Reference, Changelog, Migration Guide
  - Marketing (4): Feature Brief, Release Announcement, Product Datasheet, Sales One-Pager
- Feature discovery that identifies documentable features from project structure or Carto zones
- Resume protocol for interrupted generation runs — picks up from the last completed audience
- Conductor integration as a "communicate" pipeline phase
- Auto-discovery of context files from `docs/plans/`, `docs/decisions/`, and project root
- Master index generation (`docs/generated/index.md`) linking all generated documents
