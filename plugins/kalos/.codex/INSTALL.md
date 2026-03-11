# Installing Kalos for Codex

## Installation

1. Clone Kalos into your Codex workspace:

   ```bash
   git clone https://github.com/divyekant/kalos.git ~/.codex/kalos
   ```

2. Symlink the skill into Codex discovery:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/kalos/skills/kalos ~/.agents/skills/kalos
   ```

3. Restart Codex so it discovers the skill.

## Usage

Codex does not use Claude-style slash commands, so invoke Kalos in natural language.

Examples:

```text
Use Kalos to initialize design tokens for this project.
Use Kalos to sync tokens to Tailwind.
Use Kalos to validate this project's design artifacts.
Use Kalos to import design tokens from this app.
```

## Notes

- Kalos writes managed design rules to `AGENTS.md` in Codex projects.
- The optional `hooks/session-start.sh` flow remains a Claude Code-specific convenience and is not required for Codex use.
