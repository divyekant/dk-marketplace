# Chunked Execution Design: Context-Resilient Delphi

**Date**: 2026-02-27
**Status**: Implemented
**Problem**: Delphi has no strategy for context limits, token limits, or long conversation failures. Both generate and execute modes can exceed context windows on non-trivial projects.

## Design Principles

1. **Disk as source of truth** — all progress persisted to readable Markdown files
2. **Small bounded work units** — each unit fits comfortably in one context window
3. **Idempotent invocation** — re-running always picks up where it left off
4. **No token budget awareness** — chunking is structural, not model-dependent
5. **Visible but non-blocking** — intermediate files exist on disk (user can inspect), but Delphi doesn't pause between batches unless forced

## Discovery Phase

Every Delphi invocation starts by reading (or creating) a discovery file.

**File**: `tests/guided-cases/.discovery.md`

### Contents

```markdown
# Delphi Discovery

## Surfaces
- ui: Login, Dashboard, Settings (3 flows)
- api: /auth, /users, /tasks (3 flows)
- cli: none
- background: cron-cleanup (1 flow)

## Flows
| Flow | Surface | Est. Cases | Status |
|------|---------|-----------|--------|
| auth-login | ui | ~12 | pending |
| auth-api | api | ~8 | done |
| dashboard | ui | ~15 | in_progress |

## Generate Progress
- Total flows: 7
- Completed: 2
- In progress: 1
- Pending: 4

## Execute Progress
- Filter: P0
- Total cases: 34
- Passed: 12
- Failed: 2
- Pending: 20
```

### Behaviors

- Written before any generation or execution begins
- Updated after each flow (generate) or each case batch (execute)
- Any new session reads this file first to determine where to resume
- Estimated case counts are rough (based on coverage matrix dimensions), not exact

## Generate Mode Chunking

**Unit of work: one flow at a time.**

### Process

1. Read `.discovery.md` (or create it if first run)
2. Pick the next `pending` flow, mark it `in_progress`
3. Generate all cases for that flow using the coverage matrix
4. Write each case file to disk immediately as generated (not batched in memory)
5. Update `index.md` with new entries
6. Mark flow `done` in `.discovery.md`
7. Move to next flow

### Resume

Re-invoke Delphi -> reads `.discovery.md` -> skips `done` flows -> picks up next `pending`.

### Redundancy Avoidance

Before generating, scan existing case files in the flow's directory. If cases already exist (partial prior run), generate only the missing coverage types.

## Execute Mode Chunking

**Unit of work: one priority tier per flow.**

### Process

1. Read `.discovery.md` and `index.md`
2. Determine execution scope: filter by priority tier (P0 first, then P1, then P2)
3. Within a tier, execute one flow's cases at a time
4. After each case: write result to report file immediately (append, not rewrite)
5. Update `.discovery.md` execute progress
6. Move to next flow in tier, then next tier

### Resume

Re-invoke Delphi -> reads existing report -> skips cases already recorded -> picks up next unrecorded case.

### Evidence Management

Screenshots and responses saved to `tests/guided-cases/evidence/{case-id}/` — one directory per case. Report references evidence by path, not inline content. This keeps the report file small and context-friendly.

## Resume Protocol

Any Delphi invocation follows the same entry logic:

```
1. Does tests/guided-cases/.discovery.md exist?
   - No -> fresh run, start from discovery
   - Yes -> read it, determine current phase and progress

2. Are all flows generated?
   - No -> resume generate mode from next pending flow
   - Yes -> generation complete

3. Is execution requested?
   - Check report for completed cases
   - Resume from next unrecorded case
```

No special "resume" command needed. Delphi is idempotent by default.

## Generalizable Pattern

This design establishes a reusable pattern for any long-running skill:

| Principle | Implementation |
|-----------|---------------|
| Disk as truth | Progress in readable Markdown files |
| Small work units | One flow (generate) or one priority-tier-per-flow (execute) |
| Idempotent | Re-invocation diffs desired vs. actual, does only remaining work |
| Model-agnostic | No hardcoded token budgets; chunking is structural |

Other skills facing similar context limits can adopt the same pattern: discovery file, bounded work units, disk-persisted progress, idempotent resume.
