# DK Plugins Marketplace

A Claude Code plugin marketplace with tools for testing, documentation, project management, lateral thinking, and more.

## Installation

```bash
claude plugins marketplace add divyekant/dk-marketplace
```

## Available Plugins

| Plugin | Category | Description |
|--------|----------|------------|
| **apollo** | development | Agent-agnostic project lifecycle manager — encodes dev preferences into YAML config and syncs rules across agents |
| **argos** | development | The All-Seeing Issue Guardian — watches GitHub repos and acts on issues within configurable boundaries |
| **carto** | development | Intent-aware codebase intelligence — scans codebases, builds layered semantic index, produces skill files for instant AI agent context |
| **claude-code-restart** | utilities | Self-restart mechanism for Claude Code — adds /restart slash command and shell wrapper |
| **delphi** | testing | Comprehensive test scenario generator and executor — covers positive, negative, edge, accessibility, and security paths |
| **hermes** | documentation | Audience-specific documentation generator — internal (CS/Support), external (users/developers), and marketing (sales/PMM) docs |
| **kalos** | design | Format-agnostic design governance tool — define design tokens and rules, enforce them across Pencil, Tailwind, and more |
| **learning-skill** | development | Captures learnings from failures and fixes during Claude Code sessions |
| **pencil-prototyping** | design | Launch Pencil.dev on demand and prototype visuals on a canvas — handles install, launch, MCP connection, and screenshot capture |
| **pheme** | utilities | Universal communication layer — agents notify humans across any channel |
| **skill-conductor** | development | Skill composition framework — classifies tasks, selects pipelines, and sequences skills through phases |
| **think-different** | development | On-demand lateral thinking mode — applies 15 thinking frameworks to reframe problems |
| **ui-val** | testing | Visual UI validation using multimodal vision — captures screenshots at multiple viewports and evaluates against a 12-point rubric |
| **update-checker** | utilities | Checks for updates to installed CC plugins, MCP servers, and hooks — runs automatically on session start and via /check-updates |

## Installing a Plugin

After adding this marketplace:

```bash
claude plugins install update-checker
claude plugins install apollo
# etc.
```

## License

MIT
