---
id: fh-004
type: feature-handoff
audience: internal
topic: state-tracking
status: draft
generated: 2026-02-28
source-tier: direct
context-files: [docs/plans/2026-02-28-hermes-design.md]
hermes-version: 1.0.0
---

# Feature Handoff: State Tracking & Resume

## What It Does

Hermes tracks its generation state in a disk-based file (`.hermes.md`) located at `docs/generated/.hermes.md`. This state file records which audiences have been generated, which features were discovered, what input tier was used, and when the last generation occurred. It enables two critical capabilities: resuming interrupted generation runs and performing incremental (delta) updates based on what changed since the last run.

## How It Works

The state file is a markdown document with structured sections:

```
# Hermes State

## Configuration
- Source tier: direct
- Context files: [VISION.md, hermes-design.md, .apollo.yaml]
- Hermes version: 1.0.0

## Features
| Feature | Components | Status |
|---------|-----------|--------|
| multi-audience-generation | 1 file | complete |
| tiered-input-resolution | 1 file | complete |

## Generation Progress
- Internal: complete
- External: complete
- Marketing: complete
- Last generated: 2026-02-28T14:30:00Z
```

**Resume protocol (runs at every invocation):**
1. Check if `docs/generated/.hermes.md` exists
2. If no: fresh run — proceed to Input Resolution
3. If yes: read state and check progress
   - If partially complete: resume from next pending audience
   - If complete + user said "update": proceed to Update mode
   - If complete + user said "generate": ask whether to regenerate or update

**State transitions:**
- `pending` — audience has not been generated yet
- `in-progress` — generation started but not finished (indicates interrupted run)
- `complete` — all docs for this audience have been written

The state file is written after Feature Discovery (with all features marked `pending`) and updated after each audience completes generation.

## User-Facing Behavior

Users do not interact with the state file directly. Its effects are visible through:
- **Resume behavior** — If Hermes is interrupted mid-generation and re-invoked, it picks up where it left off: "Resuming from External docs (Internal already complete)."
- **Update mode** — Hermes uses the "Last generated" timestamp to identify changes since the last run
- **Re-generation prompt** — When docs are already complete, Hermes asks before overwriting: "Docs already exist. Regenerate from scratch or update with changes?"

## Configuration

| Option | Type | Default | Effect |
|--------|------|---------|--------|
| State file path | path | docs/generated/.hermes.md | Location of the state tracking file |

The state file format is not configurable. It follows a fixed schema.

## Edge Cases & Limitations

- **Manual edits to generated docs are not tracked** — Hermes does not diff its output against existing files. If you manually edit a generated doc and then run "update," Hermes will overwrite your edits for any feature it considers changed.
- **State file corruption** — If `.hermes.md` is malformed or partially written (e.g., due to a crash mid-write), Hermes may fail to parse it. The fix is to delete it and run a fresh generation.
- **Clock dependency** — The "Last generated" timestamp relies on the system clock. If the clock is wrong, update mode may miss changes or re-process unchanged features.
- **No version pinning** — The state file records the Hermes version that generated the docs, but does not enforce compatibility. A newer version of Hermes can resume a run started by an older version, but the doc quality/structure may be inconsistent.

## Common Questions

**Q: Can I delete `.hermes.md` to force a fresh generation?**
A: Yes. Deleting the state file is the clean way to start over. Hermes will treat the next invocation as a first run.

**Q: Does `.hermes.md` get committed to git?**
A: That is up to you. It is generated inside `docs/generated/`, which some projects gitignore. If you want other team members to benefit from incremental updates, commit it. If you prefer clean regeneration every time, gitignore it.

**Q: What happens if I move the generated docs to a different directory?**
A: Hermes will not find the state file at its expected location and will treat the next run as fresh. Move `.hermes.md` along with the docs if you relocate them.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Hermes regenerates everything instead of updating | `.hermes.md` was deleted or is missing | This is expected behavior — without state, Hermes does a full generation |
| "Resuming from..." message when a fresh run was intended | Previous `.hermes.md` exists with partial state | Delete `.hermes.md` before running |
| Update mode finds no changes | "Last generated" timestamp is very recent or in the future | Check the timestamp in `.hermes.md`; delete and regenerate if incorrect |

## Related

- [Mode System](fh-003-mode-system.md) — how modes interact with state
- [Multi-Audience Generation](fh-001-multi-audience-generation.md) — the overall generation flow
