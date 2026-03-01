# Learning Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude Code skill that records learnings (failures + fixes) during sessions and retrieves them to avoid repeating mistakes, with two storage backends.

**Architecture:** A SKILL.md defines the behavior (detect failures, check novelty, record, retrieve). Storage is backend-agnostic: auto-memory files by default, memories MCP when available. A hook enhancement adds passive extraction as a safety net.

**Tech Stack:** Claude Code skills (markdown), bash (hooks), jq, curl, memories API

---

### Task 1: Create the SKILL.md

**Files:**
- Create: `skill/SKILL.md`

**Step 1: Write the skill file**

```markdown
---
name: learning
description: Use when you encounter a failure, dead end, or wrong approach and discover the fix, or before attempting something you've struggled with before
---

# Recording Learnings

## Overview

Capture what went wrong and what fixed it so you never repeat the same mistake. This skill is **rigid** -- follow it exactly.

## When to Use

- You tried something that didn't work and found the fix
- A debugging session concluded with a root cause identified
- You're about to attempt something in an area where past failures occurred
- The user points out you made a mistake you should remember

## The Schema

Every learning follows this format:

\`\`\`
[LEARNING] <category>: <one-line summary>
TRIED: <what was attempted and why it didn't work>
SOLUTION: <what actually worked>
CONTEXT: <project/tool/language>
\`\`\`

**Categories:** `debugging`, `implementation`, `infra/config`, `api-usage`, `tooling`

## Storage Backend Detection

**Check once per session:**

1. If `mcp__memories__memory_add` tool is available → use **Memories MCP**
2. Otherwise → use **Auto-memory files**

Do NOT mix backends in a single session.

## Recording a Learning

### With Memories MCP

1. **Check novelty first:**
   ```
   mcp__memories__memory_is_novel(text="<one-line summary of the learning>")
   ```
   If not novel, skip recording.

2. **Record:**
   ```
   mcp__memories__memory_add(
     text="[LEARNING] <category>: <summary>\nTRIED: <what failed>\nSOLUTION: <what worked>\nCONTEXT: <project/tool>",
     source="learning/<project-name>"
   )
   ```

### With Auto-memory Files

1. **Read existing learnings:**
   Read `~/.claude/projects/<project-path>/memory/learnings.md`
   If a similar learning already exists, skip.

2. **Append:**
   Edit the file to append:
   ```
   ## <category>: <one-line summary>
   - **Tried:** <what failed>
   - **Solution:** <what worked>
   - **Context:** <project/tool>
   ```

## Retrieving Learnings

Before attempting work in a problem area, search for relevant past learnings:

### With Memories MCP
```
mcp__memories__memory_search(query="<description of what you're about to do>", k=5)
```

### With Auto-memory Files
Read `learnings.md` and scan for relevant entries.

## When to Record (Checklist)

After resolving any of these, STOP and record before moving on:

- [ ] Tried an approach that failed, then found the right one
- [ ] Discovered a tool/API behaves differently than expected
- [ ] A config or setup issue took multiple attempts to resolve
- [ ] Found a non-obvious root cause for a bug
- [ ] User corrected your approach

## Red Flags -- You're Skipping This

| Thought | Reality |
|---------|---------|
| "This was too simple to record" | Simple mistakes are the ones you repeat |
| "I'll remember this" | You won't. Context windows reset |
| "This is project-specific" | Patterns transfer across projects |
| "Let me finish first" | Record NOW while context is fresh |

## Quick Reference

| Step | Action |
|------|--------|
| 1 | Recognize: you failed and found the fix |
| 2 | Check: is this already recorded? |
| 3 | Record: use the [LEARNING] schema |
| 4 | Before similar work: search past learnings |
```

**Step 2: Commit**

```bash
git add skill/SKILL.md
git commit -m "feat: add learning skill definition"
```

---

### Task 2: Create the hook enhancement script

**Files:**
- Create: `hook/learning-extract.sh`

This is a **wrapper** around the existing memory-extract.sh pattern, specifically prompting for learning extraction.

**Step 1: Write the hook script**

```bash
#!/bin/bash
# learning-extract.sh — Stop hook enhancement
# Extracts failure-to-fix patterns from the last few message pairs.
# Runs alongside memory-extract.sh as an additional Stop hook.

set -euo pipefail

[ -f "${MEMORIES_ENV_FILE:-$HOME/.config/memories/env}" ] && . "${MEMORIES_ENV_FILE:-$HOME/.config/memories/env}"

MEMORIES_URL="${MEMORIES_URL:-http://localhost:8900}"
MEMORIES_API_KEY="${MEMORIES_API_KEY:-}"

# Skip if no API key (memories not configured)
[ -z "$MEMORIES_API_KEY" ] && exit 0

INPUT=$(cat)

CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
PROJECT=$(basename "$CWD")
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Expand tilde if present
TRANSCRIPT_PATH="${TRANSCRIPT_PATH/#\~/$HOME}"

MESSAGES=""

# Read more context than standard extract -- last 500 lines to catch failure-fix arcs
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  MESSAGES=$(tail -500 "$TRANSCRIPT_PATH" 2>/dev/null | jq -sr '
    [
      .[]
      | select(.type == "user" or .type == "assistant")
      | {
          role: .type,
          text: (
            if .message.content | type == "string" then
              .message.content
            elif .message.content | type == "array" then
              [.message.content[] | select(.type == "text") | .text] | join(" ")
            else
              ""
            end
          )
        }
      | select(.text != "" and (.text | length) > 10)
    ]
    | .[-6:]
    | map(.role + ": " + (.text | .[0:2000]))
    | join("\n\n")
  ' 2>/dev/null) || true
fi

if [ -z "$MESSAGES" ] || [ "$MESSAGES" = "null" ]; then
  exit 0
fi

# Cap at 8000 chars (larger window to capture failure-fix arcs)
MESSAGES="${MESSAGES:0:8000}"

# Prompt specifically for learning extraction
LEARNING_PROMPT="Extract any learnings where something was tried and failed, then a different approach worked. Format each as: [LEARNING] <category>: <summary> | TRIED: <what failed> | SOLUTION: <what worked> | CONTEXT: <project/tool>. Categories: debugging, implementation, infra/config, api-usage, tooling. Only extract genuine failure-to-fix patterns, not general facts."

curl -sf -X POST "$MEMORIES_URL/memory/extract" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $MEMORIES_API_KEY" \
  -d "{\"messages\": $(echo "$MESSAGES" | jq -Rs), \"source\": \"learning/$PROJECT\", \"context\": $(echo "$LEARNING_PROMPT" | jq -Rs)}" \
  > /dev/null 2>&1 || true
```

**Step 2: Make executable**

```bash
chmod +x hook/learning-extract.sh
```

**Step 3: Commit**

```bash
git add hook/learning-extract.sh
git commit -m "feat: add learning extraction hook script"
```

---

### Task 3: Create install script

**Files:**
- Create: `install.sh`

A script that installs the skill and hook into the user's Claude Code setup.

**Step 1: Write the install script**

```bash
#!/bin/bash
# install.sh — Install the learning skill and hook
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"
HOOKS_DIR="$HOME/.claude/hooks/memory"
SETTINGS="$HOME/.claude/settings.json"

# Find the superpowers version directory
VERSION_DIR=$(ls -d "$SKILLS_DIR"/*/skills 2>/dev/null | head -1)
if [ -z "$VERSION_DIR" ]; then
  echo "Error: superpowers plugin not found at $SKILLS_DIR"
  exit 1
fi

# Install skill
echo "Installing skill..."
mkdir -p "$VERSION_DIR/learning"
cp "$SCRIPT_DIR/skill/SKILL.md" "$VERSION_DIR/learning/SKILL.md"
echo "  -> $VERSION_DIR/learning/SKILL.md"

# Install hook (only if memories hooks directory exists)
if [ -d "$HOOKS_DIR" ]; then
  echo "Installing hook..."
  cp "$SCRIPT_DIR/hook/learning-extract.sh" "$HOOKS_DIR/learning-extract.sh"
  chmod +x "$HOOKS_DIR/learning-extract.sh"
  echo "  -> $HOOKS_DIR/learning-extract.sh"

  # Add hook to settings.json if not already present
  if ! grep -q "learning-extract.sh" "$SETTINGS" 2>/dev/null; then
    echo "Adding hook to settings.json..."
    # Use jq to add the hook to the Stop hooks array
    TMP=$(mktemp)
    jq '.hooks.Stop[0].hooks += [{"type": "command", "command": "'$HOOKS_DIR'/learning-extract.sh", "timeout": 30}]' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
    echo "  -> Added Stop hook to settings.json"
  else
    echo "  -> Hook already in settings.json"
  fi
else
  echo "Skipping hook install (no memories hooks directory at $HOOKS_DIR)"
fi

echo ""
echo "Done! Restart Claude Code (/restart) to pick up the new skill."
```

**Step 2: Make executable**

```bash
chmod +x install.sh
```

**Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: add install script for skill and hook"
```

---

### Task 4: Test the skill

**Step 1: Run the install script**

```bash
cd /Users/divyekant/Projects/learning-skill
bash install.sh
```

Expected: Skill copied to superpowers directory, hook added to settings.

**Step 2: Restart Claude Code**

Type `/restart` to reload with the new skill.

**Step 3: Verify skill loads**

Type `/learning` or reference the skill -- Claude should find and load it.

**Step 4: Test recording a learning**

Ask Claude to record the caffeinate/restart learning from this session as a test. Verify it appears in memories via `memory_search`.

**Step 5: Commit any fixes**

```bash
git add -A
git commit -m "fix: adjustments from testing"
```

---

### Task 5: Write README

**Files:**
- Create: `README.md`

**Step 1: Write README**

Brief usage doc covering:
- What it does
- How to install (`bash install.sh`)
- How it works (skill + hook)
- Storage backends (auto-memory vs MCP)

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```
