# Kalos v0.3.0 — /kalos import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `/kalos import <source>` — a staged pipeline that reads source code or live URLs, discovers tokens and components, reconstructs via adapters, and integrates into Kalos config.

**Architecture:** Extend SKILL.md with the import section (4 stages: Discover, Audit, Reconstruct, Integrate). Add Chrome MCP tools to allowed_tools. Create a headless browser fallback script (`bin/capture.sh`) for URL capture without Chrome MCP. All core logic is skill instructions — no runtime code beyond the capture script.

**Tech Stack:** YAML config, Bash capture script (tested with bats), Markdown skill file, Pencil MCP tools, Chrome MCP tools, Puppeteer/Playwright for headless fallback

---

### Task 1: SKILL.md — Frontmatter, routing table, argument_hint

**Files:**
- Modify: `skills/kalos/SKILL.md`

**Step 1: Update argument_hint**

Change line 7:
```yaml
argument_hint: "[init|check|sync|extract]"
```
to:
```yaml
argument_hint: "[init|check|sync|extract|import]"
```

**Step 2: Add Chrome MCP tools to allowed_tools**

After line 22 (`- AskUserQuestion`), add:
```yaml
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
```

**Step 3: Add import route to routing table**

Find the routing table. Change the extract row from:
```markdown
| `/kalos extract` or "bootstrap tokens" or "import design" | **Extract** section |
```
to:
```markdown
| `/kalos extract` or "bootstrap tokens" | **Extract** section |
| `/kalos import` or "import design" or "code to design" or "reverse engineer" | **Import** section |
```

Note: "import design" moves from extract to import since import is the more appropriate target.

**Step 4: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: update SKILL.md frontmatter for /kalos import

What: Add import to argument_hint, Chrome MCP + Pencil design tools
to allowed_tools, import route to routing table.

Why: Foundation for the /kalos import pipeline."
```

---

### Task 2: Headless browser capture script (TDD)

**Files:**
- Create: `bin/capture.sh`
- Create: `test/capture.bats`

**Step 1: Write failing tests**

Create `test/capture.bats`:

```bash
#!/usr/bin/env bats

setup() {
  TEST_TEMP=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_TEMP"
}

@test "script exists and is executable" {
  [ -x bin/capture.sh ]
}

@test "prints usage with no arguments" {
  run bash bin/capture.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "prints usage with --help" {
  run bash bin/capture.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "fails gracefully when no browser tool available" {
  # Set env vars to force "not found" for both npx puppeteer and playwright
  CAPTURE_NPX_CMD="false" run bash bin/capture.sh "https://example.com" "$TEST_TEMP/output"
  [ "$status" -eq 2 ]
  [[ "$output" == *"No headless browser available"* ]]
}

@test "detects puppeteer availability" {
  # Mock npx to succeed for puppeteer check
  CAPTURE_NPX_CMD="echo puppeteer" run bash bin/capture.sh --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"puppeteer"* ]] || [[ "$output" == *"playwright"* ]]
}

@test "validates URL format" {
  run bash bin/capture.sh "not-a-url" "$TEST_TEMP/output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid URL"* ]]
}

@test "validates output directory exists" {
  run bash bin/capture.sh "https://example.com" "/nonexistent/path/output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Output directory"* ]]
}
```

**Step 2: Run tests to verify they fail**

Run: `cd /Users/divyekant/Projects/kalos && bats test/capture.bats`
Expected: All tests FAIL (script doesn't exist yet)

**Step 3: Create bin/capture.sh**

```bash
#!/bin/bash
set -euo pipefail

# Kalos Import — Headless Browser Capture
# Captures a URL via Puppeteer or Playwright when Chrome MCP is unavailable.
# Outputs: screenshot.png + dom.html + styles.json to output directory.
#
# Usage: capture.sh <url> <output-dir>
#        capture.sh --check   (verify browser tool availability)
#        capture.sh --help

# Allow injection for testing
NPX_CMD="${CAPTURE_NPX_CMD:-npx}"

usage() {
  cat <<'EOF'
Usage: capture.sh <url> <output-dir>
       capture.sh --check
       capture.sh --help

Captures a web page using Puppeteer or Playwright (headless).
Outputs screenshot.png, dom.html, and styles.json to <output-dir>.

Options:
  --check   Check which headless browser is available
  --help    Show this help message
EOF
}

detect_browser() {
  if $NPX_CMD --yes puppeteer --version >/dev/null 2>&1; then
    echo "puppeteer"
    return 0
  elif $NPX_CMD --yes playwright --version >/dev/null 2>&1; then
    echo "playwright"
    return 0
  fi
  return 1
}

# Handle flags
if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "--check" ]; then
  BROWSER=$(detect_browser) || { echo "No headless browser available. Install puppeteer or playwright."; exit 2; }
  echo "Available: $BROWSER"
  exit 0
fi

# Validate arguments
if [ $# -lt 2 ]; then
  usage
  exit 1
fi

URL="$1"
OUTPUT_DIR="$2"

# Validate URL
if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Invalid URL: $URL (must start with http:// or https://)"
  exit 1
fi

# Validate output directory parent exists
OUTPUT_PARENT=$(dirname "$OUTPUT_DIR")
if [ ! -d "$OUTPUT_PARENT" ]; then
  echo "Output directory parent does not exist: $OUTPUT_PARENT"
  exit 1
fi

# Create output dir if needed
mkdir -p "$OUTPUT_DIR"

# Detect browser
BROWSER=$(detect_browser) || {
  echo "No headless browser available. Install with: npm install -g puppeteer"
  exit 2
}

# Generate capture script based on detected browser
if [ "$BROWSER" = "puppeteer" ]; then
  CAPTURE_SCRIPT=$(cat <<'SCRIPT'
const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });
  await page.goto(process.argv[2], { waitUntil: 'networkidle0', timeout: 30000 });

  // Screenshot
  await page.screenshot({ path: process.argv[3] + '/screenshot.png', fullPage: true });

  // DOM
  const html = await page.content();
  require('fs').writeFileSync(process.argv[3] + '/dom.html', html);

  // Computed styles for all visible elements
  const styles = await page.evaluate(() => {
    const elements = document.querySelectorAll('*');
    const result = [];
    elements.forEach(el => {
      const computed = window.getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        result.push({
          tag: el.tagName.toLowerCase(),
          classes: el.className,
          rect: { x: rect.x, y: rect.y, w: rect.width, h: rect.height },
          styles: {
            color: computed.color,
            backgroundColor: computed.backgroundColor,
            fontFamily: computed.fontFamily,
            fontSize: computed.fontSize,
            fontWeight: computed.fontWeight,
            padding: computed.padding,
            margin: computed.margin,
            gap: computed.gap,
            borderRadius: computed.borderRadius,
            display: computed.display,
            flexDirection: computed.flexDirection,
          }
        });
      }
    });
    return result;
  });
  require('fs').writeFileSync(
    process.argv[3] + '/styles.json',
    JSON.stringify(styles, null, 2)
  );

  await browser.close();
  console.log('Captured: screenshot.png, dom.html, styles.json');
})();
SCRIPT
  )
  echo "$CAPTURE_SCRIPT" | $NPX_CMD --yes puppeteer node -e "$(cat)" -- "$URL" "$OUTPUT_DIR"

elif [ "$BROWSER" = "playwright" ]; then
  CAPTURE_SCRIPT=$(cat <<'SCRIPT'
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto(process.argv[2], { waitUntil: 'networkidle', timeout: 30000 });

  await page.screenshot({ path: process.argv[3] + '/screenshot.png', fullPage: true });

  const html = await page.content();
  require('fs').writeFileSync(process.argv[3] + '/dom.html', html);

  const styles = await page.evaluate(() => {
    const elements = document.querySelectorAll('*');
    const result = [];
    elements.forEach(el => {
      const computed = window.getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        result.push({
          tag: el.tagName.toLowerCase(),
          classes: el.className,
          rect: { x: rect.x, y: rect.y, w: rect.width, h: rect.height },
          styles: {
            color: computed.color,
            backgroundColor: computed.backgroundColor,
            fontFamily: computed.fontFamily,
            fontSize: computed.fontSize,
            fontWeight: computed.fontWeight,
            padding: computed.padding,
            margin: computed.margin,
            gap: computed.gap,
            borderRadius: computed.borderRadius,
            display: computed.display,
            flexDirection: computed.flexDirection,
          }
        });
      }
    });
    return result;
  });
  require('fs').writeFileSync(
    process.argv[3] + '/styles.json',
    JSON.stringify(styles, null, 2)
  );

  await browser.close();
  console.log('Captured: screenshot.png, dom.html, styles.json');
})();
SCRIPT
  )
  echo "$CAPTURE_SCRIPT" | $NPX_CMD --yes playwright node -e "$(cat)" -- "$URL" "$OUTPUT_DIR"
fi

echo "Output: $OUTPUT_DIR"
```

Make executable: `chmod +x bin/capture.sh`

**Step 4: Run tests to verify they pass**

Run: `cd /Users/divyekant/Projects/kalos && bats test/capture.bats`
Expected: All 7 tests PASS (some may skip if puppeteer/playwright not installed — that's OK, the script handles gracefully)

**Step 5: Commit**

```bash
git add bin/capture.sh test/capture.bats
git commit -m "feat: add headless browser capture script for URL import

What: bin/capture.sh captures a URL via Puppeteer or Playwright,
outputting screenshot.png, dom.html, and styles.json. Falls back
gracefully if no headless browser is installed.

Why: Fallback for /kalos import URL mode when Chrome MCP unavailable."
```

---

### Task 3: SKILL.md — Import section: Input Detection + Discover stage

**Files:**
- Modify: `skills/kalos/SKILL.md`

**Step 1: Add Import section before Brand Switching**

Find `## Brand Switching`. BEFORE that section, insert:

```markdown
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
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos import — input detection + discover stage

What: New import section with code file parsing, URL capture (Chrome MCP
+ headless fallback), and UI Model intermediate representation.

Why: Stage 1 of the import pipeline reads source material into a
structured format that downstream stages can process."
```

---

### Task 4: SKILL.md — Import: Audit stage (Checkpoint 1)

**Files:**
- Modify: `skills/kalos/SKILL.md`

**Step 1: Add Audit stage after Discover**

Find the `---` separator that closes the Discover section (after the UI Model
Structure yaml block). After it, before `## Brand Switching`, insert:

```markdown
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
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos import audit stage — checkpoint 1

What: Presents discovered tokens and components, lets user adjust,
continue, stop, or jump to integration.

Why: User checkpoint ensures discovered data is accurate before
spending effort on reconstruction."
```

---

### Task 5: SKILL.md — Import: Reconstruct stage

**Files:**
- Modify: `skills/kalos/SKILL.md`

**Step 1: Add Reconstruct stage after Audit**

Find the `---` separator that closes the Audit stage. After it,
before `## Brand Switching`, insert:

```markdown
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

---
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos import reconstruct stage — adapter output

What: Generates Pencil components (atoms → molecules → organisms → pages)
and Tailwind component files from the UI Model.

Why: Stage 3 produces the actual design artifacts from discovered data."
```

---

### Task 6: SKILL.md — Import: Integrate stage (Checkpoint 2)

**Files:**
- Modify: `skills/kalos/SKILL.md`

**Step 1: Add Integrate stage after Reconstruct**

Find the `---` separator that closes the Reconstruct stage. After it,
before `## Brand Switching`, insert:

```markdown
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
- Run Instruction Injection to update CLAUDE.md
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
```

**Step 2: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: add /kalos import integrate stage — config options

What: Four integration options: create new config, add as brand,
update existing, or skip. Post-integration injection and sync.

Why: Stage 4 bridges imported data back into Kalos governance."
```

---

### Task 7: SKILL.md — Update bare detection + extract constraint

**Files:**
- Modify: `skills/kalos/SKILL.md`

**Step 1: Update bare detection item 2**

Find:
```markdown
2. **In a project but no `.kalos.yaml`**
   → "This project doesn't have Kalos config yet. Run `/kalos init`
   to set up design tokens and rules, or `/kalos extract` to bootstrap
   from existing artifacts."
```

Replace with:
```markdown
2. **In a project but no `.kalos.yaml`**
   → "This project doesn't have Kalos config yet. Run `/kalos init`
   to set up design tokens and rules, `/kalos extract` to bootstrap
   from existing artifacts, or `/kalos import` to reverse-engineer
   from source code or a live URL."
```

**Step 2: Update extract constraint note**

Find:
```markdown
### Constraint:

Extract only reads from adapter sources (Pencil, Tailwind, CSS).
No code parsing, no screenshot analysis — that belongs to a separate
code-to-design tool.
```

Replace with:
```markdown
### Constraint:

Extract only reads from adapter sources (Pencil, Tailwind, CSS).
No code parsing, no screenshot analysis — use `/kalos import` for
reading source code and live URLs.
```

**Step 3: Commit**

```bash
git add skills/kalos/SKILL.md
git commit -m "feat: update bare detection and extract constraint for import

What: Bare command now suggests /kalos import for projects without
config. Extract constraint updated to point to import instead of
'separate tool'.

Why: Import is now part of Kalos, not a separate tool."
```

---

### Task 8: README + CHANGELOG + version bump

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json`

**Step 1: Update README.md commands table**

Add a new row after the extract row:

```markdown
| `/kalos import` | Reverse-engineer design from source code or live URL |
```

**Step 2: Update README.md — add Import section**

After the `## Brands` section and before `## Adapters`, add:

```markdown
## Import

Reverse-engineer designs from existing source code or live applications:

```bash
# From source code
/kalos import src/components/

# From a live URL
/kalos import https://myapp.com/dashboard
```

Staged pipeline: **Discover** tokens and components → **Audit** findings → **Reconstruct** via adapters → **Integrate** into Kalos config. Stop at any stage.
```

**Step 3: Update CHANGELOG.md**

Add new section at top (after header, before 0.2.0):

```markdown
## [0.3.0] - 2026-03-03

### Added
- `/kalos import <source>` — staged code-to-design pipeline
- Code file input — parses .tsx/.vue/.html/.css/.svelte for tokens and components
- URL input — Chrome MCP primary, headless browser (Puppeteer/Playwright) fallback
- Discover stage — extracts tokens, layout, components into adapter-agnostic UI Model
- Audit checkpoint — presents findings, lets user adjust before reconstruction
- Reconstruct stage — generates components via enabled adapters (Pencil, Tailwind)
- Integrate checkpoint — create config, add as brand, update existing, or skip
- `bin/capture.sh` — headless browser capture script with Puppeteer/Playwright support
- Chrome MCP tools added to skill allowed_tools

### Changed
- `/kalos extract` constraint updated — points to `/kalos import` for code/URL sources
- `/kalos` (bare) — suggests import for projects without config
- Routing table — "import design" routes to import (was extract)
```

**Step 4: Update plugin.json version**

Change `"version": "0.2.0"` to `"version": "0.3.0"`.

**Step 5: Commit and tag**

```bash
git add README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "chore: update docs and bump to v0.3.0

What: README with import command and section. CHANGELOG with full
v0.3.0 release notes. Plugin version bumped.

Why: Release documentation for v0.3.0."
git tag v0.3.0
```
