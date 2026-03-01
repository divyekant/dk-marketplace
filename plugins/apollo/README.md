# Apollo

Agent-agnostic project lifecycle manager. Encodes your development preferences into a universal YAML config and enforces them by injecting rules into agent instruction files.

## Install

```bash
# 1. Symlink the skill
ln -s <path-to-apollo>/skills/apollo ~/.claude/skills/apollo

# 2. Install session start hook (optional — prints status + auto-checks project health)
mkdir -p ~/.claude/hooks/apollo
cp <path-to-apollo>/hooks/session-start.sh ~/.claude/hooks/apollo/
chmod +x ~/.claude/hooks/apollo/session-start.sh
```

Then add the hook to `~/.claude/settings.json` under `hooks.SessionStart`:

```json
{
  "type": "command",
  "command": "<absolute-path-to>/.claude/hooks/apollo/session-start.sh",
  "timeout": 5
}
```

```bash
# 3. First run — Apollo walks you through setup
/apollo config
```

## Commands

| Command | Purpose |
|---------|---------|
| `/apollo config` | Set up or edit your global preferences (conversational) |
| `/apollo init` | Create a new project from a template (conversational) |
| `/apollo check` | Health check — validates repo state, surfaces gaps |
| `/apollo` | Context-aware "what should I do next?" |
| `/apollo release` | Guided release — bump, changelog, tag, publish |
| "add to Apollo: ..." | Update config mid-session via natural language |

## Config

Apollo uses three-tier config resolution:

1. `~/.apollo/defaults.yaml` — your global preferences
2. `~/.apollo/templates/<name>.yaml` — project type templates
3. `.apollo.yaml` (in project root) — per-project overrides

See [`config/defaults.example.yaml`](config/defaults.example.yaml) for the full schema.

## Templates

Three built-in templates:

- **oss** — open source: full docs, changelog, license, contributing guide
- **personal** — side projects: lighter docs, no review gate, flexible
- **work** — corporate: strict discipline, thorough comments, review-gated

Create custom templates by adding YAML files to `~/.apollo/templates/`.

## Multi-Agent Support

Apollo writes conventions to **all your coding agents simultaneously**. Configure which agents you use in `defaults.yaml`:

```yaml
agents:
  - claude-code
  - cursor
  - codex
  - copilot
```

On every injection (`/apollo init`, `/apollo check`, config update), Apollo writes to each agent's instruction file:

| Agent | Instruction file | Format |
|-------|-----------------|--------|
| `claude-code` | `CLAUDE.md` | Markdown with managed section markers |
| `cursor` | `.cursor/rules/apollo.mdc` | MDC frontmatter (Cursor rules format) |
| `codex` | `AGENTS.md` | Markdown with managed section markers |
| `windsurf` | `.windsurfrules` | Markdown with managed section markers |
| `copilot` | `.github/copilot-instructions.md` | Markdown with managed section markers |
| `aider` | `CONVENTIONS.md` | Markdown with managed section markers |

Apollo manages only its own section (between `<!-- APOLLO:START -->` and `<!-- APOLLO:END -->` markers). Your own instructions in these files are left untouched. For Cursor, Apollo owns the entire `.cursor/rules/apollo.mdc` file but doesn't touch other rule files.

## License

MIT
