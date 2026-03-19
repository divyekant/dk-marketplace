---
name: pencil-prototyping
description: Launch Pencil.dev on demand and prototype visuals on a canvas. Use when you need to create mockups, wireframes, or visual designs. Also triggers on "open Pencil", "design mockup", "prototype this", or "visual prototype".
argument-hint: "<topic> [--path=docs/designs/] [--open=existing.pen]"
allowed-tools: Bash, Read, mcp__pencil__batch_design, mcp__pencil__batch_get, mcp__pencil__get_editor_state, mcp__pencil__get_guidelines, mcp__pencil__get_screenshot, mcp__pencil__get_style_guide, mcp__pencil__get_style_guide_tags, mcp__pencil__get_variables, mcp__pencil__set_variables, mcp__pencil__open_document, mcp__pencil__snapshot_layout, mcp__pencil__find_empty_space_on_canvas, mcp__pencil__search_all_unique_properties, mcp__pencil__replace_all_matching_properties, AskUserQuestion, Skill
---

# Pencil Prototyping

Prototype visuals on a Pencil.dev canvas — on demand, from any conversation.

## Step 1: Ensure Pencil is Ready

Run the startup script from the installed skill location:

- Claude Code install:
  ```bash
  bash ~/.claude/skills/pencil-prototyping/bin/pencil-start.sh
  ```
- Codex install:
  ```bash
  bash ~/.agents/skills/pencil-prototyping/bin/pencil-start.sh
  ```

**Interpret exit codes:**
- **Exit 0** — Pencil is installed and running. Continue to Step 2.
- **Exit 1** — Something failed (download, timeout). Show the error output to the user and stop.
- **Exit 2** — First-time install. Tell the user:
  > Pencil has been installed. Please:
  > 1. Activate with your email in the Pencil window
  > 2. Go to Settings → Agents and MCP → enable your current agent integration
  > 3. Confirm when done

  After user confirms:
  - If this host has a restart skill, use it to restart the current agent.
  - Otherwise, ask the user to restart the current agent manually and run the request again.

## Step 2: Check MCP Connection

After Step 1 succeeds (exit 0), check if Pencil MCP tools are available by calling:

```
mcp__pencil__get_editor_state
```

- **If it works** — MCP is connected. Continue to Step 3.
- **If it errors** — Pencil is running but MCP isn't connected yet. Tell the user:
  > Pencil is running but MCP isn't connected yet. Restart the current agent to establish the MCP connection, then run this request again.

  If a restart skill is available in the current host, use it. Otherwise ask the user to restart manually.

## Step 3: Create or Open Canvas

Parse the user's arguments:
- `<topic>` — the subject of the prototype (e.g., "login-flow", "dashboard")
- `--path=<dir>` — custom output directory (default: `docs/designs/` in current project)
- `--open=<file.pen>` — open an existing .pen file instead of creating new

**For new canvas:**
1. Create the output directory if it doesn't exist: `mkdir -p <path>`
2. Call `mcp__pencil__open_document` with `filePathOrTemplate: "new"`
3. Note: the .pen file will be saved by the user in Pencil (File → Save As to `<path>/<topic>.pen`)

**For existing file:**
1. Call `mcp__pencil__open_document` with `filePathOrTemplate: "<absolute-path>"`

## Step 4: Prototype

Now use the Pencil MCP tools to design:

1. **Get design guidelines** — call `get_guidelines` with the relevant topic (`landing-page`, `design-system`, `web-app`, `mobile-app`, etc.)
2. **Get style guide** — call `get_style_guide_tags` then `get_style_guide` with relevant tags for visual direction
3. **Get available components** — call `batch_get` with `patterns: [{ reusable: true }]` to see what components are available
4. **Design** — use `batch_design` to create shapes, insert components, update properties
5. **Verify** — call `get_screenshot` periodically to verify the design looks correct
6. **Iterate** — ask the user for feedback, make adjustments

## Step 5: Capture

When the user is satisfied with the prototype:

1. Call `get_screenshot` for the final state
2. Tell the user where the .pen file and screenshot are saved
3. Suggest: "You can continue editing in Pencil, or I can make more changes."

## Conductor Integration

This skill is available at any point in any pipeline. During explore/shape phases, proactively offer:
> I can prototype this visually on a canvas — want me to open Pencil?
