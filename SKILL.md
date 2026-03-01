---
name: ui-val
description: Validate UI visually after making changes. Takes screenshots at multiple viewports and you evaluate them directly. Use after editing .tsx, .css, .html, .vue, or .svelte files.
argument-hint: "<url> [--viewports=desktop,mobile] [--pages=/,/about]"
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# UI-Val: Visual UI Validation

Validate web UIs from a **human visual perspective**. You capture screenshots at multiple viewports and then evaluate them yourself using your vision capabilities. No API keys needed.

## Step 1: Capture Screenshots

Run the capture tool. The user provides a URL (usually a local dev server):

```bash
node ~/.claude/skills/ui-val/bin/ui-val.js check $ARGUMENTS
```

If no URL is provided in arguments, check the project's dev server:
- Vite projects: `http://localhost:5173`
- Next.js projects: `http://localhost:3000`
- Custom: check `package.json` scripts for the dev command and port

### Capture Options

```
--viewports=mobile              Single viewport (faster check)
--viewports=desktop,mobile      Specific viewports
--pages=/,/about,/projects      Check multiple routes
--wait=5000                     Wait longer for slow SPAs
```

The tool outputs JSON with screenshot file paths and metadata (console errors, broken images, DOM metrics).

## Step 2: Read and Evaluate Screenshots

After capture, **read each screenshot file** using the Read tool. You can see images directly.

For each viewport screenshot, evaluate against this **12-point rubric**:

1. **Page renders** — visible content, not blank/white/error screen
2. **Navigation** — visible, properly positioned, not overlapping content
3. **Content visibility** — text blocks readable, not clipped or hidden
4. **Text readability** — large enough, no overlapping text
5. **Layout integrity** — logical grid/flow, nothing out of place
6. **Spacing consistency** — consistent padding/margin between similar elements
7. **Images/icons** — loading correctly, no broken placeholders
8. **Interactive elements** — buttons/links visible, properly sized (44px min on mobile)
9. **Color consistency** — intentional scheme, no jarring breaks
10. **Visual hierarchy** — clear heading > subheading > body progression
11. **Overlapping content** — nothing incorrectly overlapping
12. **Horizontal overflow** — no sideways scroll, no cut-off content

## Step 2.5: Clean Up Screenshots

After reading and evaluating all screenshots, **always clean up** to free disk space:

```bash
node ~/.claude/skills/ui-val/bin/ui-val.js clean
```

This deletes all `.png` files from `.ui-val/screenshots/`. Do this after every evaluation pass — the screenshots have served their purpose once you've read them. If you need to re-capture (for fix verification), the next `check` run will create fresh ones, and you clean up again after evaluating those.

## Step 3: Report and Fix

### Score >= 8: PASS
Report to user: "UI validation passed. No critical issues found."

### Score 5-7: WARN
1. List the issues you found
2. For straightforward fixes (spacing, sizing): make the fix and re-capture to verify
3. For subjective issues: report to user without auto-fixing

### Score < 5: FAIL
1. Focus on **critical** issues first (page broken, content invisible, layout collapsed)
2. For each critical issue:
   - Identify the source file (use Grep to find the component/CSS)
   - Make the minimal fix
3. Re-run capture and re-evaluate to verify the fix
4. **Max 3 repair attempts** — after 3, report remaining issues to user

### Console Errors (from capture metadata)
- React key warnings: fix them
- 404 errors for assets: check file paths
- Runtime errors: investigate if related to current changes

## Important Rules

1. **Never auto-fix more than 3 times** — avoid infinite loops
2. **Don't fix subjective/info-level issues automatically** — mention them to the user
3. **If the dev server isn't running**, tell the user to start it first
4. **Always clean up screenshots** after evaluation — run `ui-val clean` once done. Add `.ui-val/screenshots/` to `.gitignore` as a safety net

## Quick Check (for auto-invocation)

When auto-invoked after a file edit, use a single viewport for speed:

```bash
node ~/.claude/skills/ui-val/bin/ui-val.js check <url> --viewports=desktop
```

Then read only the desktop screenshot for a fast check.

## Component Library Guidance (Prevention)

When building or modifying UI, **prefer established component libraries** over custom implementations:

- **Check project dependencies first** — use what's already installed (shadcn/ui, Radix, Headless UI, Mantine, Chakra, Material UI, etc.)
- **Don't mix libraries** — if the project uses shadcn/ui, stick with it
- **Use library components for common patterns**: modals, dropdowns, forms, navigation, cards, tables, toasts, dialogs, tabs
- **Use the library's responsive and accessibility patterns** — already tested across browsers
- **Never write custom modal/dialog/dropdown/toast from scratch** when a library component exists
