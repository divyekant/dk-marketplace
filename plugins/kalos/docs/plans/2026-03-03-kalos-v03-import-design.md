# Kalos v0.3.0 Design — /kalos import (Code-to-Design)

**Date:** 2026-03-03
**Status:** Approved
**Approach:** B — Staged pipeline with checkpoints

---

## Problem

Kalos v0.2.0 can extract tokens from adapter artifacts (Pencil, Tailwind, CSS files) and govern them going forward. But real projects also need to bootstrap design assets from existing source code and live applications. Without this, adopting Kalos on a brownfield project requires manually recreating the current UI state.

## Solution

Add `/kalos import <source>` — a staged pipeline that reads source code files or live app URLs, discovers UI structure and tokens, optionally reconstructs editable components via adapters, and integrates discovered tokens into Kalos config.

---

## Input Detection

`/kalos import <source>` accepts two input types:

### Code Files (path or glob)
- `/kalos import src/components/` — reads .tsx/.vue/.html/.css/.svelte files
- Parses component structure, extracts inline styles, Tailwind classes, CSS modules
- Uses Glob + Read tools — no external dependencies

### Live URL
- `/kalos import https://myapp.com/dashboard`
- **Primary**: Chrome MCP (`claude-in-chrome`) — reads DOM, accessibility tree, computed styles, takes screenshot
- **Fallback**: If Chrome MCP unavailable, use Puppeteer/Playwright via Bash to capture screenshot + extract DOM

**Detection logic:** If source starts with `http`/`https` → URL mode. Otherwise → code file mode (resolve as path/glob).

---

## Stage 1: Discover

Parse inputs and extract raw design data into a structured **UI Model** — an adapter-agnostic intermediate representation.

### From Code Files

- Component boundaries (function/class components, template blocks)
- Color values (hex, rgb, CSS vars, Tailwind color classes)
- Typography (font-family, font-size, font-weight, line-height)
- Spacing (margin, padding, gap — raw values + Tailwind spacing classes)
- Border radii
- Layout structure (flex/grid, direction, alignment, nesting)
- Component variants (conditional classes, props that change appearance)

### From Live URLs

- DOM tree + computed styles (via Chrome MCP or headless browser)
- Screenshot for Claude vision analysis (catches visual details the DOM might miss)
- Accessibility tree (component roles, labels, hierarchy)

### UI Model Structure

Internal, held in memory — not persisted as a file:

```yaml
pages:
  - url: "https://myapp.com/dashboard"
    components:
      - name: "Sidebar"
        type: frame
        layout: { direction: vertical, gap: 8 }
        children: [...]
      - name: "StatsCard"
        type: frame
        variants: [default, highlighted]
        styles: { fill: "#F8FAFC", radius: 12, padding: 16 }
tokens:
  colors: ["#6366F1", "#EC4899", "#22C55E", ...]
  fonts: ["Inter", "system-ui"]
  spacing: [4, 8, 12, 16, 24, 32]
  radii: [0, 4, 8, 12, 9999]
```

---

## Stage 2: Audit (Checkpoint 1)

Present findings to the user and pause for confirmation.

### Output

```
Kalos Import — Audit
Source: src/components/ (47 files)

Tokens Discovered:
  Colors: #6366F1 (34 uses), #EC4899 (21 uses), #22C55E (12 uses),
          #F59E0B (8 uses), #EF4444 (6 uses), #3B82F6 (4 uses)
  Fonts: Inter (primary, 41 uses), system-ui (fallback)
  Spacing: base appears to be 4px (values: 4, 8, 12, 16, 24, 32, 48)
  Radii: 0, 4, 8, 12, 9999

Components Found: 23
  Layout: Sidebar, Header, MainContent, Footer
  Data Display: StatsCard (2 variants), DataTable, Chart
  Forms: InputField, SelectBox, Button (3 variants), Checkbox
  Navigation: NavItem, Breadcrumb, TabBar
  Feedback: Toast, Modal, Badge (4 variants)

Potential Issues:
  [WARN] 3 colors not mappable to semantic tokens (#D1D5DB, #F3F4F6, #1F2937)
  [WARN] Font size 13px not on standard type scale
  [INFO] 2 components have inline styles instead of classes
```

### User Choices

1. **Continue to Reconstruct** — proceed to generate components via adapters
2. **Adjust** — correct component names, merge variants, remove false positives
3. **Stop here** — take the token audit, skip reconstruction
4. **Feed into Kalos** — jump to Integrate stage with discovered tokens

Options 3 and 4 are exit ramps. Options 1 and 2 continue the pipeline.

---

## Stage 3: Reconstruct

Generate editable components from the UI Model via enabled adapters.

### Adapter-Agnostic

The Reconstruct stage runs through whatever adapters are enabled in `.kalos.yaml`:
- `adapters: [pencil]` → generates .pen file with reusable components
- `adapters: [tailwind]` → generates Tailwind component files + CSS
- `adapters: [pencil, tailwind]` → both
- No adapters → skip reconstruction, audit report only

### Pencil Adapter Reconstruct

1. Check Pencil MCP via `mcp__pencil__get_editor_state`
2. Create .pen file — default: `docs/designs/import-<source-name>.pen`
3. Get style guide via `mcp__pencil__get_style_guide_tags` + `mcp__pencil__get_guidelines`
4. Generate components in order:
   - **Tokens** — set variables via `mcp__pencil__set_variables`
   - **Atoms** — smallest components (Button, Badge, InputField) as reusable
   - **Molecules** — composed (StatsCard, NavItem with icon + label)
   - **Organisms** — larger sections (Sidebar, Header, DataTable)
   - **Pages** — full layout compositions using instances
5. Handle variants — separate reusable components or Pencil variable system
6. Screenshot verification — compare against original using Claude vision

### Tailwind Adapter Reconstruct

1. Generate component files matching discovered structure
2. Use Kalos token CSS variables (`var(--kalos-color-primary)`, etc.)
3. Map discovered spacing/radii to Tailwind classes

### Output

```
Kalos Import — Reconstruct
Generated: docs/designs/import-dashboard.pen

Components: 23 (12 reusable, 11 instances)
  Atoms: Button (3 variants), Badge (4), InputField, Checkbox, SelectBox
  Molecules: StatsCard (2), NavItem, Breadcrumb
  Organisms: Sidebar, Header, DataTable, TabBar
  Pages: Dashboard (full layout)

Variables set: 6 colors, 2 fonts, 7 spacing, 5 radii

Visual match: ~85% (minor spacing differences in DataTable)
```

---

## Stage 4: Integrate (Checkpoint 2)

After Reconstruct (or after Audit if user stopped early), offer Kalos integration.

### Options

```
Kalos Import — Integration

1. Create new .kalos.yaml — bootstrap full config from discovered tokens
2. Add as brand palette — add discovered tokens as a new brand in existing config
3. Update existing config — merge discovered tokens into current .kalos.yaml
4. Skip — keep the audit report and generated files, no config changes
```

### Option 1: New Config

Same flow as `/kalos extract`. Write `.kalos.yaml` with discovered tokens, suggest closest template, run Instruction Injection.

### Option 2: Add as Brand

Ask for brand name. Add palette under `brands.palettes` with discovered colors + font. If `brands:` section doesn't exist yet, create it with current tokens as "default" and imported tokens as the new brand.

### Option 3: Update Existing

Deep merge discovered tokens into current config. Show diff before writing: "These values will change: primary #6366F1 → #4F46E5. Confirm?"

### Option 4: Skip

No config changes. User still has the audit report and any generated adapter files.

After integration (or skip), run `/kalos sync` if adapters are enabled to push updated tokens.

---

## Relationship to /kalos extract

- `/kalos extract` = read from **adapter artifacts** (tailwind.config, .pen files, CSS vars) → bootstrap config
- `/kalos import` = read from **source code or live URLs** → full pipeline (audit + reconstruct + config)

No overlap. Extract reads what adapters already produced. Import reads the original source.

---

## What Ships in v0.3.0

### New
- `/kalos import <source>` — staged pipeline: Discover → Audit → Reconstruct → Integrate
- Code file input — parses .tsx/.vue/.html/.css/.svelte for components, tokens, layout
- URL input — Chrome MCP primary, headless browser fallback (Puppeteer/Playwright)
- UI Model — adapter-agnostic intermediate representation of components + tokens
- Audit checkpoint — token report + component inventory, usable standalone
- Reconstruct via adapters — each enabled adapter generates components in its format
- Brand palette import — add discovered tokens as new brand in existing config
- Visual verification — screenshot comparison for URL imports
- Headless capture script — `bin/capture.sh` for Puppeteer/Playwright fallback

### Updated
- SKILL.md — new import section, updated routing table, updated argument_hint
- Config schema — no changes needed (import writes to existing brands/tokens structure)

### Not in Scope
- Figma adapter for reconstruct
- Auto-detecting multi-brand themes from code (needs CSS selector analysis)
- Component diff ("what changed since last import")
- Design-to-code direction (existing Pencil-prototyping + Tailwind domain)

---

## File Changes

```
~/Projects/kalos/
├── skills/
│   └── kalos/
│       └── SKILL.md                 # Updated: import section, routing, argument_hint
├── bin/
│   └── capture.sh                   # NEW: headless browser fallback script
├── test/
│   └── capture.bats                 # NEW: tests for capture script
├── docs/
│   └── plans/
│       └── 2026-03-03-kalos-v03-import-design.md  # This doc
├── CHANGELOG.md                     # Updated
├── README.md                        # Updated
└── .claude-plugin/
    └── plugin.json                  # Updated: version 0.3.0
```
