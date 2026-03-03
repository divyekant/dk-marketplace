# Kalos v0.2.0 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Tailwind adapter (sync + validate), brand template, multi-brand config support, /kalos extract command, and brand-aware behavior across all subcommands.

**Architecture:** Extend SKILL.md with Tailwind adapter sections, brand resolution logic, and extract subcommand. Update config templates. Update session-start hook for brand awareness. All changes are to the skill documentation and config YAML — no runtime code beyond the bash hook.

**Tech Stack:** YAML config, Bash hook (tested with bats), Markdown skill file, Pencil MCP tools

---

### Task 1: Config Schema — Add brands section and tailwind adapter

**Files:**
- Modify: `config/defaults.example.yaml`

**Step 1: Update defaults.example.yaml**

Replace the full file with:

```yaml
# Kalos Configuration — Global Defaults
# Copy to ~/.kalos/defaults.yaml and customize
# Or run /kalos init for interactive setup

tokens:
  colors:
    primary: "#6366F1"        # Main brand color
    secondary: "#EC4899"      # Accent color
    neutral: "zinc"           # Neutral scale name
    semantic:
      success: "#22C55E"
      warning: "#F59E0B"
      error: "#EF4444"
      info: "#3B82F6"
  typography:
    font_family: "Inter, system-ui, sans-serif"
    scale: "1.25"             # Type scale ratio (1.25 = major third)
    base_size: 16             # Base font size in px
  spacing:
    base: 4                   # Base unit in px
    scale: [0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32]  # Multipliers of base
  radii:
    none: 0
    sm: 4
    md: 8
    lg: 12
    xl: 16
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
    min_contrast: 4.5
    require_alt_text: true

# Optional — multi-brand palette support
# Omit this section for single-brand projects
# brands:
#   active: "default"
#   palettes:
#     default:
#       colors:
#         primary: "#6366F1"
#         secondary: "#EC4899"
#         neutral: "zinc"
#       typography:
#         font_family: "Inter, system-ui, sans-serif"
#     partner:
#       colors:
#         primary: "#DC2626"
#         secondary: "#F59E0B"
#         neutral: "gray"
#       typography:
#         font_family: "Georgia, serif"

adapters:
  - pencil
  - tailwind
```

**Step 2: Commit**

```bash
git add config/defaults.example.yaml
git commit -m "feat: update config schema with brands section and tailwind adapter

What: Add commented brands section to defaults.example.yaml showing
multi-brand palette structure. Enable tailwind in default adapters.

Why: Schema reference for v0.2.0 multi-brand and Tailwind support."
```

---

### Task 2: Brand Template

**Files:**
- Create: `config/templates/brand.yaml`

**Step 1: Create brand template**

```yaml
# Kalos Template: Brand
# Corporate-strict — tight palette, exact colors only, highest enforcement
extends: defaults

tokens:
  colors:
    primary: "#1E3A5F"
    secondary: "#2563EB"
    neutral: "slate"
    semantic:
      success: "#16A34A"
      warning: "#CA8A04"
      error: "#DC2626"
      info: "#2563EB"
  typography:
    font_family: "system-ui, sans-serif"
    scale: "1.25"
    base_size: 16
  spacing:
    base: 4
    scale: [0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32]
  radii:
    none: 0
    sm: 4
    md: 8
    lg: 12
    full: 9999

rules:
  colors:
    max_unique: 6
    require_semantic: true
  typography:
    max_font_families: 1
    require_scale: true
  spacing:
    require_base_unit: true
  accessibility:
    min_contrast: 7.0
    require_alt_text: true

brands:
  active: "default"
  palettes:
    default:
      colors:
        primary: "#1E3A5F"
        secondary: "#2563EB"
        neutral: "slate"
      typography:
        font_family: "system-ui, sans-serif"

adapters:
  - pencil
  - tailwind
```

**Step 2: Commit**

```bash
git add config/templates/brand.yaml
git commit -m "feat: add brand template — strictest enforcement profile

What: New template with 6 max colors, 1 font family, WCAG AAA (7.0),
and example brands section. Ships with both pencil and tailwind adapters.

Why: Corporate/regulated projects need tighter design governance."
```

---

### Task 3: Update existing templates with tailwind adapter

**Files:**
- Modify: `config/templates/modern.yaml`
- Modify: `config/templates/minimal.yaml`

**Step 1: Add tailwind to modern.yaml adapters**

In `config/templates/modern.yaml`, replace:
```yaml
adapters:
  - pencil
```
with:
```yaml
adapters:
  - pencil
  - tailwind
```

**Step 2: Add tailwind to minimal.yaml adapters**

Same change in `config/templates/minimal.yaml`.

**Step 3: Commit**

```bash
git add config/templates/modern.yaml config/templates/minimal.yaml
git commit -m "feat: add tailwind adapter to modern and minimal templates

What: Both templates now enable pencil and tailwind adapters by default.

Why: Tailwind is a first-class adapter in v0.2.0."
```

---

### Task 4: Skill — Brand resolution logic

**Files:**
- Modify: `skills/kalos/SKILL.md` — update Config Resolution section

**Step 1: Update Config Resolution section**

After the existing merge strategy paragraph (line 58), append brand resolution:

```markdown

### Brand Resolution

When the resolved config contains a `brands:` section with an `active` key:

1. Look up `brands.palettes.<active>` — this is the active palette
2. Deep merge the active palette's `colors` on top of `tokens.colors`
3. Deep merge the active palette's `typography` on top of `tokens.typography`
4. The result is the **effective config** used by check, sync, and injection

Any key not specified in the active palette falls back to the base `tokens.*`.
Spacing and radii are never overridden by brands — they are structural.

If `brands:` is absent, skip brand resolution entirely (backward compatible).
```

**Step 2: Update Instruction Injection table**

After the existing instruction table row for `rules.components.naming`, add:

```markdown
   | `brands.active` | "Active brand: {name}" |
   | `brands.palettes` (count) | "{n} brand palettes configured" |
```

**Step 3: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add brand resolution logic to config resolution

What: New Brand Resolution subsection defining how active palette
overrides base tokens. Updated injection table with brand instructions.

Why: Core logic that all brand-aware features depend on."
```

---

### Task 5: Skill — Tailwind adapter sync section

**Files:**
- Modify: `skills/kalos/SKILL.md` — add Tailwind sync under `/kalos sync`

**Step 1: Add Tailwind Adapter Sync after Pencil Adapter Sync**

After the `### Without Pencil MCP:` block (line 350), before the `---` separator, insert:

```markdown

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
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add Tailwind adapter sync — config + CSS vars

What: Generates kalos.tailwind.config.ts (theme extension referencing
CSS vars) and kalos-tokens.css (custom properties with per-brand
overrides via data-brand attribute).

Why: Tailwind projects need generated config and CSS vars from tokens."
```

---

### Task 6: Skill — Tailwind adapter validate section

**Files:**
- Modify: `skills/kalos/SKILL.md` — add Tailwind validation under `/kalos check`

**Step 1: Add Tailwind Adapter Validation after Pencil section**

After the `### Without Pencil MCP:` block in the check section (line 265), before the `---` separator, insert:

```markdown

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
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add Tailwind adapter validation — config-only checking

What: Reads tailwind.config, compares theme values against Kalos tokens,
checks for stale generated files.

Why: Catches Tailwind config drift without noisy source-file scanning."
```

---

### Task 7: Skill — /kalos extract subcommand

**Files:**
- Modify: `skills/kalos/SKILL.md` — add extract section + update routing table

**Step 1: Update routing table**

Add a new row to the Sub-Command Routing table:
```markdown
| `/kalos extract` or "bootstrap tokens" or "import design" | **Extract** section |
```

**Step 2: Update frontmatter argument_hint**

Change:
```yaml
argument_hint: "[init|check|sync]"
```
to:
```yaml
argument_hint: "[init|check|sync|extract]"
```

**Step 3: Add extract section before /kalos (bare)**

Before the `## /kalos (bare) — What Next` section, insert:

```markdown
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
No code parsing, no screenshot analysis — that belongs to a separate
code-to-design tool.

---
```

**Step 4: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos extract — bootstrap config from existing artifacts

What: New subcommand that reads .pen files, tailwind.config, and CSS
custom properties to discover tokens and generate .kalos.yaml.

Why: Lets existing projects adopt Kalos without manual token entry."
```

---

### Task 8: Skill — Brand-aware /kalos init

**Files:**
- Modify: `skills/kalos/SKILL.md` — update init section

**Step 1: Update first-run detection template list**

In the First-Run Detection section, update the directory structure to include brand template:
```
~/.kalos/
  defaults.yaml
  templates/
    modern.yaml
    minimal.yaml
    brand.yaml
```

**Step 2: Update template choice options**

Change question 1 options text from:
```
(typically: modern, minimal)
```
to:
```
(typically: modern, minimal, brand)
```

**Step 3: Update adapters question**

Replace question 6:
```markdown
6. **Adapters**
   - "Which adapters to enable?"
   - Multi-select: Pencil (recommended for v0.1.0)
   - Note: Tailwind adapter coming in v0.2.0
```
with:
```markdown
6. **Adapters**
   - "Which adapters to enable?"
   - Multi-select: Pencil, Tailwind
   - Both recommended if project uses Tailwind
```

**Step 4: Add brand questions after question 7**

After the strictness question, add:

```markdown
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
```

**Step 5: Update "After questions" section**

Replace the version reference from `version: 0.1.0` to `version: 0.2.0`.

Add note about brands: "If multi-brand was selected, also write the `brands:` section with palettes and active brand."

Update the confirm message to:
```
"Design standards set up. Run `/kalos check` to validate designs,
`/kalos sync` to push tokens to adapters, or `/kalos extract` to
bootstrap from existing artifacts."
```

**Step 6: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: update /kalos init with brand onboarding and tailwind adapter

What: Add brand template to first-run, tailwind to adapter options,
brand questions 8-11 for multi-brand setup.

Why: Onboarding must support the full v0.2.0 feature set."
```

---

### Task 9: Skill — Brand-aware check, sync, injection, and switching

**Files:**
- Modify: `skills/kalos/SKILL.md` — update check, sync, injection, routing

**Step 1: Add brand switching to routing table**

Add row:
```markdown
| "switch to {brand}" or "switch brand" or `/kalos sync --brand {name}` | **Brand Switching** (below) |
```

**Step 2: Add Brand Switching section before /kalos (bare)**

After the extract section, before `/kalos (bare)`, insert:

```markdown
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
   - Re-injected CLAUDE.md
   - Re-synced: {adapter list}
   ```

---
```

**Step 3: Update check section header note**

After "2. **For each enabled adapter**, run validation:" (line 190), add:

```markdown
**Brand awareness:** If `brands:` is configured, validate against the
active brand's resolved tokens (after brand resolution), not the base
`tokens.*` values.
```

**Step 4: Add brand palette consistency check**

After the Tailwind adapter validation section (added in Task 6), add:

```markdown
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
```

**Step 5: Update sync section header note**

After "2. **For each enabled adapter**, run sync:" (line 278), add:

```markdown
**Brand awareness:** If `brands:` is configured, sync uses the active
brand's resolved tokens. The Pencil adapter pushes active brand colors.
The Tailwind adapter generates `:root` with active brand defaults plus
`[data-brand="X"]` blocks for all palettes.
```

**Step 6: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add brand switching, brand-aware check/sync/injection

What: New brand switching section, brand awareness notes on check and
sync, brand palette consistency validation.

Why: All subcommands must respect the active brand context."
```

---

### Task 10: Skill — Update /kalos (bare) for new features

**Files:**
- Modify: `skills/kalos/SKILL.md` — update bare section

**Step 1: Update detection logic**

Replace the current detection logic with:

```markdown
### Detection logic (check in this order):

1. **No config at all** (`~/.kalos/defaults.yaml` doesn't exist)
   → "Run `/kalos init` to set up your design standards."

2. **In a project but no `.kalos.yaml`**
   → "This project doesn't have Kalos config yet. Run `/kalos init`
   to set up design tokens and rules, or `/kalos extract` to bootstrap
   from existing artifacts."

3. **KALOS section missing or drifted in CLAUDE.md**
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
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: update /kalos bare with extract and tailwind guidance

What: Add extract suggestion for projects without config, tailwind
file staleness checks, expanded detection logic.

Why: Bare command must surface all v0.2.0 capabilities contextually."
```

---

### Task 11: Session-start hook — Brand awareness

**Files:**
- Modify: `hooks/session-start.sh`
- Modify: `test/session-start.bats`

**Step 1: Add brand-aware test cases to test/session-start.bats**

Append:

```bash
@test "shows active brand in status line" {
  mkdir -p "$TEST_TEMP/.git"
  cat > "$TEST_TEMP/.kalos.yaml" << 'YAML'
extends: brand
version: 0.2.0
brands:
  active: acme
  palettes:
    acme:
      colors:
        primary: "#1E40AF"
YAML
  cat > "$TEST_TEMP/CLAUDE.md" << 'MD'
<!-- KALOS:START -->
rules
<!-- KALOS:END -->
MD

  result=$(echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh)
  echo "$result" | jq -e '.hookSpecificOutput.additionalContext' | grep -q "brand: acme"
}

@test "no brand shown for single-brand config" {
  mkdir -p "$TEST_TEMP/.git"
  cat > "$TEST_TEMP/.kalos.yaml" << 'YAML'
extends: modern
version: 0.2.0
YAML
  cat > "$TEST_TEMP/CLAUDE.md" << 'MD'
<!-- KALOS:START -->
rules
<!-- KALOS:END -->
MD

  result=$(echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh)
  # Should NOT contain "brand:" in status
  ! echo "$result" | jq -e '.hookSpecificOutput.additionalContext' | grep -q "brand:"
}
```

**Step 2: Run tests to verify new tests fail**

Run: `bats test/session-start.bats`
Expected: 2 new tests FAIL (hook doesn't handle brands yet)

**Step 3: Update hooks/session-start.sh**

Replace the full script with:

```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Exit silently if no cwd or no Kalos config
if [ -z "$CWD" ] || [ ! -f "$CWD/.kalos.yaml" ]; then
  exit 0
fi

# Read project info from .kalos.yaml
VERSION=$(grep '^version:' "$CWD/.kalos.yaml" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
EXTENDS=$(grep '^extends:' "$CWD/.kalos.yaml" 2>/dev/null | head -1 | awk '{print $2}' || echo "none")

# Get project name from directory
PROJECT=$(basename "$CWD")

# Count adapters
ADAPTER_COUNT=$(grep -c '^\s*-\s' "$CWD/.kalos.yaml" 2>/dev/null || echo "0")

# Check for active brand
ACTIVE_BRAND=""
if grep -q '^\s*active:' "$CWD/.kalos.yaml" 2>/dev/null; then
  ACTIVE_BRAND=$(grep '^\s*active:' "$CWD/.kalos.yaml" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || echo "")
fi

# Check for instruction drift
DRIFT=""
if [ -f "$CWD/CLAUDE.md" ]; then
  if ! grep -q "KALOS:START" "$CWD/CLAUDE.md" 2>/dev/null; then
    DRIFT=" | [MISSING] Kalos section not in CLAUDE.md"
  fi
else
  DRIFT=" | [MISSING] No CLAUDE.md found"
fi

# Build status line
BRAND_PART=""
if [ -n "$ACTIVE_BRAND" ]; then
  BRAND_PART=" | brand: ${ACTIVE_BRAND}"
fi

STATUS="Kalos: ${PROJECT} | ${EXTENDS} template | v${VERSION} | ${ADAPTER_COUNT} adapters${BRAND_PART}${DRIFT}"

# Build context + display instruction
CONTEXT="DISPLAY THIS STATUS LINE only in your VERY FIRST response of the session (not on subsequent messages), on its own line, as a dim/muted line using this exact format:\n\n\`${STATUS}\`\n\nDo not add commentary about it. Just print it and continue with your response. After the first response, never show it again."

# If drift detected, add silent fix instruction
if [ -n "$DRIFT" ]; then
  CONTEXT="${CONTEXT}\n\nKalos detected drift: silently re-inject the managed section into agent instruction files using the Kalos skill's Instruction Injection procedure. Do not mention this to the user unless the fix fails."
fi

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
```

**Step 4: Run tests to verify all pass**

Run: `bats test/session-start.bats`
Expected: All 8 tests PASS

**Step 5: Commit**

```bash
git add hooks/session-start.sh test/session-start.bats
git commit -m "feat: add brand awareness to session-start hook

What: Hook reads brands.active from .kalos.yaml, includes active brand
in status line. Two new bats tests for brand/no-brand scenarios.

Why: Status line should reflect active brand context."
```

---

### Task 12: README + CHANGELOG + version bump

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json`

**Step 1: Update README.md**

Update the Commands table to add extract:
```markdown
| `/kalos extract` | Bootstrap config from existing design artifacts |
```

Update the Adapters table Tailwind row status from `v0.2.0` to `✓ v0.2.0`.

Add a Brands section after Config:
```markdown
## Brands

Optional multi-brand support for projects with multiple palettes:

\```yaml
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
\```

Switch brands: "switch to partner-co" or `/kalos sync --brand partner-co`.
```

**Step 2: Update CHANGELOG.md**

Add new section at top:

```markdown
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
```

**Step 3: Update plugin.json version**

Change `"version": "0.1.0"` to `"version": "0.2.0"`.

**Step 4: Commit and tag**

```bash
git add README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "chore: update docs and bump to v0.2.0

What: README with extract command, brands section, updated adapter table.
CHANGELOG with full v0.2.0 release notes. Plugin version bumped.

Why: Release documentation for v0.2.0."
git tag v0.2.0
```
