# claude-code-restart — Installation Instructions

When the user asks to install or set up this project, follow these steps.

## Overview

This project provides a self-restart mechanism for Claude Code. It has two parts that BOTH must be installed:

1. **Slash command** (`src/restart.md`) — adds `/restart` inside Claude Code sessions
2. **Shell wrapper** (`src/wrapper.sh`) — a `claude()` function that catches SIGHUP (exit 129) and restarts with `--continue`

The slash command alone does nothing useful. Without the wrapper, `kill -HUP $PPID` just terminates the session. Both pieces are required.

## Step 1: Install the slash command

Copy `src/restart.md` to the user's Claude Code commands directory:

```
mkdir -p ~/.claude/commands
cp src/restart.md ~/.claude/commands/restart.md
```

## Step 2: Detect the user's shell

Check `$SHELL` to determine the shell profile to modify:

- If `$SHELL` ends with `zsh` -> profile is `~/.zshrc`
- If `$SHELL` ends with `bash` -> profile is `~/.bashrc`
- Otherwise, ask the user which profile file to use

## Step 3: Add the wrapper function (ASK FIRST)

Read the contents of `src/wrapper.sh` from this repo.

**Before modifying any file**, show the user:
- The exact content that will be appended (the full wrapper function)
- The target file path (e.g., `~/.zshrc`)

Ask for explicit confirmation before proceeding. Only append if the user agrees.

When appending, add a blank line before the content to separate it from existing profile contents. Do not add it if the function already exists in the profile (check for `claude()` or `claude-code-restart` in the file first).

## Step 4: Post-install guidance

Tell the user:
- Run `source ~/.zshrc` (or `~/.bashrc`) to activate in the current terminal, or open a new terminal
- Going forward, launch Claude Code normally with `claude` — the wrapper is transparent
- Use `/restart` inside any Claude Code session to trigger a self-restart
- The optional env var `CLAUDE_SKIP_PERMISSIONS=1` passes `--dangerously-skip-permissions` to claude

## Important notes

- The wrapper function overrides the `claude` command with a shell function. It calls the real `claude` binary via `command claude`.
- On macOS, the wrapper uses `caffeinate` to prevent system sleep during sessions.
- The `/restart` slash command only works when Claude Code is launched through the wrapper function.
