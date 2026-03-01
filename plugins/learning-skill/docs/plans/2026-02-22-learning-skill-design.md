# Learning Skill Design

## Overview

A Claude Code skill that automatically records learnings (failures + fixes) during sessions and retrieves them to avoid repeating mistakes. Works with two storage backends: auto-memory files (default) and memories MCP (enhanced).

## Memory Schema

Each learning follows a structured format:

```
[LEARNING] <category>: <one-line summary>
TRIED: <what was attempted and why it didn't work>
SOLUTION: <what actually worked>
CONTEXT: <project/tool/language>
```

**Categories**: `debugging`, `implementation`, `infra/config`, `api-usage`, `tooling`

**Source tag** (MCP only): `learning/<project-name>`

## Storage Backends

### Option A: Auto-memory files (default, zero dependencies)

- Records learnings by appending to a `learnings.md` file in the project's auto-memory directory (`~/.claude/projects/.../memory/learnings.md`)
- Uses Read/Edit tools -- works out of the box for everyone
- Searches by reading the file

### Option B: Memories MCP (if available)

- Uses `mcp__memories__memory_add` / `memory_search` / `memory_is_novel`
- Richer semantic search, deduplication, cross-project retrieval
- Source tag: `learning/<project-name>`

**Detection logic**: If `mcp__memories__memory_add` tool is available, use Option B. Otherwise fall back to Option A.

## Layer 1: The Skill (real-time, in-session)

A skill file that teaches Claude to:

1. **Recognize failures in real-time** -- when an approach doesn't work, before moving on, record the learning
2. **Search past learnings** -- before attempting something, check if there's a relevant learning
3. **Record with structure** -- use the `[LEARNING]` schema

### Trigger conditions

The skill should be invoked when:
- Claude tries something that doesn't work and finds the fix
- Claude is about to attempt something it (or the user) has struggled with before
- A debugging session concludes with a root cause identified

### Checklist (rigid -- follow exactly)

1. **Detect**: Recognize that a failure occurred and a fix was found
2. **Check novelty**: Before recording, verify this isn't already known
   - MCP: `memory_is_novel`
   - Files: Read `learnings.md` and check for similar entries
3. **Record**: Store using the `[LEARNING]` schema
   - MCP: `memory_add` with source `learning/<project>`
   - Files: Append to `learnings.md`
4. **Retrieve**: Before attempting similar work, search for past learnings
   - MCP: `memory_search` with relevant query
   - Files: Read and scan `learnings.md`

## Layer 2: The Hook (safety net, post-session)

Enhance the existing `memory-extract.sh` Stop hook to also look for learning patterns in the transcript.

- Only applies when memories API is available (hooks use curl)
- Adds a prompt hint to the extraction request asking the API to specifically identify failure-to-fix patterns
- Uses `learning/<project>` source tag for extracted learnings
- Deduplication handled by the memories API

For file-only users, the skill's in-session recording is the only mechanism.

## File Structure

```
~/.claude/plugins/cache/claude-plugins-official/superpowers/<version>/skills/
  learning/
    SKILL.md          # The skill definition
```

Hook modification:
```
~/.claude/hooks/memory/
  memory-extract.sh   # Enhanced with learning extraction prompt
```

## Retrieval

Learnings are surfaced in two ways:

1. **Auto-injected**: The existing `memory-query.sh` (UserPromptSubmit hook) already injects relevant memories. Learnings stored via MCP will naturally appear when semantically relevant.
2. **On-demand**: The skill teaches Claude to proactively search learnings before attempting work in areas where past failures occurred.
