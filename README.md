# Learning Skill for Claude Code and Codex

A skill for coding agents that teaches them to automatically record learnings (failures + fixes) during sessions and retrieve them to avoid repeating the same mistakes.

## Why

Claude's context resets every session. When it spends 20 minutes debugging something, that knowledge is lost. This skill makes Claude record what went wrong and what fixed it, so it (or you) never repeats the same mistake.

## Install

### As a Claude Code plugin (recommended)

```bash
# From the DK marketplace
claude plugins marketplace add divyekant/dk-marketplace
claude plugins install learning-skill

# Or install directly from GitHub
claude plugins install github:divyekant/learning-skill
```

### In Codex

Codex support uses the Memories MCP backend. The Claude Code file backend and hook installer do not apply there.

```bash
git clone https://github.com/divyekant/learning-skill.git ~/.codex/learning-skill
mkdir -p ~/.agents/skills
ln -s ~/.codex/learning-skill/skill ~/.agents/skills/learning
```

Ensure the Memories MCP server is configured in Codex, then restart Codex so it discovers the skill.

Detailed Codex instructions: [`/.codex/INSTALL.md`](.codex/INSTALL.md)

### Manual install in Claude Code

```bash
git clone https://github.com/divyekant/learning-skill.git
cd learning-skill
bash install.sh
```

Then restart Claude Code (new session or `/restart` if you have a restart command set up).

#### What install.sh does

1. Copies the skill to your superpowers plugin directory
2. Copies the hook to `~/.claude/hooks/memory/` (if you have a memories setup)
3. Adds the hook to `~/.claude/settings.json`

### Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- (Optional) [Memories](https://github.com/divyekant/memories) -- a lightweight semantic memory server for AI agents. Enables semantic search, deduplication, and cross-project retrieval of learnings

## How It Works

### Two layers

1. **Skill (real-time)** -- the agent recognizes failures during a session and records them using a structured schema
2. **Hook (safety net, Claude Code only)** -- a Stop hook analyzes the transcript for failure-to-fix patterns that weren't captured in-session (requires memories API)

### Two storage backends

| Backend | Dependencies | Features |
|---------|-------------|----------|
| **Auto-memory files** | None (built into Claude Code only) | Appends to `learnings.md`, supersedes old learnings to `learnings-archive.md`, keyword-based dedup |
| **[Memories](https://github.com/divyekant/memories) MCP** | Memories server | Semantic search, deduplication, cross-project retrieval, staleness handled OOB |

The skill auto-detects which backend is available. If Memories MCP tools exist, it uses them. Otherwise it falls back to file-based storage in Claude Code only.

### Staleness management

Learnings don't just accumulate — when Claude finds a better fix for a known problem, it supersedes the old learning:

- **Memories MCP:** Reconciliation and dedup are handled by the API. Old learnings are updated automatically.
- **Auto-memory files:** Old entries are moved to `learnings-archive.md` and the new fix takes their place in `learnings.md`.

Both backends apply age awareness: learnings older than 6 months are treated as lower-confidence hints that should be verified before relying on.

## Schema

Every learning follows this format:

```
[LEARNING] <category>: <one-line summary>
TRIED: <what was attempted and why it didn't work>
SOLUTION: <what actually worked>
CONTEXT: <project/tool/language>
```

**Categories:** `debugging`, `implementation`, `infra/config`, `api-usage`, `tooling`

### Example

```
[LEARNING] infra/config: caffeinate wraps exit codes, breaking restart detection
TRIED: Used `caffeinate -dims -- command claude` which swallowed exit code 129
SOLUTION: Run caffeinate in background (`caffeinate -dims &`) to preserve raw exit codes
CONTEXT: Claude Code shell wrapper, zsh, macOS
```

## Usage

The skill activates automatically when Claude encounters a failure and finds the fix. No manual invocation needed.

It triggers when:
- Claude tries something that doesn't work and finds the right approach
- A debugging session concludes with a root cause
- Claude is about to attempt something it has struggled with before
- You point out a mistake Claude should remember

## Project Structure

```
skill/SKILL.md              # The skill definition
hook/learning-extract.sh    # Stop hook for passive extraction
install.sh                  # Installer
docs/plans/                 # Design docs
```

## License

MIT
