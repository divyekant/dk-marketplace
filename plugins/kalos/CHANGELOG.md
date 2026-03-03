# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-03

### Added
- `/kalos sync` Tailwind adapter — generates `kalos.tailwind.config.ts` + `kalos-tokens.css`
- `/kalos check` Tailwind adapter — config-only validation, stale file detection
- `/kalos extract` — bootstrap `.kalos.yaml` from existing Pencil/Tailwind/CSS artifacts
- `brand` template — strict enforcement (6 colors, 1 font, WCAG AAA)
- Multi-brand support — `brands:` config section with named palettes
- Brand switching — change active brand and re-sync all adapters
- Brand-aware onboarding — `/kalos init` asks about multi-brand setup
- Brand-aware instruction injection — CLAUDE.md shows active brand
- Brand-aware session-start hook — status line shows active brand
- Brand palette consistency validation

### Changed
- Config schema — added `brands:` top-level key with palette structure
- `/kalos init` — new questions for brand setup, tailwind in adapter options
- `/kalos check` — runs both Pencil and Tailwind adapters
- `/kalos sync` — runs both adapters, generates per-brand CSS vars
- `/kalos` (bare) — expanded detection for extract, tailwind, staleness
- Templates — `modern` and `minimal` now include tailwind adapter

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
