# Kalos v0.1.0 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a format-agnostic design governance skill that defines design tokens/rules in YAML, injects them into agent instruction files, syncs tokens to Pencil, and validates .pen files against declared rules.

**Architecture:** Claude Code skill with 4 subcommands (init, check, sync, bare). 3-tier YAML config resolution. Session-start hook for drift detection. Pencil adapter for sync/validate via MCP.

**Tech Stack:** YAML config, Bash hook (tested with bats), Markdown skill file, Pencil MCP tools

---

### Task 1: Config Templates

**Files:**
- Create: `config/defaults.example.yaml`
- Create: `config/templates/modern.yaml`
- Create: `config/templates/minimal.yaml`

**Step 1: Create the defaults example config**

This is the full schema reference — users copy it to `~/.kalos/defaults.yaml`.

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
    max_unique: 12            # Max unique colors before warning
    require_semantic: true    # All colors must map to a token
  typography:
    max_font_families: 2      # Max distinct font families
    require_scale: true       # Font sizes must follow type scale
  spacing:
    require_base_unit: true   # All spacing must be multiples of base
  components:
    naming: "PascalCase"      # Component naming convention
    require_variants: false   # Require variant definitions
  accessibility:
    min_contrast: 4.5         # WCAG AA minimum contrast ratio
    require_alt_text: true    # Require alt text on images

adapters:
  - pencil                    # Pencil .pen file sync + validation
  # - tailwind               # v0.2.0
  # - figma                  # v0.3.0
```

**Step 2: Create the modern template**

```yaml
# Kalos Template: Modern
# Current web standards — generous spacing, rounded corners, accessible
extends: defaults

tokens:
  colors:
    primary: "#6366F1"
    secondary: "#EC4899"
    neutral: "zinc"
    semantic:
      success: "#22C55E"
      warning: "#F59E0B"
      error: "#EF4444"
      info: "#3B82F6"
  typography:
    font_family: "Inter, system-ui, sans-serif"
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
  accessibility:
    min_contrast: 4.5
    require_alt_text: true

adapters:
  - pencil
```

**Step 3: Create the minimal template**

```yaml
# Kalos Template: Minimal
# Strict constraints — limited palette, tight spacing, no extras
extends: defaults

tokens:
  colors:
    primary: "#18181B"
    secondary: "#71717A"
    neutral: "zinc"
    semantic:
      success: "#16A34A"
      warning: "#CA8A04"
      error: "#DC2626"
      info: "#2563EB"
  typography:
    font_family: "system-ui, sans-serif"
    scale: "1.2"
    base_size: 16
  spacing:
    base: 4
    scale: [0, 1, 2, 3, 4, 6, 8, 12, 16]
  radii:
    none: 0
    sm: 2
    md: 4
    lg: 8
    full: 9999

rules:
  colors:
    max_unique: 8
    require_semantic: true
  typography:
    max_font_families: 1
    require_scale: true
  spacing:
    require_base_unit: true
  accessibility:
    min_contrast: 7.0
    require_alt_text: true

adapters:
  - pencil
```

**Step 4: Commit**

```bash
git add config/defaults.example.yaml config/templates/modern.yaml config/templates/minimal.yaml
git commit -m "feat: add config schema and templates (modern, minimal)"
```

---

### Task 2: Session-Start Hook

**Files:**
- Create: `hooks/session-start.sh`
- Create: `test/session-start.bats`
- Create: `test/test_helper.bash`

**Step 1: Write the bats test helper**

```bash
#!/usr/bin/env bash
# test/test_helper.bash — shared setup/teardown for bats tests

setup() {
  TEST_TEMP="$(mktemp -d)"
  export TEST_TEMP
}

teardown() {
  rm -rf "$TEST_TEMP"
}
```

**Step 2: Write the failing tests**

```bash
#!/usr/bin/env bats
# test/session-start.bats

load test_helper

@test "script exists and is executable" {
  [ -x "hooks/session-start.sh" ]
}

@test "exits silently with no cwd" {
  echo '{}' | bash hooks/session-start.sh
  # Should exit 0 with no output
}

@test "exits silently when no .kalos.yaml" {
  echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh
}

@test "returns status line when .kalos.yaml exists" {
  mkdir -p "$TEST_TEMP/.git"
  cat > "$TEST_TEMP/.kalos.yaml" << 'YAML'
extends: modern
version: 0.1.0
YAML
  cat > "$TEST_TEMP/CLAUDE.md" << 'MD'
# Test
<!-- KALOS:START -->
rules here
<!-- KALOS:END -->
MD

  result=$(echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh)
  echo "$result" | jq -e '.hookSpecificOutput.additionalContext' | grep -q "Kalos:"
}

@test "detects missing KALOS section in CLAUDE.md" {
  mkdir -p "$TEST_TEMP/.git"
  cat > "$TEST_TEMP/.kalos.yaml" << 'YAML'
extends: modern
version: 0.1.0
YAML
  echo "# No kalos section" > "$TEST_TEMP/CLAUDE.md"

  result=$(echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh)
  echo "$result" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "MISSING"
}

@test "detects drift when no CLAUDE.md exists" {
  mkdir -p "$TEST_TEMP/.git"
  cat > "$TEST_TEMP/.kalos.yaml" << 'YAML'
extends: modern
version: 0.1.0
YAML

  result=$(echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh)
  echo "$result" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "MISSING"
}
```

**Step 3: Run tests to verify they fail**

Run: `bats test/session-start.bats`
Expected: First test fails (script doesn't exist yet)

**Step 4: Write the session-start hook**

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

# Check for instruction drift
DRIFT=""
if [ -f "$CWD/CLAUDE.md" ]; then
  if ! grep -q "KALOS:START" "$CWD/CLAUDE.md" 2>/dev/null; then
    DRIFT=" | [MISSING] Kalos section not in CLAUDE.md"
  fi
else
  DRIFT=" | [MISSING] No CLAUDE.md found"
fi

STATUS="Kalos: ${PROJECT} | ${EXTENDS} template | v${VERSION} | ${ADAPTER_COUNT} adapters${DRIFT}"

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

**Step 5: Make executable and run tests**

Run: `chmod +x hooks/session-start.sh && bats test/session-start.bats`
Expected: All 6 tests PASS

**Step 6: Commit**

```bash
git add hooks/session-start.sh test/session-start.bats test/test_helper.bash
git commit -m "feat: add session-start hook with drift detection

What: Bash hook that detects .kalos.yaml, reads config, checks for
KALOS:START markers in CLAUDE.md, and returns status line + drift fix.

Why: Enables automatic drift detection on every session start,
mirroring Apollo's session-start hook pattern."
```

---

### Task 3: Skill File — Config Resolution + Instruction Injection

**Files:**
- Create: `skills/kalos/SKILL.md`

This is the core skill file. Task 3 covers: metadata, sub-command routing, config resolution logic, and the instruction injection procedure. Tasks 4-7 add the individual subcommand sections.

**Step 1: Write the skill file skeleton with routing + config resolution + injection**

```markdown
---
name: kalos
description: >-
  Use when starting a design phase, setting up design tokens, or validating
  design artifacts. Triggers on '/kalos', 'design tokens', 'design standards',
  'design check', or 'design rules'.
argument_hint: "[init|check|sync]"
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

   Only include instructions for config values that are set and meaningful.

3. **Write to CLAUDE.md** using marker-based injection:

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

(See Task 4)

---

## /kalos check — Validate Design Artifacts

(See Task 5)

---

## /kalos sync — Push Tokens to Adapters

(See Task 6)

---

## /kalos (bare) — What Next

(See Task 7)
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add skill skeleton with routing, config resolution, injection

What: SKILL.md with metadata, sub-command routing table, 3-tier config
resolution logic, and instruction injection procedure with translation table.

Why: Core skill infrastructure that all subcommands build on."
```

---

### Task 4: Skill Section — /kalos init

**Files:**
- Modify: `skills/kalos/SKILL.md` — replace the `(See Task 4)` placeholder

**Step 1: Write the init section**

Replace `(See Task 4)` with:

```markdown
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
  ```
- Copy template files from this skill's source: `../../config/templates/`
- Copy defaults from: `../../config/defaults.example.yaml`
- Then continue with project-level init below.

### Flow:

Ask questions ONE AT A TIME using AskUserQuestion.

1. **Template choice**
   - "Which design template?"
   - Options: list template names from `~/.kalos/templates/`
     (typically: modern, minimal)
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
   - Multi-select: Pencil (recommended for v0.1.0)
   - Note: Tailwind adapter coming in v0.2.0

7. **Strictness**
   - "How strict should design rules be?"
   - Options:
     - Relaxed (max 16 colors, contrast 3.0)
     - Standard (max 12 colors, contrast 4.5 WCAG AA) — recommended
     - Strict (max 8 colors, contrast 7.0 WCAG AAA)

### After questions:

1. Write `.kalos.yaml` to project root with `extends`, `version: 0.1.0`,
   and any overrides from user answers
2. Run the **Instruction Injection Procedure** to write KALOS section
   to CLAUDE.md
3. Confirm: "Design standards set up. Run `/kalos check` after creating
   designs to validate them, or `/kalos sync` to push tokens to Pencil."
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos init subcommand — interactive onboarding

What: Conversational Q&A flow for setting up design tokens, rules,
and adapter selection. Creates .kalos.yaml and injects CLAUDE.md.

Why: Entry point for new projects to establish design governance."
```

---

### Task 5: Skill Section — /kalos check (Pencil Adapter)

**Files:**
- Modify: `skills/kalos/SKILL.md` — replace the `(See Task 5)` placeholder

**Step 1: Write the check section**

Replace `(See Task 5)` with:

```markdown
## /kalos check — Validate Design Artifacts

Scan design artifacts against declared rules. Returns a violation report.

### Flow:

1. **Load config** — resolve `.kalos.yaml` using 3-tier resolution.
   If no `.kalos.yaml`: "No Kalos config found. Run `/kalos init` first."

2. **For each enabled adapter**, run validation:

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
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos check with Pencil adapter validation

What: Scans .pen files via MCP, checks colors/fonts/spacing/radii
against declared tokens and rules, reports violations.

Why: Active validation catches design drift that instruction injection
alone cannot prevent."
```

---

### Task 6: Skill Section — /kalos sync (Pencil Adapter)

**Files:**
- Modify: `skills/kalos/SKILL.md` — replace the `(See Task 6)` placeholder

**Step 1: Write the sync section**

Replace `(See Task 6)` with:

```markdown
## /kalos sync — Push Tokens to Adapters

Push resolved design tokens to adapter targets.

### Flow:

1. **Load config** — resolve `.kalos.yaml` using 3-tier resolution.
   If no `.kalos.yaml`: "No Kalos config found. Run `/kalos init` first."

2. **For each enabled adapter**, run sync:

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
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos sync with Pencil adapter token push

What: Reads resolved tokens, maps to Pencil variable format, pushes
via set_variables MCP tool.

Why: Keeps Pencil canvas variables in sync with declared design tokens."
```

---

### Task 7: Skill Section — /kalos (bare)

**Files:**
- Modify: `skills/kalos/SKILL.md` — replace the `(See Task 7)` placeholder

**Step 1: Write the What Next section**

Replace `(See Task 7)` with:

```markdown
## /kalos (bare) — What Next

Context-aware guidance. Detect project state and suggest the most useful
next action.

### Detection logic (check in this order):

1. **No config at all** (`~/.kalos/defaults.yaml` doesn't exist)
   → "Run `/kalos init` to set up your design standards."

2. **In a project but no `.kalos.yaml`**
   → "This project doesn't have Kalos config yet. Run `/kalos init`
   to set up design tokens and rules."

3. **KALOS section missing or drifted in CLAUDE.md**
   → Re-inject the managed section automatically using the
   Instruction Injection Procedure, then confirm:
   "Re-synced design standards with Kalos config."

4. **`.pen` files exist but haven't been checked**
   → "Found .pen files in this project. Run `/kalos check` to
   validate them against your design rules."

5. **Everything looks good**
   → "Design standards are set. Use `/kalos check` to validate
   artifacts, `/kalos sync` to push tokens to Pencil."

Only show the FIRST applicable suggestion.
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos bare subcommand — context-aware guidance

What: Detects project state (no config, drift, unchecked files) and
suggests the most relevant next action.

Why: Provides ergonomic entry point when user doesn't know which
subcommand to use."
```

---

### Task 8: Plugin Packaging + dk-marketplace

**Files:**
- Modify: `.claude-plugin/plugin.json` (already created, verify contents)
- Update: `README.md` if install instructions need adjustment

**Step 1: Verify plugin.json is correct**

Read `.claude-plugin/plugin.json` and confirm it matches:
```json
{
  "name": "kalos",
  "description": "Format-agnostic design governance tool — define design tokens and rules, enforce them across Pencil, Tailwind, and more",
  "version": "0.1.0",
  "author": "Divyekant",
  "homepage": "https://github.com/divyekant/kalos",
  "repository": "https://github.com/divyekant/kalos",
  "license": "MIT",
  "keywords": ["design", "governance", "tokens", "design-system", "pencil"]
}
```

**Step 2: Verify the skill can be symlinked**

Run: `ls -la skills/kalos/SKILL.md`
Expected: File exists with the full skill content

**Step 3: Commit if any changes**

```bash
git status
# Only commit if there are changes
```

---

### Task 9: Integration Test — End-to-End Walkthrough

**Files:**
- No new files — this is a manual verification task

**Step 1: Verify hook works**

Run:
```bash
echo '{"cwd": "/Users/divyekant/Projects/kalos"}' | bash hooks/session-start.sh | jq .
```
Expected: JSON with status line containing "Kalos: kalos | oss template"

**Step 2: Verify skill file is well-formed**

Run:
```bash
head -20 skills/kalos/SKILL.md
```
Expected: Valid YAML frontmatter with name, description, allowed_tools

**Step 3: Verify config templates parse**

Run:
```bash
python3 -c "import yaml; yaml.safe_load(open('config/templates/modern.yaml'))" 2>/dev/null || echo "YAML parse check: install pyyaml or verify manually"
```

**Step 4: Final project structure check**

Run:
```bash
find . -not -path './.git/*' -not -path './.git' | sort
```

Expected structure:
```
.
./.apollo.yaml
./.claude-plugin
./.claude-plugin/plugin.json
./.github
./.github/ISSUE_TEMPLATE
./.github/ISSUE_TEMPLATE/bug_report.md
./.github/ISSUE_TEMPLATE/feature_request.md
./.gitignore
./CHANGELOG.md
./CLAUDE.md
./CODE_OF_CONDUCT.md
./CONTRIBUTING.md
./LICENSE
./README.md
./config
./config/defaults.example.yaml
./config/templates
./config/templates/minimal.yaml
./config/templates/modern.yaml
./docs
./docs/plans
./docs/plans/2026-03-03-kalos-design.md
./docs/plans/2026-03-03-kalos-implementation.md
./hooks
./hooks/session-start.sh
./skills
./skills/kalos
./skills/kalos/SKILL.md
./test
./test/session-start.bats
./test/test_helper.bash
```

**Step 5: Run bats tests one final time**

Run: `bats test/session-start.bats`
Expected: All tests pass

---

### Task 10: Update CHANGELOG and Tag v0.1.0

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Update CHANGELOG**

Replace `## [Unreleased]` section with:

```markdown
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
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "chore: update CHANGELOG for v0.1.0"
```

**Step 3: Tag**

```bash
git tag v0.1.0
```
