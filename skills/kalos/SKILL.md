---
name: kalos
description: >-
  Use when starting a design phase, setting up design tokens, or validating
  design artifacts. Triggers on '/kalos', 'design tokens', 'design standards',
  'design check', or 'design rules'.
argument_hint: "[init|check|sync|extract|import]"
allowed_tools:
  - mcp__pencil__batch_get
  - mcp__pencil__search_all_unique_properties
  - mcp__pencil__replace_all_matching_properties
  - mcp__pencil__get_variables
  - mcp__pencil__set_variables
  - mcp__pencil__get_editor_state
  - mcp__pencil__get_screenshot
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - mcp__claude-in-chrome__read_page
  - mcp__claude-in-chrome__computer
  - mcp__claude-in-chrome__get_page_text
  - mcp__claude-in-chrome__javascript_tool
  - mcp__claude-in-chrome__tabs_context_mcp
  - mcp__claude-in-chrome__tabs_create_mcp
  - mcp__claude-in-chrome__navigate
  - mcp__claude-in-chrome__find
  - mcp__pencil__batch_design
  - mcp__pencil__get_guidelines
  - mcp__pencil__get_style_guide_tags
  - mcp__pencil__get_style_guide
  - mcp__pencil__find_empty_space_on_canvas
  - mcp__pencil__snapshot_layout
  - mcp__pencil__open_document
---

# Kalos — Design Governance

Format-agnostic design governance tool. Define design tokens and rules once,
enforce them across Pencil, Tailwind, CSS, and more.

## Sub-Command Routing

Detect the user's intent:

| User says | Route to |
|-----------|----------|
| `/kalos init` or "set up design tokens" or "design standards" | **Init** section |
| `/kalos check` or "check design" or "validate design" | **Check** section |
| `/kalos sync` or "sync tokens" or "push tokens" | **Sync** section |
| `/kalos extract` or "bootstrap tokens" | **Extract** section |
| `/kalos import` or "import design" or "code to design" or "reverse engineer" | **Import** section |
| "switch to {brand}" or "switch brand" or `/kalos sync --brand {name}` | **Brand Switching** (below) |
| `/kalos` (bare) or "kalos" | **What Next** section |

## Config Resolution

Kalos uses three-tier config resolution. Later tiers override earlier ones.

**Resolution order:**
1. `~/.kalos/defaults.yaml` — global user preferences
2. `~/.kalos/templates/<name>.yaml` — template overrides (via `extends` key)
3. `.kalos.yaml` (project root) — per-project overrides

**How to resolve:**
1. Read `~/.kalos/defaults.yaml`. This is the base config.
2. If context has an `extends` key, read `~/.kalos/templates/<extends>.yaml`
   and deep merge on top of defaults.
3. If `.kalos.yaml` exists in current working directory, read it and deep merge
   on top. Ignore `extends` and `version` keys during merge.

**Merge strategy:** Deep merge. Nested keys override individually, not entire
objects. Arrays replace (not concatenate).

### Brand Resolution

When the resolved config contains a `brands:` section with an `active` key:

1. Look up `brands.palettes.<active>` — this is the active palette
2. Deep merge the active palette's `colors` on top of `tokens.colors`
3. Deep merge the active palette's `typography` on top of `tokens.typography`
4. The result is the **effective config** used by check, sync, and injection

Any key not specified in the active palette falls back to the base `tokens.*`.
Spacing and radii are never overridden by brands — they are structural.

If `brands:` is absent, skip brand resolution entirely (backward compatible).

## Instruction Injection Procedure

Called by `/kalos init`, `/kalos` (bare, when drift detected), and after any
config change.

### Steps:

1. **Resolve config** using three-tier resolution above.

2. **Generate instructions** from resolved config. Translate each value:

   | Config | Instruction |
   |--------|------------|
   | `tokens.colors.primary` | "Primary: {value}" |
   | `tokens.colors.secondary` | "Secondary: {value}" |
   | `tokens.colors.semantic.*` | "Semantic colors: success={s}, warning={w}, error={e}" |
   | `tokens.typography.font_family` | "Font: {family}" |
   | `tokens.typography.scale` + `base_size` | "Type scale: {ratio} from {base}px base" |
   | `tokens.spacing.base` | "Spacing: {base}px base unit, use multiples only" |
   | `rules.colors.max_unique` | "Max {n} unique colors" |
   | `rules.colors.require_semantic: true` | "All colors must map to design tokens" |
   | `rules.typography.max_font_families` | "Max {n} font families" |
   | `rules.spacing.require_base_unit: true` | "All spacing must be multiples of base unit" |
   | `rules.accessibility.min_contrast` | "Min contrast ratio: {n} (WCAG AA)" |
   | `rules.accessibility.require_alt_text: true` | "Require alt text on all images" |
   | `rules.components.naming` | "Component naming: {convention}" |
   | `brands.active` | "Active brand: {name}" |
   | `brands.palettes` (count) | "{n} brand palettes configured" |

   Only include instructions for config values that are set and meaningful.

3. **Write to the current agent instruction file** using marker-based injection:

   - Claude Code: `CLAUDE.md`
   - Codex: `AGENTS.md`

   ```markdown
   <!-- KALOS:START - Do not edit this section manually -->
   ## Design Standards (managed by Kalos)
   - <instruction 1>
   - <instruction 2>
   <!-- KALOS:END -->
   ```

   Write strategy:
   - If file exists and has KALOS markers: replace content between markers
   - If file exists but no markers: append managed section at end
   - If file doesn't exist: create with managed section only

   **Important:** Never touch content outside the markers. Never touch Apollo's
   `<!-- APOLLO:START -->` section.

---

## /kalos init — Interactive Onboarding

Set up design tokens and rules for the current project.

### First-Run Detection

Before handling init, check if `~/.kalos/defaults.yaml` exists.

If it does NOT exist:
- Say: "Welcome to Kalos! Let's set up your design defaults first."
- Create `~/.kalos/` directory structure:
  ```
  ~/.kalos/
    defaults.yaml
    templates/
      modern.yaml
      minimal.yaml
      brand.yaml
  ```
- Copy template files from this skill's source: `../../config/templates/`
- Copy defaults from: `../../config/defaults.example.yaml`
- Then continue with project-level init below.

### Flow:

Ask questions ONE AT A TIME using AskUserQuestion.

1. **Template choice**
   - "Which design template?"
   - Options: list template names from `~/.kalos/templates/`
     (typically: modern, minimal, brand)
   - This sets the `extends` value

2. **Primary color**
   - "Primary brand color? (hex value or 'use template default')"
   - Show the template default as reference

3. **Secondary color**
   - "Secondary/accent color? (hex value or 'use template default')"

4. **Font family**
   - "Primary font family?"
   - Options: Inter, system-ui, Custom (ask for value)
   - Default from template

5. **Spacing base unit**
   - "Base spacing unit?"
   - Options: 4px (recommended), 8px, Custom
   - Default from template

6. **Adapters**
   - "Which adapters to enable?"
   - Multi-select: Pencil, Tailwind
   - Both recommended if project uses Tailwind

7. **Strictness**
   - "How strict should design rules be?"
   - Options:
     - Relaxed (max 16 colors, contrast 3.0)
     - Standard (max 12 colors, contrast 4.5 WCAG AA) — recommended
     - Strict (max 8 colors, contrast 7.0 WCAG AAA)

8. **Multi-brand?**
   - "Do you need multiple brand palettes?"
   - Options: No (single brand) — recommended, Yes
   - If "No": skip to After Questions

9. **Brand names** (only if multi-brand)
   - "Name your brands (comma-separated, e.g., acme, partner-co)"

10. **Brand colors** (only if multi-brand)
    - For each brand, ask:
      - "Primary color for {brand}? (hex value)"
      - "Secondary color for {brand}? (hex value)"
      - "Font family for {brand}? (or 'use default')"

11. **Active brand** (only if multi-brand)
    - "Which brand should be active by default?"
    - Options: list the brand names entered in Q9

### After questions:

1. Write `.kalos.yaml` to project root with `extends`, `version: 0.2.0`,
   and any overrides from user answers.
   If multi-brand was selected, also write the `brands:` section with palettes and active brand.
2. Run the **Instruction Injection Procedure** to write KALOS section
   to the current agent instruction file
3. Confirm: "Design standards set up. Run `/kalos check` to validate designs,
   `/kalos sync` to push tokens to adapters, or `/kalos extract` to
   bootstrap from existing artifacts."

---

## /kalos check — Validate Design Artifacts

Scan design artifacts against declared rules. Returns a violation report.

### Flow:

1. **Load config** — resolve `.kalos.yaml` using 3-tier resolution.
   If no `.kalos.yaml`: "No Kalos config found. Run `/kalos init` first."

2. **For each enabled adapter**, run validation:

**Brand awareness:** If `brands:` is configured, validate against the
active brand's resolved tokens (after brand resolution), not the base
`tokens.*` values.

#### Pencil Adapter Validation

Only runs if `pencil` is in the `adapters` list AND Pencil MCP tools
are available (check with `mcp__pencil__get_editor_state`).

**Steps:**

a. Find all `.pen` files in the project:
   ```
   Glob for **/*.pen
   ```

b. For each `.pen` file, use `mcp__pencil__get_editor_state` to confirm
   MCP is connected. If not, skip Pencil validation with a warning.

c. Use `mcp__pencil__search_all_unique_properties` on the root nodes with:
   - `fillColor` — compare against `tokens.colors.*`
   - `textColor` — compare against `tokens.colors.*`
   - `strokeColor` — compare against `tokens.colors.*`
   - `fontSize` — compare against type scale (base_size * ratio^n)
   - `fontFamily` — compare against `tokens.typography.font_family`
   - `gap` — compare against spacing scale (base * multipliers)
   - `padding` — compare against spacing scale
   - `cornerRadius` — compare against `tokens.radii.*`

d. For each property found, check against rules:
   - **Color check**: Count unique fill/text/stroke colors. If
     `> rules.colors.max_unique`, report `[WARN] {n} unique colors
     found (max: {max})`. If `rules.colors.require_semantic` and a
     color doesn't match any token, report `[WARN] Unlisted color
     {hex} not in design tokens`.
   - **Typography check**: Count unique font families. If
     `> rules.typography.max_font_families`, report `[WARN] {n} font
     families found (max: {max})`. If `rules.typography.require_scale`
     and a font size doesn't match `base * ratio^n` for any integer n
     (0-10), report `[WARN] Font size {px} not on type scale`.
   - **Spacing check**: If `rules.spacing.require_base_unit` and a
     gap/padding value is not `base * multiplier` for any multiplier
     in the scale, report `[WARN] Spacing {px} not a multiple of
     base unit ({base}px)`.
   - **Corner radius check**: If a radius doesn't match any value in
     `tokens.radii`, report `[INFO] Corner radius {px} not in token set`.

e. **Contrast check** (if `rules.accessibility.min_contrast` is set):
   For text nodes, if both textColor and the parent's fillColor are
   available, calculate relative luminance contrast ratio. If below
   `min_contrast`, report `[ERROR] Contrast ratio {ratio} below
   minimum {min} for text "{preview...}"`.

### Output format:

```
Kalos Check — <project_name>
Template: <extends> | Adapters: <list>

Pencil: <filename>.pen
  [OK] 8 unique colors (max: 12)
  [WARN] Font size 13px not on type scale (base: 16, ratio: 1.25)
  [WARN] Spacing 7px not a multiple of base unit (4px)
  [ERROR] Contrast ratio 2.8 below minimum 4.5 for text "Submit"
  [OK] 1 font family (max: 2)
  [OK] All corner radii match tokens

Summary: 0 errors, 2 warnings, 0 info
```

If no violations: "All design artifacts pass validation."

### Without Pencil MCP:

If Pencil MCP tools are not available but `pencil` is in adapters:
```
[SKIP] Pencil adapter: MCP not connected. Open Pencil and restart session.
```

---

#### Tailwind Adapter Validation

Only runs if `tailwind` is in the `adapters` list.

**Steps:**

a. Look for Tailwind config in project root: `tailwind.config.ts`,
   `tailwind.config.js`, or `tailwind.config.mjs`. If not found, skip
   with `[SKIP] Tailwind: no config file found`.

b. Read the Tailwind config theme values (colors, spacing, radii, fonts).

c. Compare against resolved Kalos tokens:
   - **Colors**: Do config color hex values match `tokens.colors.*`?
     If mismatch: `[WARN] Tailwind color '{name}' is {actual},
     expected {token}`.
   - **Spacing**: Do spacing values match `base * multipliers` from
     the token scale? If extra: `[WARN] Tailwind spacing '{key}'
     ({value}) not in token scale`.
   - **Radii**: Do border-radius values match `tokens.radii.*`?
     If mismatch: `[WARN] Tailwind radius '{name}' is {actual},
     expected {token}`.
   - **Fonts**: Does `fontFamily` match `tokens.typography.font_family`?
     If mismatch: `[WARN] Tailwind font family doesn't match token`.

d. Check for stale generated files:
   - If `kalos.tailwind.config.ts` exists, compare against what sync
     would generate. If different: `[WARN] kalos.tailwind.config.ts
     is stale — run /kalos sync`.
   - Same for `kalos-tokens.css`.

**Output:**
```
Tailwind: tailwind.config.ts
  [OK] Colors match tokens
  [WARN] Spacing value 7px not in token scale
  [WARN] Generated kalos-tokens.css is stale — run /kalos sync
  [OK] Font family matches
  [OK] Border radii match tokens
```

#### Brand Palette Validation

Only runs if `brands:` is configured with multiple palettes.

Check that all palettes define the same set of keys:
- For each palette, collect all defined keys (e.g., `colors.primary`,
  `colors.secondary`, `typography.font_family`)
- Compare key sets across palettes
- If a palette is missing a key that others have:
  `[ERROR] Brand '{name}' missing key: {key}`
- If all palettes are consistent:
  `[OK] All {n} brand palettes have consistent keys`

---

## /kalos sync — Push Tokens to Adapters

Push resolved design tokens to adapter targets.

### Flow:

1. **Load config** — resolve `.kalos.yaml` using 3-tier resolution.
   If no `.kalos.yaml`: "No Kalos config found. Run `/kalos init` first."

2. **For each enabled adapter**, run sync:

**Brand awareness:** If `brands:` is configured, sync uses the active
brand's resolved tokens. The Pencil adapter pushes active brand colors.
The Tailwind adapter generates `:root` with active brand defaults plus
`[data-brand="X"]` blocks for all palettes.

#### Pencil Adapter Sync

Only runs if `pencil` is in the `adapters` list AND Pencil MCP tools
are available.

**Steps:**

a. Check MCP connection via `mcp__pencil__get_editor_state`.

b. Read current Pencil variables via `mcp__pencil__get_variables`.

c. Build variable set from resolved tokens:

   ```yaml
   # Map tokens to Pencil variables
   variables:
     color-primary:
       type: color
       value: <tokens.colors.primary>
     color-secondary:
       type: color
       value: <tokens.colors.secondary>
     color-success:
       type: color
       value: <tokens.colors.semantic.success>
     color-warning:
       type: color
       value: <tokens.colors.semantic.warning>
     color-error:
       type: color
       value: <tokens.colors.semantic.error>
     color-info:
       type: color
       value: <tokens.colors.semantic.info>
     font-family:
       type: string
       value: <tokens.typography.font_family>
     font-base-size:
       type: number
       value: <tokens.typography.base_size>
     spacing-base:
       type: number
       value: <tokens.spacing.base>
     radius-sm:
       type: number
       value: <tokens.radii.sm>
     radius-md:
       type: number
       value: <tokens.radii.md>
     radius-lg:
       type: number
       value: <tokens.radii.lg>
   ```

d. Push via `mcp__pencil__set_variables` with the built variable set.

e. Confirm:
   ```
   Kalos Sync — <project_name>
   Pencil: pushed {n} variables
     Colors: primary, secondary, success, warning, error, info
     Typography: font-family, font-base-size
     Spacing: spacing-base
     Radii: sm, md, lg
   ```

### Without Pencil MCP:

```
[SKIP] Pencil adapter: MCP not connected. Open Pencil and restart session.
```

---

#### Tailwind Adapter Sync

Only runs if `tailwind` is in the `adapters` list.

**Steps:**

a. Resolve effective config (with brand resolution if applicable).

b. Generate `kalos.tailwind.config.ts` in project root:

   ```ts
   // Generated by Kalos — do not edit manually
   // Regenerate with: /kalos sync
   import type { Config } from "tailwindcss";

   export const kalosTheme: Partial<Config["theme"]> = {
     extend: {
       colors: {
         primary: "var(--kalos-color-primary)",
         secondary: "var(--kalos-color-secondary)",
         success: "var(--kalos-color-success)",
         warning: "var(--kalos-color-warning)",
         error: "var(--kalos-color-error)",
         info: "var(--kalos-color-info)",
       },
       fontFamily: {
         sans: [<tokens.typography.font_family parts>],
       },
       spacing: {
         // Generated from tokens.spacing.base * tokens.spacing.scale
         "<multiplier>": "<base * multiplier>px",
       },
       borderRadius: {
         // Generated from tokens.radii
         "<name>": "<value>px",
       },
     },
   };
   ```

c. Generate `kalos-tokens.css` in project root:

   ```css
   /* Generated by Kalos — do not edit manually */
   /* Regenerate with: /kalos sync */

   :root {
     --kalos-color-primary: <tokens.colors.primary>;
     --kalos-color-secondary: <tokens.colors.secondary>;
     --kalos-color-success: <tokens.colors.semantic.success>;
     --kalos-color-warning: <tokens.colors.semantic.warning>;
     --kalos-color-error: <tokens.colors.semantic.error>;
     --kalos-color-info: <tokens.colors.semantic.info>;
     --kalos-font-family: <tokens.typography.font_family>;
     --kalos-font-base-size: <tokens.typography.base_size>px;
     --kalos-spacing-base: <tokens.spacing.base>px;
     --kalos-radius-sm: <tokens.radii.sm>px;
     --kalos-radius-md: <tokens.radii.md>px;
     --kalos-radius-lg: <tokens.radii.lg>px;
   }
   ```

   If `brands:` is configured, also generate per-brand overrides:

   ```css
   [data-brand="<brand-name>"] {
     --kalos-color-primary: <palette.colors.primary>;
     --kalos-color-secondary: <palette.colors.secondary>;
     /* Only override keys that differ from :root */
     --kalos-font-family: <palette.typography.font_family>;
   }
   ```

d. Confirm:
   ```
   Tailwind: generated 2 files
     kalos.tailwind.config.ts — theme extension with CSS var references
     kalos-tokens.css — custom properties (default + {n} brand overrides)
   ```

---

## /kalos extract — Bootstrap Config from Existing

Read existing design artifacts and generate a `.kalos.yaml` from
discovered values.

### Flow:

1. **Detect available sources** — check which adapters have artifacts:
   - Pencil: Glob for `**/*.pen`. If found, use
     `mcp__pencil__search_all_unique_properties` on root nodes to
     discover `fillColor`, `textColor`, `fontSize`, `fontFamily`,
     `gap`, `padding`, `cornerRadius` values.
   - Tailwind: Look for `tailwind.config.ts` (or `.js`, `.mjs`).
     If found, read theme extension values for colors, spacing,
     fonts, radii.
   - CSS: Glob for `**/globals.css`, `**/global.css`, `**/vars.css`,
     or files containing `:root {`. Parse CSS custom property
     definitions for color, font, spacing, radius values.

2. **Merge discovered values:**
   - Deduplicate colors, sort by usage frequency
   - Identify most-used font as primary font family
   - Infer spacing base from GCD of discovered spacing values
   - Collect unique radii values and map to sm/md/lg/xl

3. **Present findings to user:**
   ```
   Kalos Extract — discovered tokens:
     Sources: <list of sources found>
     Colors: #6366F1 (12 uses), #EC4899 (8 uses), #22C55E (4 uses)...
     Font: Inter (primary), system-ui (fallback)
     Spacing: base appears to be 4px (values: 4, 8, 12, 16, 24, 32)
     Radii: 0, 4, 8, 12

   Suggested template: modern (closest match)
   Use these as your Kalos config?
   ```

4. **If user approves** — write `.kalos.yaml` with discovered values,
   set `extends` to suggested template, run Instruction Injection.

5. **If user wants changes** — let them adjust values before writing.
   Re-present updated config for confirmation.

### Constraint:

Extract only reads from adapter sources (Pencil, Tailwind, CSS).
No code parsing, no screenshot analysis — use `/kalos import` for
reading source code and live URLs.

---

## /kalos import — Code-to-Design Pipeline

Staged pipeline that reads source code or live URLs, discovers UI structure
and tokens, optionally reconstructs components via adapters, and integrates
into Kalos config.

Usage: `/kalos import <source>`
- Code: `/kalos import src/components/` — reads .tsx/.vue/.html/.css/.svelte
- URL: `/kalos import https://myapp.com/dashboard` — captures live app

### Input Detection

If source starts with `http://` or `https://` → **URL mode**.
Otherwise → **Code file mode** (resolve as path or glob pattern).

### Stage 1: Discover

Parse inputs and extract raw design data into a **UI Model** — an
adapter-agnostic intermediate representation held in memory.

#### Code File Mode

1. Glob for files matching the source path:
   `.tsx`, `.vue`, `.html`, `.css`, `.svelte`, `.jsx`, `.scss`, `.less`

2. For each file, extract:
   - **Component boundaries** — function/class components, template blocks,
     `export default` patterns
   - **Colors** — hex values, rgb/rgba, CSS custom properties, Tailwind
     color classes (e.g., `bg-blue-500` → `#3B82F6`)
   - **Typography** — font-family declarations, font-size values,
     font-weight, line-height, Tailwind text classes
   - **Spacing** — margin, padding, gap values (px, rem), Tailwind
     spacing classes (e.g., `p-4` → `16px`)
   - **Border radii** — border-radius values, Tailwind rounded classes
   - **Layout** — flex/grid direction, alignment, gap, nesting depth
   - **Variants** — conditional classes, props that change appearance
     (e.g., `variant="primary"`, `className={active ? 'bg-blue' : 'bg-gray'}`)

3. Build UI Model from collected data.

#### URL Mode

1. **Check Chrome MCP** — call `mcp__claude-in-chrome__tabs_context_mcp`.
   If available, use Chrome MCP. If not, fall back to headless capture.

2. **Chrome MCP capture:**
   a. Create new tab via `mcp__claude-in-chrome__tabs_create_mcp`
   b. Navigate to URL via `mcp__claude-in-chrome__navigate`
   c. Take screenshot via `mcp__claude-in-chrome__computer` (action: screenshot)
   d. Read DOM structure via `mcp__claude-in-chrome__read_page`
   e. Extract computed styles via `mcp__claude-in-chrome__javascript_tool`:
      ```javascript
      Array.from(document.querySelectorAll('*')).filter(el => {
        const rect = el.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
      }).map(el => {
        const s = window.getComputedStyle(el);
        return {
          tag: el.tagName, classes: el.className,
          rect: el.getBoundingClientRect(),
          color: s.color, bg: s.backgroundColor,
          font: s.fontFamily, fontSize: s.fontSize,
          padding: s.padding, margin: s.margin,
          gap: s.gap, radius: s.borderRadius,
          display: s.display, flexDir: s.flexDirection
        };
      })
      ```
   f. Read accessibility tree via `mcp__claude-in-chrome__read_page`
      with `filter: "all"` for component roles and hierarchy

3. **Headless fallback** (if Chrome MCP unavailable):
   a. Run `bin/capture.sh <url> <output-dir>` where output-dir is
      a temp directory (e.g., `/tmp/kalos-import-<timestamp>`)
   b. Read the output files: `screenshot.png`, `dom.html`, `styles.json`
   c. If capture.sh exits with code 2: "No headless browser available.
      Install Puppeteer (`npm install -g puppeteer`) or connect Chrome
      MCP for URL import."

4. **Analyze with Claude vision** — read the screenshot to identify:
   - Visual sections and component boundaries
   - Color palette in use
   - Typography hierarchy
   - Spacing patterns
   - Overall layout structure

5. **Merge DOM + vision** — combine structural data from DOM/styles
   with visual analysis from screenshot. DOM provides exact values;
   vision provides component semantics and grouping.

6. Build UI Model from merged data.

#### UI Model Structure

```yaml
source:
  type: "code" | "url"
  path: "<source path or URL>"
  files_scanned: <n>    # code mode
  screenshot: "<path>"  # url mode

pages:
  - name: "<page or component group>"
    components:
      - name: "<ComponentName>"
        type: "frame"
        reusable: true | false
        layout:
          direction: "horizontal" | "vertical"
          gap: <px>
          align: "<alignment>"
        styles:
          fill: "<color>"
          radius: <px>
          padding: [<top>, <right>, <bottom>, <left>]
        variants:
          - name: "<variant>"
            styles: { ... }
        children: [...]

tokens:
  colors:
    - value: "<hex>"
      uses: <n>
      semantic: "primary" | "secondary" | "success" | ... | null
  fonts:
    - family: "<name>"
      uses: <n>
  spacing:
    values: [<px>, ...]
    inferred_base: <px>
  radii:
    values: [<px>, ...]
```

The UI Model is held in memory — not persisted as a file.

---

### Stage 2: Audit (Checkpoint 1)

Present discovered findings to the user and pause for confirmation
before proceeding.

#### Output Format

```
Kalos Import — Audit
Source: <source> (<n> files | URL)

Tokens Discovered:
  Colors: <hex> (<n> uses), <hex> (<n> uses), ...
  Fonts: <family> (primary, <n> uses), <family> (fallback)
  Spacing: base appears to be <n>px (values: <list>)
  Radii: <list>

Components Found: <n>
  Layout: <component list>
  Data Display: <component list with variant counts>
  Forms: <component list with variant counts>
  Navigation: <component list>
  Feedback: <component list>

Potential Issues:
  [WARN] <n> colors not mappable to semantic tokens (<list>)
  [WARN] Font size <n>px not on standard type scale
  [INFO] <n> components have inline styles instead of classes
```

#### User Choices

Present using AskUserQuestion:

1. **Continue to Reconstruct** — proceed to generate components via
   enabled adapters. Only available if at least one adapter is enabled
   and its MCP/tools are available.

2. **Adjust** — let user correct component names, merge similar
   components, remove false positives, assign semantic color roles.
   Re-present audit after adjustments.

3. **Stop here** — take the token audit report only. No adapter
   output. Print summary and exit.

4. **Feed into Kalos** — jump to Integrate stage (Stage 4) with
   discovered tokens. Skip reconstruction.

Options 3 and 4 are exit ramps — the pipeline ends without
reconstruction. Options 1 and 2 continue to Stage 3.

---

### Stage 3: Reconstruct

Generate editable components from the UI Model via enabled adapters.
Each adapter translates the UI Model into its own format.

#### Pre-check

Verify at least one adapter is available:
- Pencil: check `mcp__pencil__get_editor_state`
- Tailwind: always available (generates files)

If no adapter can run: "No adapters available for reconstruction.
Use option 3 (Stop here) or 4 (Feed into Kalos) from the audit."

#### Pencil Adapter Reconstruct

Only runs if `pencil` is in adapters AND Pencil MCP is connected.

**Steps:**

a. Create or open .pen file:
   - Default path: `docs/designs/import-<source-name>.pen`
   - If user passed `--output=<path>`, use that path
   - Use `mcp__pencil__open_document` to open or create

b. Get design guidelines:
   - `mcp__pencil__get_style_guide_tags` → select relevant tags
   - `mcp__pencil__get_style_guide` with selected tags
   - `mcp__pencil__get_guidelines` for layout rules

c. Set token variables via `mcp__pencil__set_variables`:
   - Map discovered colors to `color-primary`, `color-secondary`, etc.
   - Map fonts to `font-family`
   - Map spacing to `spacing-base`
   - Map radii to `radius-sm`, `radius-md`, `radius-lg`

d. Generate components using `mcp__pencil__batch_design` in order:
   - **Atoms first** — smallest components (Button, Badge, Input)
     as reusable Pencil components (`reusable: true`)
   - **Molecules** — composed components using atom refs
   - **Organisms** — larger sections using molecule/atom refs
   - **Pages** — full layout compositions using all component refs

   Each batch_design call should have max 25 operations.
   Use Insert (I) for new components, Update (U) for properties,
   and set `reusable: true` on component definitions.

e. Handle variants:
   - Components with visual variants get separate reusable definitions
     (e.g., `Button-primary`, `Button-secondary`, `Button-ghost`)

f. Visual verification:
   - `mcp__pencil__get_screenshot` on generated page
   - For URL imports: compare against original screenshot using
     Claude vision. Note significant deviations.

#### Tailwind Adapter Reconstruct

Only runs if `tailwind` is in adapters.

**Steps:**

a. For each component in the UI Model, generate a component file
   using Kalos CSS custom properties:
   - Colors: `var(--kalos-color-primary)`, etc.
   - Spacing: Tailwind classes mapped to token scale
   - Radii: Tailwind rounded classes mapped to token radii

b. File output: `kalos-import/<ComponentName>.tsx` (or `.vue`, `.svelte`
   matching the source file format if detectable)

c. If `kalos-tokens.css` doesn't exist, generate it via the existing
   Tailwind Adapter Sync process.

#### Output

```
Kalos Import — Reconstruct
Generated: docs/designs/import-dashboard.pen

Components: <n> (<reusable> reusable, <instances> instances)
  Atoms: <list with variant counts>
  Molecules: <list>
  Organisms: <list>
  Pages: <list>

Variables set: <n> colors, <n> fonts, <n> spacing, <n> radii

Visual match: ~<percent>% (<notes on deviations>)
```

### Stage 4: Integrate (Checkpoint 2)

After Reconstruct completes (or after Audit if user chose option 4),
offer Kalos config integration.

#### Options

Present using AskUserQuestion:

1. **Create new .kalos.yaml** — bootstrap full config from discovered
   tokens. Same flow as `/kalos extract`: write `.kalos.yaml` with
   tokens, suggest closest template based on discovered values
   (modern if relaxed, minimal if few tokens, brand if strict),
   run Instruction Injection.

2. **Add as brand palette** — add discovered tokens as a new brand.
   Ask for brand name. Write palette under `brands.palettes`:
   ```yaml
   brands:
     palettes:
       <brand-name>:
         colors:
           primary: "<discovered primary>"
           secondary: "<discovered secondary>"
           neutral: "<discovered neutral>"
           semantic:
             success: "<discovered>"
             warning: "<discovered>"
             error: "<discovered>"
             info: "<discovered>"
         typography:
           font_family: "<discovered font>"
   ```
   If `brands:` doesn't exist yet, create it with current tokens as
   "default" palette and imported tokens as the new brand. Set
   `brands.active` to the new brand.

3. **Update existing config** — deep merge discovered tokens into
   current `.kalos.yaml`. Show diff before writing:
   ```
   These values will change:
     primary: #6366F1 → #4F46E5
     secondary: #EC4899 → #8B5CF6
     font_family: "Inter" → "Geist"
   Confirm?
   ```
   Only write after user confirms.

4. **Skip** — no config changes. User keeps the audit report and
   any generated adapter files. Print summary and exit.

#### Post-Integration

If user chose option 1, 2, or 3:
- Run Instruction Injection to update the current agent instruction file
- If adapters are enabled, offer to run `/kalos sync`

#### Final Summary

```
Kalos Import — Complete
Source: <source>
Tokens: <n> colors, <n> fonts, <n> spacing, <n> radii
Components: <n> generated via <adapter list>
Config: <action taken or "no changes">
```

---

## Brand Switching

Switch the active brand and re-sync all adapters.

### Flow:

1. **Parse brand name** from user message (e.g., "switch to acme").

2. **Validate** — check that the brand name exists in `brands.palettes`.
   If not: "Brand '{name}' not found. Available: {list of palette names}."

3. **Update config** — change `brands.active` to the new brand name
   in `.kalos.yaml`.

4. **Re-inject** — run Instruction Injection with the new active brand's
   resolved colors and font.

5. **Re-sync** — run `/kalos sync` for all enabled adapters with the
   new active brand.

6. **Confirm:**
   ```
   Switched to brand: {name}
   - Primary: {color}, Secondary: {color}
   - Font: {family}
   - Re-injected the current agent instruction file
   - Re-synced: {adapter list}
   ```

---

## /kalos (bare) — What Next

Context-aware guidance. Detect project state and suggest the most useful
next action.

### Detection logic (check in this order):

1. **No config at all** (`~/.kalos/defaults.yaml` doesn't exist)
   → "Run `/kalos init` to set up your design standards."

2. **In a project but no `.kalos.yaml`**
   → "This project doesn't have Kalos config yet. Run `/kalos init`
   to set up design tokens and rules, `/kalos extract` to bootstrap
   from existing artifacts, or `/kalos import` to reverse-engineer
   from source code or a live URL."

3. **KALOS section missing or drifted in the current agent instruction file**
   → Re-inject the managed section automatically using the
   Instruction Injection Procedure, then confirm:
   "Re-synced design standards with Kalos config."

4. **Tailwind adapter enabled but generated files missing**
   → "Tailwind adapter is enabled but kalos.tailwind.config.ts or
   kalos-tokens.css not found. Run `/kalos sync` to generate them."

5. **Generated files are stale**
   → "Generated Tailwind files are out of date. Run `/kalos sync`
   to regenerate."

6. **`.pen` files exist but haven't been checked**
   → "Found .pen files in this project. Run `/kalos check` to
   validate them against your design rules."

7. **Everything looks good**
   → "Design standards are set. Use `/kalos check` to validate
   artifacts, `/kalos sync` to push tokens to adapters."

Only show the FIRST applicable suggestion.
