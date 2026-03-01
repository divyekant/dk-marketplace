# claude-code-restart Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Package the Claude Code self-restart mechanism as a public GitHub repo that users can set up via Claude Code or manually.

**Architecture:** Two source files (slash command + shell wrapper), a CLAUDE.md install guide for Claude Code to follow, a README for humans, a how-it-works doc, and an MIT license. No build step, no dependencies beyond bash/zsh.

**Tech Stack:** Bash/Zsh, Claude Code hooks system, Git

---

### Task 1: Initialize git repo

**Files:**
- Create: `/Users/divyekant/Projects/claude-code-restart/.gitignore`

**Step 1: Init git repo**

Run: `cd /Users/divyekant/Projects/claude-code-restart && git init`

**Step 2: Create .gitignore**

```
.DS_Store
/tmp/
*.swp
```

**Step 3: Create directory structure**

Run: `mkdir -p src docs`

**Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: init repo"
```

---

### Task 2: Write the restart slash command

**Files:**
- Create: `src/restart.md`

**Step 1: Write the command file**

```markdown
# Restart Claude Code

!`kill -HUP $PPID`
```

Note: Simplified from the original — removed the `touch /tmp/.claude-restart` flag file since the shell wrapper detects exit code 129 directly. The flag file was a redundant fallback.

**Step 2: Commit**

```bash
git add src/restart.md
git commit -m "feat: add /restart slash command"
```

---

### Task 3: Write the shell wrapper function

**Files:**
- Create: `src/wrapper.sh`

**Step 1: Write the wrapper**

```bash
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
}
```

**Step 2: Verify it's valid shell**

Run: `bash -n src/wrapper.sh && zsh -n src/wrapper.sh && echo "OK"`
Expected: `OK`

**Step 3: Commit**

```bash
git add src/wrapper.sh
git commit -m "feat: add shell wrapper with restart loop"
```

---

### Task 4: Write CLAUDE.md (install guide for Claude Code)

**Files:**
- Create: `CLAUDE.md`

**Step 1: Write the guide**

This is the key file — it's what Claude Code reads when a user opens the repo and says "set this up". Write clear, step-by-step instructions that Claude Code can follow:

1. Copy `src/restart.md` to `~/.claude/commands/restart.md`
2. Detect the user's shell (`$SHELL`)
3. Read `src/wrapper.sh` and append the `claude()` function to the user's shell profile (`.zshrc` or `.bashrc`)
4. Tell the user to run `source ~/.zshrc` (or `.bashrc`) or open a new terminal
5. Explain that `/restart` will now work inside Claude Code

Important: The CLAUDE.md should instruct Claude to ask the user before modifying their shell profile.

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md install guide"
```

---

### Task 5: Write README.md

**Files:**
- Create: `README.md`

**Step 1: Write the README**

Sections:
1. **Title + one-line description** — "Self-restart for Claude Code"
2. **The problem** — 2 sentences on why you need this
3. **Quick setup** — two paths:
   - **Via Claude Code:** Clone repo, open Claude Code, say "set this up"
   - **Manual:** Copy command file + paste wrapper into shell profile
4. **How it works** — brief explanation with link to `docs/how-it-works.md`
5. **Configuration** — env var table
6. **Platform support** — macOS + Linux
7. **License** — MIT

Keep it concise. No walls of text.

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```

---

### Task 6: Write docs/how-it-works.md

**Files:**
- Create: `docs/how-it-works.md`

**Step 1: Write the deep dive**

Cover:
1. **Unix signals and exit codes** — when a process receives signal N, it exits with code 128+N. SIGHUP is signal 1, so exit code is 129.
2. **The slash command** — uses `!` prefix for immediate execution (bypasses LLM). `kill -HUP $PPID` sends SIGHUP to the parent shell process running Claude.
3. **The shell wrapper** — a `while true` loop that checks `$?` after Claude exits. On 129, it restarts with `--continue` to resume the session. On anything else, it exits normally.
4. **caffeinate** — macOS utility that prevents the system from sleeping. The wrapper spawns it as a background process during each Claude session and kills it on exit.
5. **Session continuity** — `--continue` tells Claude Code to resume the previous session, preserving conversation context.

Credit the blog post: https://www.panozzaj.com/blog/2026/02/07/building-a-reload-command-for-claude-code/

**Step 2: Commit**

```bash
git add docs/how-it-works.md
git commit -m "docs: add how-it-works deep dive"
```

---

### Task 7: Add LICENSE

**Files:**
- Create: `LICENSE`

**Step 1: Write MIT license**

Standard MIT license, copyright 2026 Divyekant Gupta.

**Step 2: Commit**

```bash
git add LICENSE
git commit -m "chore: add MIT license"
```

---

### Task 8: Final review and cleanup

**Step 1: Verify repo structure**

Run: `find /Users/divyekant/Projects/claude-code-restart -type f | grep -v .git/ | sort`

Expected:
```
CLAUDE.md
LICENSE
README.md
docs/how-it-works.md
docs/plans/2026-02-22-claude-code-restart-design.md
docs/plans/2026-02-22-implementation-plan.md
src/restart.md
src/wrapper.sh
.gitignore
```

**Step 2: Read through each file for consistency**

Verify:
- Links between files work (README links to docs/how-it-works.md, etc.)
- No hardcoded user-specific paths (except in CLAUDE.md instructions where `~` is used)
- Shell wrapper passes `bash -n` and `zsh -n` syntax check

**Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "chore: final cleanup"
```
