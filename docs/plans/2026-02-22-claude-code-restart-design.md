# Design: claude-code-restart

**Date:** 2026-02-22

## Problem

Claude Code cannot restart itself. When you change MCP servers, hooks, or settings, you must manually quit and relaunch. This breaks flow, especially during autonomous operation.

## Solution

A two-part restart mechanism using Unix signals:

1. **Slash command** (`/restart`) — sends SIGHUP to Claude's parent process, causing exit code 129
2. **Shell wrapper** (`claude()` function) — detects exit code 129 and auto-relaunches with `--continue`

## Components

### Slash command (`src/restart.md`)

A Claude Code custom command that uses `!` prefix for immediate execution (no LLM processing):

```markdown
# Restart Claude Code
!`touch /tmp/.claude-restart && kill -HUP $PPID`
```

### Shell wrapper (`src/wrapper.sh`)

A shell function that wraps the `claude` CLI:

- Runs `claude` in a loop
- Detects exit code 129 (SIGHUP = signal 1, 128+1=129)
- On 129: restarts with `--continue` to resume the session
- On any other exit: breaks the loop normally
- Cross-platform: uses `caffeinate` on macOS to prevent sleep, silently skips on Linux
- Optional `CLAUDE_SKIP_PERMISSIONS=1` env var for `--dangerously-skip-permissions`

### CLAUDE.md (install guide for Claude Code)

Instructions that Claude Code can follow to install the restart mechanism:

1. Copy restart command to `~/.claude/commands/restart.md`
2. Detect user's shell (zsh/bash)
3. Append wrapper function to shell profile
4. Advise user to source profile or open new terminal

### README.md

Human-readable documentation:

- What this does
- Quick setup (via Claude Code or manual)
- How it works (signal mechanism)
- Configuration (env vars)
- Platform support (macOS + Linux)

### docs/how-it-works.md

Deep dive for curious users:

- Unix signal conventions
- Exit code 128+N pattern
- Why SIGHUP specifically
- Session continuity via `--continue`
- The caffeinate trick

## Repo structure

```
claude-code-restart/
├── CLAUDE.md
├── README.md
├── LICENSE
├── src/
│   ├── restart.md
│   └── wrapper.sh
└── docs/
    ├── how-it-works.md
    └── plans/
        └── 2026-02-22-claude-code-restart-design.md
```

## Configuration

| Env var | Default | Description |
|---------|---------|-------------|
| `CLAUDE_SKIP_PERMISSIONS` | `0` | Set to `1` to pass `--dangerously-skip-permissions` |

## Platform support

- **macOS**: Full support including `caffeinate`
- **Linux**: Full support, caffeinate silently skipped

## Attribution

Inspired by https://www.panozzaj.com/blog/2026/02/07/building-a-reload-command-for-claude-code/
