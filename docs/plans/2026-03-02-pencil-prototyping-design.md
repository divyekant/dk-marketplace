# pencil-prototyping — Design Document

**Date**: 2026-03-02
**Status**: Approved

## Summary

A standalone, publicly-distributable Claude Code skill that gives CC the ability to launch Pencil.dev on demand and prototype visuals on a canvas — no code, no manual setup. Handles the full lifecycle: install, launch, connect, draw, capture.

## Problem

Prototyping during brainstorming requires a visual surface. Pencil.dev provides this via MCP, but has friction:

- Pencil must be installed and activated manually
- MCP connection requires Pencil running before CC starts
- No skill exists to orchestrate this end-to-end

## Solution

A skill with three layers:

1. **Shell script** (`bin/pencil-start.sh`) — handles install, launch, and readiness detection
2. **Skill instructions** (`skill.md`) — guides CC through the flow, invokes restart when needed
3. **Public docs** (`README.md`) — install and usage for external users

## Architecture

```
pencil-prototyping/
├── skill.md              # Skill instructions for CC
├── bin/
│   └── pencil-start.sh   # Install/launch/readiness script
├── README.md             # Public install + usage docs
├── LICENSE               # MIT
└── docs/
    └── plans/            # Design documents
```

## Flow

### 1. Onboard (first-time only)

```
Is Pencil.app installed? (check ~/Applications and /Applications)
  No →
    Detect architecture (uname -m → arm64 or x86_64)
    Download correct DMG via curl
    Mount, copy to ~/Applications, cleanup
    Launch Pencil
    Prompt user: "Activate with your email, then enable Claude Code
                  in Settings → Agents and MCP"
    Wait for user confirmation
    Invoke restart skill (MCP registers on next session)
  Yes → continue
```

### 2. Launch

```
Is Pencil running? (pgrep -f Pencil.app)
  No →
    Launch: open ~/Applications/Pencil.app (or /Applications/Pencil.app)
    Poll localhost port until responsive (timeout: 15s)
  Yes → continue

Is MCP connected? (check if mcp__pencil tools are available)
  No →
    Inform user: "Pencil is running. Restarting CC for MCP connection."
    Invoke restart skill
  Yes → continue
```

### 3. Canvas

```
Create or open .pen file:
  Default location: <project>/docs/designs/<topic>.pen
  User can override with custom path
  Create docs/designs/ directory if missing

Open file in Pencil via mcp__pencil__open_document
```

### 4. Prototype

```
Use MCP tools to draw:
  - get_guidelines (for design rules)
  - get_style_guide_tags + get_style_guide (for visual direction)
  - batch_design (create/update/delete shapes)
  - batch_get (read canvas state)
  - get_screenshot (verify visually)
  - snapshot_layout (check layout issues)

Iterate with user feedback
```

### 5. Capture

```
Take screenshot of final state via get_screenshot
Save as <topic>.png alongside the .pen file
```

## Edge Cases

| Case | Handling |
|------|----------|
| Pencil installed but never activated | Launch and prompt user to activate + enable Claude Code integration |
| Pencil crashed mid-session | MCP tools error → relaunch Pencil → restart CC |
| Wrong architecture DMG | Detect via `uname -m` before download |
| No internet for download | Exit with error message + manual download link |
| System /Applications vs user ~/Applications | Check both, install to ~/Applications (no sudo needed) |
| Port conflict | Verify Pencil is the actual process on the port |
| User wants existing .pen file | Skill accepts optional path argument |
| Project has no docs/designs/ | Create automatically |

## Shell Script: `bin/pencil-start.sh`

Responsibilities:
- `--check` flag: exit 0 if Pencil is installed, exit 1 if not
- `--install` flag: download and install Pencil for current architecture
- `--start` flag: launch Pencil if not running, wait for port readiness
- `--status` flag: report install state, running state, port state
- No flag: run full sequence (check → install if needed → start)

Exit codes:
- 0: success (Pencil installed and running)
- 1: failure (timeout, download error, etc.)
- 2: installed but needs activation (first-time)

## Skill Instructions: `skill.md`

The skill.md tells CC how to:
1. Run `bin/pencil-start.sh` and interpret exit codes
2. Handle first-time activation prompts
3. Detect MCP connection and invoke restart if needed
4. Create .pen files in the right location
5. Use Pencil MCP tools for prototyping
6. Capture screenshots on completion

Argument hint: `"<topic> [--path=docs/designs/] [--open=existing.pen]"`

## Conductor Integration

- **Always-available**: can be invoked at any point in any pipeline
- **Phase skill**: wired into `explore` and `shape` phases
- Skill announces availability: "I can prototype this visually — want me to open a canvas?"

To integrate, users add to their `pipelines.yaml`:

```yaml
skills:
  pencil-prototyping:
    source: external
    phase: shape
    type: phase

always-available:
  - pencil-prototyping
```

## Distribution

- **Repo**: standalone Git repository
- **Install**: `git clone <repo> ~/.claude/skills/pencil-prototyping`
- **Prerequisites**: macOS, Claude Code CLI with active subscription
- **Dependencies**: none (Pencil installed by the skill itself)

## Memories Integration

No explicit integration needed. Existing memory hooks (SessionStart, UserPromptSubmit, Stop) automatically capture decisions, learnings, and context from prototyping sessions.

## Non-Goals

- Code generation from designs (handled by Pencil's built-in export or other tools)
- Multi-user collaboration on canvases
- Non-macOS support (Pencil.dev is macOS/Electron only)
