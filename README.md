# ui-val

Give AI agents eyes. Visual UI validation for Claude Code, OpenClaw, Codex, and any LLM agent.

## The Problem

AI agents build UI but can't tell if it actually looks right. They break layouts, overlapping text, missing content on mobile — stuff a human catches instantly by looking at the screen. There's no feedback loop where the agent *sees* what it built.

## How It Works

```
Agent edits UI code
  → ui-val captures screenshots at 3 viewports (Playwright)
  → Agent reads the screenshot files directly (multimodal vision)
  → Agent evaluates against 12-point visual rubric
  → Agent fixes issues and re-captures to verify
```

No API keys. No external services. The agent uses its own vision capabilities to evaluate the screenshots — it just needs Playwright to capture them.

## Install

```bash
git clone https://github.com/divyekant/ui-val.git ~/.claude/skills/ui-val
cd ~/.claude/skills/ui-val
npm install
npx playwright install chromium
```

## Usage

### As a Claude Code Skill

Once installed to `~/.claude/skills/ui-val/`, it's available as `/ui-val` in any Claude Code session:

```
/ui-val http://localhost:5173
```

Claude Code will:
1. Run the capture tool to take screenshots at desktop, tablet, and mobile
2. Read each screenshot and evaluate it visually
3. Report issues or fix them automatically

### As an OpenClaw Skill

Symlink to OpenClaw's skill directory:

```bash
ln -s ~/.claude/skills/ui-val ~/.openclaw/skills/ui-val
```

### As a Standalone CLI (Any Agent)

Any agent that can run bash can use it:

```bash
node ~/.claude/skills/ui-val/bin/ui-val.js check http://localhost:5173
```

Then the agent reads the saved screenshot PNGs and evaluates them.

### CLI Options

```
--viewports=desktop,tablet,mobile   Viewports to check (default: all three)
--viewports=mobile                  Single viewport (faster)
--wait=5000                         Wait ms after page load (default: 3000)
--pages=/,/about,/projects          Check multiple routes (default: /)
```

## Example Output

```json
{
  "url": "http://localhost:5173",
  "timestamp": "2026-02-09T12:00:00Z",
  "viewports": {
    "desktop": {
      "screenshot": ".ui-val/screenshots/desktop-latest.png",
      "size": { "width": 1440, "height": 900 },
      "domMetrics": {
        "totalElements": 191,
        "brokenImages": 0,
        "visibleTextLength": 2584,
        "bodyEmpty": false,
        "title": "My App"
      }
    },
    "tablet": {
      "screenshot": ".ui-val/screenshots/tablet-latest.png",
      "size": { "width": 768, "height": 1024 },
      "domMetrics": { "..." : "..." }
    },
    "mobile": {
      "screenshot": ".ui-val/screenshots/mobile-latest.png",
      "size": { "width": 375, "height": 812 },
      "domMetrics": { "..." : "..." }
    }
  },
  "consoleErrors": []
}
```

Screenshots are saved to `.ui-val/screenshots/` in the current working directory. The agent reads them directly using its vision capabilities.

## The 12-Point Visual Rubric

The agent evaluates each viewport screenshot against:

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

## Architecture

```
ui-val/
├── SKILL.md              # Skill definition (Claude Code / OpenClaw)
├── bin/
│   └── ui-val.js         # CLI entry point
├── src/
│   ├── index.js          # Orchestrator: preflight → capture → output JSON
│   ├── capture.js        # Playwright screenshot engine
│   └── config.js         # Viewport definitions, defaults
├── prompts/
│   └── layout-check.md   # 12-point visual rubric (reference)
├── package.json
└── .gitignore
```

## How Agents Use It

The key insight: modern LLMs (Claude, GPT-4, etc.) can see images. Instead of calling a separate vision API, the agent just reads the screenshot files directly. The SKILL.md teaches the agent:

1. When to validate (after UI file edits)
2. How to capture (run the CLI tool)
3. How to evaluate (read screenshots, apply 12-point rubric)
4. How to fix (identify the source file, make minimal fix, re-capture)
5. When to stop (score >= 8, or max 3 repair attempts)

## Requirements

- Node.js 18+
- Playwright (installed automatically with `npm install`)
- Chromium (install with `npx playwright install chromium`)

## License

MIT
