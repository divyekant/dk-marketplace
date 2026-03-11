# Installing Apollo for Codex

Apollo already knows how to write Codex conventions to `AGENTS.md`. For Codex, the only setup you need is skill discovery.

## Installation

1. Clone the repo into your Codex workspace:

   ```bash
   git clone https://github.com/divyekant/apollo.git ~/.codex/apollo
   ```

2. Symlink the Apollo skill into Codex's discovered skills directory:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/apollo/skills/apollo ~/.agents/skills/apollo
   ```

3. Restart Codex so it discovers the new skill.

## Usage

Open Codex in a project directory and ask Apollo to initialize or update conventions for the repo.

Examples:

```text
Use Apollo to set up project conventions for this repo.
Initialize Apollo for this project.
Update Apollo config so this repo uses Codex and Claude Code.
```

Apollo stores its shared config in `~/.apollo/` and writes Codex conventions to `AGENTS.md` when `codex` is included in the configured `agents` list.

## Notes

- The optional session-start hook described in the main README is Claude Code-specific.
- Apollo's config format is shared across hosts, so the same `~/.apollo/defaults.yaml` can drive both Claude Code and Codex projects.
