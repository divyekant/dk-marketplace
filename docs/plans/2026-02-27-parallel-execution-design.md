# Parallel Execution for Delphi Execute Mode

**Date**: 2026-02-27
**Status**: Approved

## Problem

Delphi's execute mode runs all cases sequentially — one case at a time, one flow at a time. For projects with many flows, this is slow. API/CLI/background cases have no shared resource constraint and can safely run concurrently.

## Design

Same subagent-per-flow pattern as generate mode, with one constraint: UI-surface flows cannot parallelize on the browser.

### Flow Classification

Before dispatch, scan the case list and bucket flows:

| Bucket | Criteria | Execution |
|--------|----------|-----------|
| **Parallel** | Flow has ZERO `ui` surface cases | One subagent per flow, all dispatched concurrently |
| **Sequential** | Flow has ANY `ui` surface case | Run one flow at a time on the shared browser |

Mixed flows (e.g., auth with both UI and API cases) go to the sequential bucket. No splitting a flow across execution strategies.

### Dispatch Model

```
Execute Mode Step 3 (revised)
├── Classify flows by surface type
│   ├── UI flows → sequential queue
│   └── API/CLI/background flows → parallel dispatch
├── Dispatch parallel subagents (one per non-UI flow)
│   └── Each writes .report-fragment.md + evidence/
├── Run UI flows sequentially (after or concurrently with dispatch)
│   └── Each writes .report-fragment.md + evidence/
├── Merge all fragments into final report
└── Update .discovery.md + index.md
```

### Subagent Contract

Each subagent receives:
- Flow name, case files (full content), execution strategy per surface type
- Evidence output path: `tests/guided-cases/evidence/`
- Fragment output path: `tests/guided-cases/[flow-name]/.report-fragment.md`

Each subagent:
1. Executes all cases for its flow in priority order (P0 → P1 → P2)
2. Writes evidence to `evidence/gc-XXX/` per case
3. Writes `.report-fragment.md` with per-case results
4. **MUST NOT** write to the main report, `.discovery.md`, or `index.md`

### Report Merge

After all subagents + sequential UI flows complete:
1. Read all `.report-fragment.md` files
2. Merge into `tests/guided-cases/reports/YYYY-MM-DD-HH-MM-report.md`
3. Compute aggregate stats (passed/failed/skipped counts + percentages)
4. Update `index.md` case statuses
5. Update `.discovery.md` execute progress
6. Clean up fragment files

### Resume Handling

Same pattern as generate mode resume:
- On resume, read existing report + fragments
- Cases already recorded → skip
- Fragments from crashed subagents → partial results preserved, re-dispatch only unrecorded cases

## Decisions

1. **Parallel unit**: Flows (mirrors generate mode)
2. **UI conflict resolution**: UI flows run sequentially, API/CLI/background flows parallel
3. **Report coordination**: Fragment files per flow, merged after completion
