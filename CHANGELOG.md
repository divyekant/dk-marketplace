# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-03

### Added
- `/kalos init` — interactive design token onboarding
- `/kalos check` — Pencil adapter validation (colors, typography, spacing, radii, contrast)
- `/kalos sync` — push tokens to Pencil variables via MCP
- `/kalos` (bare) — context-aware guidance
- Session-start hook with drift detection
- Config templates: modern, minimal
- 3-tier config resolution (global → template → project)
- Instruction injection into CLAUDE.md with KALOS markers
- Plugin packaging for dk-marketplace
