# claude-code-restart

Self-restart for Claude Code.

## The problem

Claude Code can't restart itself. When you change MCP servers, hooks, or settings, you have to manually quit and relaunch for them to take effect.

## Quick setup

### Via Claude Code (recommended)

```bash
git clone https://github.com/divyekant/claude-code-restart.git
cd claude-code-restart
claude
```

Then say **"set this up"** -- Claude reads the project's `CLAUDE.md` and installs both components for you.

### Manual

1. Copy the slash command:

```bash
mkdir -p ~/.claude/commands
cp src/restart.md ~/.claude/commands/restart.md
```

2. Add the wrapper function from `src/wrapper.sh` to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
cat src/wrapper.sh >> ~/.zshrc   # or ~/.bashrc
source ~/.zshrc
```

Both pieces are required. The slash command sends SIGHUP; the wrapper catches exit code 129 and restarts.

## Usage

Inside any Claude Code session, type:

```
/restart
```

The session terminates, then the wrapper automatically relaunches with `--continue` so your conversation picks up where it left off. (Requires the shell wrapper — the slash command alone just terminates the session.)

## How it works

The `/restart` slash command runs `kill -HUP $PPID`, which sends SIGHUP to the parent process. Claude Code exits with code 129 (128 + signal 1). The shell wrapper function detects this specific exit code, waits briefly, and restarts `claude --continue` to resume the session.

For a full deep dive, see [docs/how-it-works.md](docs/how-it-works.md).

## Configuration

| Variable | Default | Description |
|---|---|---|
| `CLAUDE_SKIP_PERMISSIONS` | `0` | Set to `1` to pass `--dangerously-skip-permissions` on launch |

## Platform support

| Platform | Status | Notes |
|---|---|---|
| macOS | Full | Includes `caffeinate` to prevent sleep during sessions |
| Linux | Full | `caffeinate` silently skipped |

## Credits

Inspired by Anthony Panozzo's blog post: [Building a reload command for Claude Code](https://www.panozzaj.com/blog/2026/02/07/building-a-reload-command-for-claude-code/).

## License

MIT
