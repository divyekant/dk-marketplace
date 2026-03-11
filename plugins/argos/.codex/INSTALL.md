# Installing Argos for Codex

## What Works in Codex

- Core Argos skill invocation
- Policy/state stored under `~/.argos/`
- Direct issue triage and action flow when Argos is invoked explicitly

## What Stays Claude Code-Specific

- Slash commands in `commands/`
- Session-start hook in `hooks/session-start.sh`
- Plugin packaging in `.claude-plugin/`

## Installation

1. Clone Argos into your Codex workspace:

   ```bash
   git clone https://github.com/divyekant/argos.git ~/.codex/argos
   ```

2. Symlink the skill into Codex discovery:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/argos/skills/argos ~/.agents/skills/argos
   ```

3. Restart Codex so it discovers the skill.

## Usage

Invoke Argos directly in natural language instead of Claude slash commands.

Examples:

```text
Use Argos to triage issues for owner/repo.
Run Argos for owner/repo now.
```
