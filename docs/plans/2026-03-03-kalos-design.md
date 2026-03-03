# Kalos Design — Design Governance Tool

**Date:** 2026-03-03
**Status:** Approved
**Approach:** B — Apollo governance pattern + active design validation

---

## Problem

Design standards are invisible during development. Teams define color palettes, typography scales, and spacing rules, but nothing enforces them when code or designs are produced. Apollo solves this for dev conventions — Kalos does the same for design conventions.

## Solution

Kalos is a format-agnostic design governance tool. It defines design tokens and rules in YAML config (3-tier resolution), injects them as instructions into agent files, and actively validates design artifacts through adapters.

**Core identity:** Governance tier (sibling to Apollo), not indexing tier (Carto) or creation tier (Pencil-prototyping).

## Architecture

### Config Schema

3-tier resolution: `~/.kalos/defaults.yaml` → `~/.kalos/templates/<name>.yaml` → `.kalos.yaml` (project root). Deep merge at each level.

```yaml
# .kalos.yaml
extends: modern

tokens:
  colors:
    primary: "#6366F1"
    secondary: "#EC4899"
    neutral: "zinc"
    semantic:
      success: "#22C55E"
      warning: "#F59E0B"
      error: "#EF4444"
  typography:
    font_family: "Inter, system-ui, sans-serif"
    scale: "1.25"         # major third type scale
    base_size: 16
  spacing:
    base: 4               # 4px base unit
    scale: [0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32]
  radii:
    none: 0
    sm: 4
    md: 8
    lg: 12
    full: 9999

rules:
  colors:
    max_unique: 12
    require_semantic: true
  typography:
    max_font_families: 2
    require_scale: true
  spacing:
    require_base_unit: true
  components:
    naming: "PascalCase"
    require_variants: false
  accessibility:
    min_contrast: 4.5     # WCAG AA
    require_alt_text: true

adapters:
  - pencil
  - tailwind
```

### Skill Subcommands

| Command | Purpose |
|---------|---------|
| `/kalos init` | Interactive onboarding — color, typography, spacing preferences. Creates `.kalos.yaml`, injects CLAUDE.md |
| `/kalos check` | Active validation — scans design artifacts via adapters, reports violations |
| `/kalos sync` | Push tokens to adapters — Pencil variables, Tailwind config, CSS custom properties |
| `/kalos` (bare) | Context-aware — no config? suggest init. Drifted? re-inject. Unchecked? suggest check |

### Instruction Injection

Same marker pattern as Apollo, separate markers:

```markdown
<!-- KALOS:START - Do not edit this section manually -->
## Design Standards (managed by Kalos)
- Primary color: #6366F1, Secondary: #EC4899
- Font: Inter, scale: 1.25 major third from 16px base
- Spacing: 4px base unit, only use multiples
- Max 12 unique colors, all must map to design tokens
- Min contrast ratio: 4.5 (WCAG AA)
- Component naming: PascalCase
<!-- KALOS:END -->
```

Writes to same agent files as Apollo (CLAUDE.md, .cursor/rules/, AGENTS.md, etc.) using agent-specific formats.

### Adapter Architecture

Each adapter implements two capabilities:

- **sync(config)** — push tokens to target format
- **validate(config)** — scan artifacts, return violations

```
Kalos Core (config resolution + rule engine)
    │
    ├── Adapter: Pencil
    │   ├── sync: set_variables() → push tokens as Pencil theme variables
    │   ├── validate: batch_get() + search_all_unique_properties() → compare against rules
    │   └── reads: .pen files via MCP
    │
    ├── Adapter: Tailwind
    │   ├── sync: generate tailwind.config.ts theme + CSS custom properties
    │   ├── validate: parse tailwind.config + scan for hardcoded values
    │   └── reads: tailwind.config.ts, globals.css, source files
    │
    └── (future: Figma, vanilla CSS)
```

### Lifecycle Integration

**Session-start hook:**
- Checks for `.kalos.yaml` in project root
- Verifies KALOS section in CLAUDE.md (drift detection)
- Returns status line: `Kalos: modern template | 2 adapters | last check: 2h ago`
- Silently re-injects if drifted

**Conductor pipeline:**
```yaml
skills:
  kalos:
    source: external
    phase: shape
    type: phase

always-available:
  - kalos
```

Wired into shape phase alongside pencil-prototyping. Also always-available for ad-hoc `/kalos check`.

### Relationship to Ecosystem

| Tool | Relationship |
|------|-------------|
| Apollo | Sibling — dev conventions vs design conventions. Separate YAML, separate markers, same pattern |
| Pencil-prototyping | Downstream — Pencil creates designs, Kalos validates and syncs tokens to them |
| Carto | Parallel — lightweight. Kalos could feed design metadata to Memories for cross-tool queries |
| Delphi | Future consumer — accessibility rules for test scenarios |

## What Ships in v0.1.0

**In scope:**
- `/kalos init` — interactive onboarding, writes `.kalos.yaml`, injects CLAUDE.md
- `/kalos check` — Pencil adapter validation (scan .pen files via MCP)
- `/kalos sync` — Pencil adapter sync (push tokens to Pencil variables)
- `/kalos` (bare) — context-aware guidance
- Session-start hook with drift detection
- 2 templates: `modern` and `minimal`
- Plugin packaging for dk-marketplace

**Deferred to v0.2.0:**
- Tailwind adapter (sync + validate)
- `extract` capability (bootstrap config from existing project)
- Auto-fix via `replace_all_matching_properties`

**Deferred to v0.3.0+:**
- Figma adapter
- Memories integration for check results
- Delphi accessibility rule handoff

## File Structure

```
~/Projects/kalos/
├── .kalos.yaml
├── .apollo.yaml
├── CLAUDE.md
├── README.md
├── CHANGELOG.md
├── skills/
│   └── kalos/
│       └── SKILL.md
├── hooks/
│   └── session-start.sh
├── config/
│   ├── defaults.example.yaml
│   └── templates/
│       ├── modern.yaml
│       └── minimal.yaml
├── docs/
│   └── plans/
└── .claude-plugin/
    └── plugin.json
```

## Testing

- Session-start hook tested with bats
- Config resolution tested manually via skill
- Adapter validation tested against known .pen files
