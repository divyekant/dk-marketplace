# Design: Learning Staleness Management

**Date:** 2026-02-22
**Status:** Approved
**Problem:** Learnings are append-only. Old/stale learnings are never updated, superseded, or pruned, risking contradictory or outdated advice.

## Research Summary

Explored how AI agent memory systems handle staleness (Mem0, Letta/MemGPT, LangMem, A-Mem, Engram, Kore, FadeMem). Key patterns:

- **Write-time reconciliation** (Mem0): on every new memory, compare to existing and decide add/update/delete/merge
- **Time-based decay** (FadeMem, Engram, Kore): memories lose strength unless accessed; eventually pruned
- **Agent self-editing** (Letta): agent overwrites old memories when contradictions found
- **Periodic review/retire** (Wikipedia bots, enterprise KM): scheduled passes flag or archive old content
- **Metadata tracking** (vector DBs): store created_at, last_used_at, use_count to enable decay/prioritization

**Key insight:** No single mechanism solves all staleness. The most effective systems combine write-time reconciliation with metadata. For this project, Memories MCP already handles most of this OOB.

## Scope

| Backend | Changes |
|---------|---------|
| **Auto-memory files** | Write-time supersede + archive + metadata + retrieval-time age awareness |
| **Memories MCP** | Retrieval-time age awareness only (reconciliation/dedup handled OOB by the API) |

## Auto-memory Files: Write-Time Supersede

### Recording flow

1. Before appending a new learning, scan `learnings.md` for entries with matching category + overlapping keywords in summary/context
2. If a match is found:
   - Move the old entry to `learnings-archive.md` with supersede metadata
   - Write the new entry in its place
3. If no match, append as today

### Entry format (with metadata)

```markdown
## debugging: caffeinate wraps exit codes
<!-- created: 2026-02-22 -->
- **Tried:** Used `caffeinate -dims -- command` which swallowed exit code 129
- **Solution:** Run caffeinate in background (`caffeinate -dims &`) to preserve raw exit codes
- **Context:** Claude Code shell wrapper, zsh, macOS
```

Only `created` date — no `last_used` to avoid noisy edits on every retrieval.

### Archive file format (`learnings-archive.md`)

```markdown
# Archived Learnings

## debugging: old caffeinate workaround
<!-- created: 2026-01-15, superseded: 2026-02-22 -->
<!-- superseded-by: caffeinate wraps exit codes -->
- **Tried:** ...
- **Solution:** ...
- **Context:** ...
```

## Retrieval-Time Age Awareness (Both Backends)

When Claude retrieves learnings before attempting work:

- Parse the created date (from `<!-- created -->` comment for files, from stored timestamp for Memories MCP)
- If older than **6 months**, treat as a lower-confidence hint rather than a reliable fix — verify it still applies before relying on it
- No interactive "is this still valid?" prompt — avoid adding friction
- 6 months is the default staleness threshold; document that users can adjust per their environment (fast-moving projects: 3 months, stable infrastructure: 12 months)

This is a **skill behavior change** (instructions in SKILL.md), not new infrastructure.

## Memories MCP: Minimal Changes

The Memories API already handles:
- Semantic deduplication via `memory_is_novel`
- LLM-based extraction and reconciliation via `/memory/extract`

Only addition: if `memory_is_novel` returns not-novel but the solution clearly differs from the existing learning, Claude should consider superseding (delete old + add new) rather than skipping. This is an edge case instruction in SKILL.md, not new tooling.

## SKILL.md Documentation Updates

1. New `## Superseding a Learning` section (between "Recording" and "Retrieving")
2. Updated `## Retrieving Learnings` with age awareness behavior
3. New `## Limitations by Backend` callout table:

| Capability | Memories MCP | Auto-memory Files |
|---|---|---|
| Semantic dedup | OOB | Keyword-based (imprecise) |
| Supersede detection | OOB | Category + keyword match |
| Age awareness | Via stored timestamps | Via `<!-- created -->` comments |
| Archive | N/A (managed by API) | `learnings-archive.md` |

## What This Does NOT Include

- No time-based decay math (over-engineered for current scale)
- No background pruning hooks (Memories API handles this; files stay manual)
- No `/review-learnings` command (can be added later if needed)
- No changes to `learning-extract.sh` hook (it feeds into Memories API which reconciles OOB)
