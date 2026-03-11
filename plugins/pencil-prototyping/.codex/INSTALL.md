# Installing pencil-prototyping for Codex

## Prerequisites

- macOS
- Pencil.dev
- Codex
- Pencil MCP configured in `~/.codex/config.toml`

## Installation

1. Clone the repo into your Codex workspace:

   ```bash
   git clone https://github.com/divyekant/pencil-prototyping.git ~/.codex/pencil-prototyping
   ```

2. Symlink the skill into Codex discovery:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/pencil-prototyping ~/.agents/skills/pencil-prototyping
   ```

3. Restart Codex so it discovers the skill.

## Usage

Invoke the skill in natural language, for example:

```text
Prototype a login screen with email, password, and social login buttons.
Prototype a dashboard and save it in docs/designs/.
```

## First-Time Pencil Activation

If Pencil installs on first use, activate it in the app and enable your current agent integration in Settings → Agents and MCP. Then restart Codex and run the request again.
