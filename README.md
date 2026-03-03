# Kalos

Format-agnostic design governance tool. Define design tokens and rules once, enforce them across Pencil, Tailwind, CSS, and more.

Greek: *kalos* (καλός) — beautiful, noble, fine.

## What It Does

Kalos is the design counterpart to [Apollo](https://github.com/divyekant/apollo). Apollo governs dev conventions; Kalos governs design conventions.

- **Define** design tokens (colors, typography, spacing, radii) in YAML config
- **Inject** design rules into agent instruction files (CLAUDE.md, .cursorrules, etc.)
- **Sync** tokens to design tools (Pencil variables, Tailwind config)
- **Validate** design artifacts against declared rules

## Quick Start

```bash
# Clone into your skills directory
git clone https://github.com/divyekant/kalos ~/.claude/skills/kalos

# Initialize in any project
/kalos init
```

## Commands

| Command | Purpose |
|---------|---------|
| `/kalos init` | Set up design tokens and rules for a project |
| `/kalos check` | Validate design artifacts against rules |
| `/kalos sync` | Push tokens to adapters (Pencil, Tailwind) |
| `/kalos extract` | Bootstrap config from existing design artifacts |
| `/kalos` | Context-aware guidance |

## Config

Three-tier resolution: `~/.kalos/defaults.yaml` → templates → `.kalos.yaml` (project).

```yaml
# .kalos.yaml
extends: modern

tokens:
  colors:
    primary: "#6366F1"
    secondary: "#EC4899"
  typography:
    font_family: "Inter, system-ui, sans-serif"
    scale: "1.25"
    base_size: 16
  spacing:
    base: 4

rules:
  colors:
    max_unique: 12
    require_semantic: true
  accessibility:
    min_contrast: 4.5

adapters:
  - pencil
  - tailwind
```

## Brands

Optional multi-brand support for projects with multiple palettes:

```yaml
brands:
  active: "acme"
  palettes:
    acme:
      colors:
        primary: "#1E40AF"
        secondary: "#7C3AED"
      typography:
        font_family: "Helvetica Neue, sans-serif"
    partner-co:
      colors:
        primary: "#DC2626"
        secondary: "#F59E0B"
```

Switch brands: "switch to partner-co" or `/kalos sync --brand partner-co`.

## Adapters

| Adapter | Sync | Validate | Status |
|---------|------|----------|--------|
| Pencil | Push tokens as Pencil variables | Scan .pen files via MCP | v0.1.0 |
| Tailwind | Generate config + CSS vars | Config-only validation, stale detection | ✓ v0.2.0 |
| Figma | — | — | Planned |

## License

MIT
