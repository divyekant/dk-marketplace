# Installing Learning Skill for Codex

## Supported Backend in Codex

Codex support uses the **Memories MCP** backend.

The Claude Code-specific auto-memory files (`~/.claude/projects/.../memory/learnings.md`) and stop-hook installer do not carry over to Codex.

## Installation

1. Clone the repo into your Codex workspace:

   ```bash
   git clone https://github.com/divyekant/learning-skill.git ~/.codex/learning-skill
   ```

2. Symlink the skill into Codex discovery:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/learning-skill/skill ~/.agents/skills/learning
   ```

3. Ensure the Memories MCP server is configured for Codex.

4. Restart Codex so it discovers the skill.

## Usage

Once installed, the skill can capture learnings through Memories MCP during normal Codex work. No Claude-specific hook setup is required.
