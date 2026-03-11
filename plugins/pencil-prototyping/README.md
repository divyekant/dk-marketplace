# pencil-prototyping

A skill for Claude Code and Codex that lets you prototype visually on [Pencil.dev](https://www.pencil.dev/) canvases — on demand, from any conversation.

Describe what you want, see it drawn on a live canvas, iterate with natural language. No code required.

## Prerequisites

- macOS (Pencil.dev is macOS only)
- Claude Code or Codex
- Pencil.dev is installed automatically on first use

## Install

### In Codex

```bash
git clone https://github.com/divyekant/pencil-prototyping.git ~/.codex/pencil-prototyping
mkdir -p ~/.agents/skills
ln -s ~/.codex/pencil-prototyping ~/.agents/skills/pencil-prototyping
```

Restart Codex after installation so it discovers the skill.

Detailed Codex instructions: [`/.codex/INSTALL.md`](.codex/INSTALL.md)

### In Claude Code

```bash
git clone https://github.com/divyekant/pencil-prototyping.git ~/.claude/skills/pencil-prototyping
```

Or clone anywhere and symlink:

```bash
git clone https://github.com/divyekant/pencil-prototyping.git ~/Projects/pencil-prototyping
ln -s ~/Projects/pencil-prototyping ~/.claude/skills/pencil-prototyping
```

## Usage

In any Claude Code or Codex session:

```
> Prototype a login screen with email, password, and social login buttons
```

The skill will:
1. Launch Pencil.dev if not running (install it if needed)
2. Ask for an agent restart if MCP connection needs to be established
3. Create a `.pen` canvas in your project
4. Draw the prototype on the canvas
5. Capture a screenshot for reference

## Conductor Integration

If you use [skill-conductor](https://github.com/divyekant/skill-conductor), add to your `pipelines.yaml`:

```yaml
skills:
  pencil-prototyping:
    source: external
    phase: shape
    type: phase

always-available:
  - pencil-prototyping
```

## How It Works

The skill has two components:

- **`skill.md`** — Instructions that guide the agent through the prototyping flow
- **`bin/pencil-start.sh`** — Shell script that handles Pencil installation, launch, and readiness detection

## License

MIT
