---
id: ra-v1.0.0
type: release-announcement
audience: marketing
version: 1.0.0
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Hermes v1.0.0: One Codebase, Three Audiences, Zero Translation Tax

## The Headline

Hermes generates documentation for CS, developers, and marketing from a single codebase — so every team understands what was built the moment it ships.

## What's New

### Multi-Audience Documentation Generation

Every feature you ship now produces three sets of documentation automatically: detailed handoffs for your support team (how it works, edge cases, troubleshooting), user-facing guides for developers (how to use it, examples, configuration), and benefit-focused briefs for marketing (what it is, who cares, messaging).

**Key benefit:** CS can answer customer questions about new features without asking engineering. Marketing has feature briefs within minutes, not days.

### Tiered Input Resolution

Hermes works on any project without setup. It reads your code, README, and git history to understand what needs documenting. Projects with Carto indexing get even richer docs, but setup is never required to get started.

**Key benefit:** Useful documentation from the first run, with quality that scales as you invest more context.

### Five Operational Modes

Generate full project docs, update only what changed, or target a specific audience. Natural language invocation — no flags, no config files.

**Key benefit:** Run it once for everything, or surgically generate just what you need.

### State Tracking & Resume

Large projects can take multiple sessions to document fully. Hermes tracks progress and resumes where it left off if interrupted. Update mode uses the same state to generate deltas efficiently.

**Key benefit:** Never redo completed work. Pick up where you left off.

### 17 Document Templates

A complete template library covering every document type your teams need: Feature Handoffs, Use Cases, Troubleshooting Guides, Release Notes, FAQ, Glossary, Feature Docs, Getting Started, API Reference, Config Reference, Error Reference, Changelog, Migration Guides, Feature Briefs, Release Announcements, Product Datasheets, and Sales One-Pagers.

**Key benefit:** Consistent, structured documentation across every feature and every audience.

## Improvements

- Single-file skill design — no dependencies, no build step, no installation
- Conductor integration — Hermes runs as the "communicate" phase in development pipelines
- YAML frontmatter on every document for programmatic consumption and tracking

## Getting Started

- **New users:** Add Hermes to your project and say "Generate docs for this project" in a Claude Code session. See the [Getting Started guide](../external/getting-started.md).
- **Existing Carto users:** Hermes automatically detects your Carto index for richer documentation.

## What's Next

We are working on CI/CD integration for automatic doc generation on merge, a web UI for non-developer teams to browse generated docs, and a doc diff view that shows what changed between generations.
