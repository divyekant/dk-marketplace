# claude-code-restart: Shell wrapper for Claude Code self-restart
# Source this file in your .zshrc or .bashrc, or copy the function directly.
#
# How it works:
#   - Wraps the `claude` command in a loop
#   - When Claude exits with code 129 (SIGHUP), it auto-restarts with --continue
#   - Uses caffeinate on macOS to prevent sleep during sessions
#
# Configuration:
#   CLAUDE_SKIP_PERMISSIONS=1  — pass --dangerously-skip-permissions to claude

claude() {
  local rc cafe_pid
  while true; do
    # Prevent system sleep during session (macOS only, silently skipped elsewhere)
    if command -v caffeinate &>/dev/null; then
      { caffeinate -dims & } 2>/dev/null
      cafe_pid=$!
    fi

    # Run claude, optionally skipping permissions
    if [ "${CLAUDE_SKIP_PERMISSIONS:-0}" = "1" ]; then
      command claude --dangerously-skip-permissions "$@"
    else
      command claude "$@"
    fi
    rc=$?

    # Clean up caffeinate process
    if [ -n "$cafe_pid" ]; then
      { kill "$cafe_pid"; wait "$cafe_pid"; } 2>/dev/null
      cafe_pid=""
    fi

    # Exit code 129 = received SIGHUP (128 + signal 1) = restart requested
    if [ "$rc" -eq 129 ]; then
      printf '\n\033[0;34m↻ Restarting Claude Code...\033[0m\n\n'
      sleep 0.5
      set -- --continue
    else
      break
    fi
  done
  return $rc
}
