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

```
[LEARNING] <category>: <one-line summary>
TRIED: <what was attempted and why it didn't work>
SOLUTION: <what actually worked>
CONTEXT: <project/tool/language>
```

**Categories:** `debugging`, `implementation`, `infra/config`, `api-usage`, `tooling`

## Storage Backend Detection

**Check once per session:**

1. If `mcp__memories__memory_add` tool is available → use **Memories MCP**
2. Otherwise:
   - In Claude Code → use **Auto-memory files**
   - In other hosts (including Codex) → explain that the file fallback is unavailable there and that Memories MCP must be configured

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

### With Auto-memory Files (Claude Code only)

1. **Read existing learnings:**
   Read `~/.claude/projects/<project-path>/memory/learnings.md`

2. **Check for supersede candidate:**
   Scan existing entries for one with the same category AND overlapping keywords in the summary or context.
   - If a match exists with a **different solution** → go to "Superseding a Learning" below
   - If a match exists with the **same solution** → skip (already recorded)
   - If no match → continue to step 3

3. **Append:**
   Edit the file to append:
   ```
   ## <category>: <one-line summary>
   <!-- created: YYYY-MM-DD -->
   - **Tried:** <what failed>
   - **Solution:** <what worked>
   - **Context:** <project/tool>
   ```

## Superseding a Learning

When a new learning covers the same problem as an existing one but with a different/better solution, supersede rather than duplicate.

### With Memories MCP

The Memories API handles reconciliation out-of-the-box (OOB) via `memory_is_novel` and its dedup logic.

**Edge case:** If `memory_is_novel` returns not-novel, but you can see the existing learning has a clearly different (worse or outdated) solution:
1. `mcp__memories__memory_search(query="<summary>", k=3)` to find the existing entry
2. `mcp__memories__memory_delete(id=<old_learning_id>)` to remove it
3. `mcp__memories__memory_add(...)` to record the new learning

This should be rare — only when you're confident the new solution supersedes the old one.

### With Auto-memory Files (Claude Code only)

1. **Archive the old entry:**
   Read `~/.claude/projects/<project-path>/memory/learnings-archive.md` (create if it doesn't exist).
   Append the old entry with supersede metadata:
   ```
   ## <old category>: <old summary>
   <!-- created: <old date>, superseded: YYYY-MM-DD -->
   <!-- superseded-by: <new summary> -->
   - **Tried:** <old tried>
   - **Solution:** <old solution>
   - **Context:** <old context>
   ```

2. **Remove old entry from learnings.md:**
   Edit `learnings.md` to remove the old entry (the full block from `##` to the next `##` or end of file).

3. **Write new entry to learnings.md:**
   Append the new learning with the standard format (including `<!-- created: YYYY-MM-DD -->`).

## Retrieving Learnings

Before attempting work in a problem area, search for relevant past learnings:

### With Memories MCP
```
mcp__memories__memory_search(query="<description of what you're about to do>", k=5)
```

### With Auto-memory Files (Claude Code only)
Read `learnings.md` and scan for relevant entries.

### Age Awareness

When reviewing retrieved learnings, check how old they are:
- **Auto-memory files:** Parse the `<!-- created: YYYY-MM-DD -->` comment
- **Memories MCP:** Check the stored timestamp on the returned entry

**If a learning is older than 6 months:** treat it as a lower-confidence hint. Verify it still applies to the current environment before relying on it. Don't discard it — just confirm before trusting it.

> **Configurable:** 6 months is the default staleness threshold. Fast-moving projects (frequent dependency updates) may want 3 months. Stable infrastructure may be fine with 12 months.

## Limitations by Backend

| Capability | Memories MCP | Auto-memory Files (Claude Code only) |
|---|---|---|
| Semantic dedup | OOB | Keyword-based (imprecise) |
| Supersede detection | OOB | Category + keyword match |
| Age awareness | Via stored timestamps | Via `<!-- created -->` comments |
| Archive | N/A (managed by API) | `learnings-archive.md` |

**Note:** Auto-memory files use keyword matching for supersede detection, which may miss semantically similar but differently worded learnings. Memories MCP handles this via semantic search. If you notice duplicate or contradictory learnings accumulating in auto-memory files, manually clean up `learnings.md`.

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
| 2 | Check: is this already recorded? If same problem, different fix → supersede |
| 3 | Record: use the [LEARNING] schema (with `<!-- created -->` date for auto-memory files) |
| 4 | Before similar work: search past learnings |
| 5 | Age check: learnings older than 6 months → verify before trusting |
