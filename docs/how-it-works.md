# How It Works

A technical deep dive into the claude-code-restart mechanism.

## Unix Signals and Exit Codes

When a Unix process receives a signal and doesn't handle it, the kernel terminates the process and sets its exit status to 128 + N, where N is the signal number. This is a POSIX convention, not a hard rule -- programs that install signal handlers can exit with whatever code they choose. But most CLI tools, including Node.js processes, follow the convention.

SIGHUP (signal 1) was originally "hangup" -- sent when a terminal disconnected. Today it's commonly used to tell a process to reload its configuration. That reload semantic is exactly why we use it here: we want Claude Code to "reload" by restarting.

Signal 1 means exit code 129 (128 + 1). That's the value the shell wrapper watches for.

## The Slash Command

The file `src/restart.md` contains:

```markdown
# Restart Claude Code

!`kill -HUP $PPID`
```

Two things make this work:

**The `!` prefix.** In Claude Code's custom command system, prefixing a command body with `!` tells Claude to execute it immediately as a shell command, bypassing LLM processing entirely. Without `!`, Claude would interpret the content as a prompt and try to reason about it. With `!`, the backtick-wrapped command runs directly in the shell.

**`kill -HUP $PPID`.** `$PPID` is a shell variable containing the PID of the parent process. When Claude Code executes a shell command, the parent process is the Node.js process running the `claude` CLI. Sending SIGHUP to that process causes it to exit with code 129.

## The Shell Wrapper

The wrapper in `src/wrapper.sh` defines a `claude()` shell function that shadows the real `claude` binary:

```bash
claude() {
  local rc cafe_pid
  while true; do
    # ... caffeinate setup ...

    command claude "$@"
    rc=$?

    # ... caffeinate cleanup ...

    if [ "$rc" -eq 129 ]; then
      printf '\n\033[0;34m↻ Restarting Claude Code...\033[0m\n\n'
      sleep 0.5
      set -- --continue
    else
      break
    fi
  done
}
```

Key details:

- **`command claude`** calls the real `claude` binary, bypassing the shell function. Without `command`, this would be infinite recursion.
- **`$?` check after exit.** When `claude` exits, the wrapper inspects the exit code. If it's 129 (SIGHUP), restart. Anything else (0 for normal exit, 1 for error, 130 for Ctrl-C) breaks the loop and returns to the shell.
- **`set -- --continue`** replaces the positional parameters (`$@`) so the next loop iteration launches `claude --continue` instead of whatever the original arguments were. This is how the wrapper switches from "first launch with user's args" to "restart with session resume."
- **`sleep 0.5`** gives a brief visual pause so the restart message is readable before Claude's UI takes over the terminal.

## caffeinate

Long-running Claude Code sessions -- especially autonomous ones -- can be interrupted by macOS putting the system to sleep. The wrapper prevents this using `caffeinate`, a built-in macOS utility:

```bash
if command -v caffeinate &>/dev/null; then
  { caffeinate -dims & } 2>/dev/null
  cafe_pid=$!
fi
```

The flags:
- `-d` -- prevent the display from sleeping
- `-i` -- prevent the system from idle sleeping
- `-m` -- prevent the disk from sleeping
- `-s` -- prevent the system from sleeping (on AC power)

`caffeinate` runs as a background process for the duration of each Claude session. When Claude exits (for any reason), the wrapper kills the `caffeinate` process before either restarting or returning to the shell.

On Linux, `command -v caffeinate` returns false, so the entire block is silently skipped. No special handling needed.

## Session Continuity

The `--continue` flag tells Claude Code to resume the most recent conversation session. After a restart, Claude picks up with full conversation context -- it sees the entire history of the session, including the `/restart` command that triggered the restart.

This is critical for autonomous workflows. If Claude modifies its own MCP server configuration or installs a new tool, it can restart itself to pick up the changes and then continue working on the original task. Without `--continue`, each restart would be a blank session with no memory of what came before.

## The Restart Flow

Here's what happens step by step when you type `/restart`:

1. **User types `/restart`** in a Claude Code session. Claude Code looks up `~/.claude/commands/restart.md`.

2. **Claude executes `kill -HUP $PPID`.** The `!` prefix triggers immediate shell execution. `$PPID` resolves to the PID of the Node.js process running Claude Code.

3. **Claude's Node.js process receives SIGHUP.** It doesn't have a custom handler for this signal, so it exits with code 129 (128 + 1) per POSIX convention.

4. **The shell wrapper detects exit code 129.** The `while true` loop checks `$?` and sees it's 129, not a normal exit.

5. **The wrapper prints a restart message** and pauses briefly (`sleep 0.5`).

6. **The wrapper re-launches Claude** with `command claude --continue`. The `set -- --continue` from the previous iteration replaces `$@`.

7. **Claude resumes the previous session.** With `--continue`, Claude Code loads the conversation history and picks up where it left off.

From the user's perspective: you type `/restart`, the screen flickers briefly, and Claude is back with full context. The whole cycle takes about 2-3 seconds.

---

Inspired by [Building a Reload Command for Claude Code](https://www.panozzaj.com/blog/2026/02/07/building-a-reload-command-for-claude-code/).
