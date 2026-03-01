# Learning Staleness Management Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add write-time superseding and retrieval-time age awareness to the learning skill so old learnings get updated instead of accumulating forever.

**Architecture:** Update SKILL.md with new sections for superseding (auto-memory files get full flow, Memories MCP gets edge-case instruction) and age awareness (both backends). Add limitations table. Update README to document the new behavior.

**Tech Stack:** Markdown (SKILL.md skill definition), shell (no changes to hook)

---

### Task 1: Update Auto-memory Files Entry Format with Metadata

**Files:**
- Modify: `skill/SKILL.md:59-72` (the "With Auto-memory Files" recording section)

**Step 1: Update the auto-memory files append format**

Change the current append format in the "With Auto-memory Files" section from:

```markdown
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
```

To:

```markdown
### With Auto-memory Files

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
```

**Step 2: Verify the edit reads correctly**

Read `skill/SKILL.md` and confirm:
- The `<!-- created: YYYY-MM-DD -->` line appears in the append format
- Step 2 (supersede check) is present between read and append
- The section flows logically: read → check → append

**Step 3: Commit**

```bash
git add skill/SKILL.md
git commit -m "feat: add metadata and supersede check to auto-memory recording"
```

---

### Task 2: Add Superseding a Learning Section

**Files:**
- Modify: `skill/SKILL.md` (insert new section between "Recording a Learning" and "Retrieving Learnings")

**Step 1: Add the supersede section**

Insert the following new section after "Recording a Learning" (after the auto-memory files recording steps) and before "Retrieving Learnings":

```markdown
## Superseding a Learning

When a new learning covers the same problem as an existing one but with a different/better solution, supersede rather than duplicate.

### With Memories MCP

The Memories API handles reconciliation OOB via `memory_is_novel` and its dedup logic.

**Edge case:** If `memory_is_novel` returns not-novel, but you can see the existing learning has a clearly different (worse or outdated) solution:
1. `mcp__memories__memory_search(query="<summary>", k=3)` to find the existing entry
2. `mcp__memories__memory_delete(id=<old_learning_id>)` to remove it
3. `mcp__memories__memory_add(...)` to record the new learning

This should be rare — only when you're confident the new solution supersedes the old one.

### With Auto-memory Files

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
```

**Step 2: Verify the section placement**

Read `skill/SKILL.md` and confirm:
- "Superseding a Learning" appears between "Recording a Learning" and "Retrieving Learnings"
- Both backend paths are documented
- The auto-memory archive format matches the design doc

**Step 3: Commit**

```bash
git add skill/SKILL.md
git commit -m "feat: add superseding section for both backends"
```

---

### Task 3: Add Retrieval-Time Age Awareness

**Files:**
- Modify: `skill/SKILL.md` (update "Retrieving Learnings" section)

**Step 1: Update the retrieving section**

Replace the current "Retrieving Learnings" section:

```markdown
## Retrieving Learnings

Before attempting work in a problem area, search for relevant past learnings:

### With Memories MCP
```
mcp__memories__memory_search(query="<description of what you're about to do>", k=5)
```

### With Auto-memory Files
Read `learnings.md` and scan for relevant entries.
```

With:

```markdown
## Retrieving Learnings

Before attempting work in a problem area, search for relevant past learnings:

### With Memories MCP
```
mcp__memories__memory_search(query="<description of what you're about to do>", k=5)
```

### With Auto-memory Files
Read `learnings.md` and scan for relevant entries.

### Age Awareness

When reviewing retrieved learnings, check how old they are:
- **Auto-memory files:** Parse the `<!-- created: YYYY-MM-DD -->` comment
- **Memories MCP:** Check the stored timestamp on the returned entry

**If a learning is older than 6 months:** treat it as a lower-confidence hint. Verify it still applies to the current environment before relying on it. Don't discard it — just confirm before trusting it.

> **Configurable:** 6 months is the default staleness threshold. Fast-moving projects (frequent dependency updates) may want 3 months. Stable infrastructure may be fine with 12 months.
```

**Step 2: Verify the edit reads correctly**

Read `skill/SKILL.md` and confirm:
- Age awareness subsection appears under "Retrieving Learnings"
- Both backends are covered
- The 6-month default and configurability note are present

**Step 3: Commit**

```bash
git add skill/SKILL.md
git commit -m "feat: add retrieval-time age awareness for both backends"
```

---

### Task 4: Add Limitations by Backend Table

**Files:**
- Modify: `skill/SKILL.md` (add new section before "When to Record" checklist)

**Step 1: Add the limitations table**

Insert the following section before the "When to Record (Checklist)" section:

```markdown
## Limitations by Backend

| Capability | Memories MCP | Auto-memory Files |
|---|---|---|
| Semantic dedup | OOB | Keyword-based (imprecise) |
| Supersede detection | OOB | Category + keyword match |
| Age awareness | Via stored timestamps | Via `<!-- created -->` comments |
| Archive | N/A (managed by API) | `learnings-archive.md` |

**Note:** Auto-memory files use keyword matching for supersede detection, which may miss semantically similar but differently worded learnings. Memories MCP handles this via semantic search. If you notice duplicate or contradictory learnings accumulating in auto-memory files, manually clean up `learnings.md`.
```

**Step 2: Verify placement**

Read `skill/SKILL.md` and confirm:
- Table appears before "When to Record (Checklist)"
- The note about auto-memory limitations is present

**Step 3: Commit**

```bash
git add skill/SKILL.md
git commit -m "feat: add backend limitations table to skill"
```

---

### Task 5: Update README

**Files:**
- Modify: `README.md` (update "How It Works" and storage backends sections)

**Step 1: Update the storage backends table**

In the "Two storage backends" section, update the table from:

```markdown
| Backend | Dependencies | Features |
|---------|-------------|----------|
| **Auto-memory files** | None (built into Claude Code) | Appends to `learnings.md` in project memory directory |
| **[Memories](https://github.com/divyekant/memories) MCP** | Memories server | Semantic search, deduplication, cross-project retrieval |
```

To:

```markdown
| Backend | Dependencies | Features |
|---------|-------------|----------|
| **Auto-memory files** | None (built into Claude Code) | Appends to `learnings.md`, supersedes old learnings to `learnings-archive.md`, keyword-based dedup |
| **[Memories](https://github.com/divyekant/memories) MCP** | Memories server | Semantic search, deduplication, cross-project retrieval, staleness handled OOB |
```

**Step 2: Add staleness management note**

After the "Two storage backends" section (and its table), add:

```markdown
### Staleness management

Learnings don't just accumulate — when Claude finds a better fix for a known problem, it supersedes the old learning:

- **Memories MCP:** Reconciliation and dedup are handled by the API. Old learnings are updated automatically.
- **Auto-memory files:** Old entries are moved to `learnings-archive.md` and the new fix takes their place in `learnings.md`.

Both backends apply age awareness: learnings older than 6 months are treated as lower-confidence hints that should be verified before relying on.
```

**Step 3: Verify README reads correctly**

Read `README.md` and confirm:
- Updated storage backends table
- Staleness management section is present under "How It Works"
- No broken markdown

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: document staleness management in README"
```

---

### Task 6: Final Review and Push

**Step 1: Read the complete SKILL.md end-to-end**

Read `skill/SKILL.md` and verify the full document flows logically:
1. Overview → When to Use → Schema → Backend Detection
2. Recording a Learning (with supersede check for auto-memory files)
3. Superseding a Learning (both backends)
4. Retrieving Learnings (with age awareness)
5. Limitations by Backend
6. When to Record → Red Flags → Quick Reference

**Step 2: Read README.md end-to-end**

Confirm the README is consistent with the updated SKILL.md.

**Step 3: Push**

```bash
git push origin main
```
