---
id: ds-001
type: datasheet
audience: marketing
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Hermes — Product Datasheet

## Overview

Hermes is an AI-powered documentation generation skill that translates codebases into audience-specific documentation for three distinct groups: internal teams (CS/Support), external users (developers), and marketing (product marketing/sales). It operates as a Claude Code skill, requiring no installation, no dependencies, and no configuration to produce structured, reviewable documentation from any project.

## Key Capabilities

### Documentation Generation
- **Multi-audience output:** Generates internal, external, and marketing docs from a single source
- **17 document templates:** Feature Handoffs, Use Cases, Troubleshooting Guides, Release Notes, FAQ, Glossary, Feature Docs, Getting Started, API Reference, Config Reference, Error Reference, Changelog, Migration Guides, Feature Briefs, Release Announcements, Product Datasheets, Sales One-Pagers
- **Audience-specific voice:** Internal (practical/scenario-driven), External (clear/second-person), Marketing (benefit-focused)

### Input Intelligence
- **Tiered input resolution:** Automatically uses the best available source — Carto index, direct codebase, or context files
- **Context layering:** Business documents (PRDs, design docs, competitive analyses) layer on top of code analysis for richer output
- **Feature discovery:** Identifies documentable features from project structure or Carto zones

### Operational Modes
- **Generate:** Full project documentation for all audiences
- **Update:** Incremental delta generation from git history
- **Single-audience:** Target internal, external, or marketing independently

### Reliability
- **State tracking:** Disk-based `.hermes.md` tracks generation progress
- **Resume capability:** Interrupted runs resume from the last completed audience
- **Change detection:** Maps git commits to features for surgical updates

## Technical Specifications

| Spec | Value |
|------|-------|
| Language/Runtime | Markdown-based skill (no runtime required) |
| Supported Platforms | Any platform that runs Claude Code |
| Interface | Natural language invocation within Claude Code |
| Output Format | Markdown with YAML frontmatter |
| State Management | Disk-based (.hermes.md) |
| Version Control Integration | Git (for changelog, release notes, change detection) |

## Dependencies

| Dependency | Version | Purpose |
|-----------|---------|---------|
| Claude Code | Latest | Runtime environment |
| Memories MCP | Any | Carto index storage (optional, for Tier 1 input) |
| Git | Any | Changelog generation, change detection |

## Integrations

- **Carto:** Consumes Carto code indexes for Tier 1 input quality
- **Conductor:** Runs as the "communicate" phase in Conductor development pipelines
- **Apollo:** Reads `.apollo.yaml` project configuration as context
- **Memories MCP:** Stores doc summaries for AI-searchable access

## Deployment Options

- **Project-local:** Copy `skills/hermes/skill.md` into your project's `skills/` directory
- **Shared ecosystem:** Make Hermes available across projects through a shared skills directory
- **Conductor pipeline:** Integrate as a phase in Conductor-orchestrated workflows

## Security & Compliance

- No network access required — operates entirely on local files and optionally Memories MCP
- No credentials or API keys needed
- No data leaves the local machine (unless Memories MCP is configured with remote storage)
- All output is reviewable markdown — no opaque formats or binary output

## System Requirements

| Requirement | Minimum |
|------------|---------|
| Claude Code | Latest version |
| Disk space | ~1MB per documented project (generated markdown files) |
| Git | Recommended (for changelog and change detection features) |
| Carto | Optional (for Tier 1 input quality) |
