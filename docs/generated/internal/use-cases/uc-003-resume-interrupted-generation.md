---
id: uc-003
type: use-case
audience: internal
topic: resume-interrupted-generation
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Use Case: Resume Interrupted Generation

## Trigger

User re-invokes Hermes after a previous generation was interrupted (session ended, context window exhausted, or crash). The state file exists with partial progress.

## Preconditions

- `docs/generated/.hermes.md` exists with at least one audience marked `pending` or `in-progress`
- Previously generated docs for completed audiences still exist on disk
- The project codebase has not changed significantly since the interrupted run

## Flow

1. **User says:** "Generate docs" or "Resume docs" or simply re-invokes Hermes
   **System does:** Reads `.hermes.md`. Finds partial state — e.g., Internal: complete, External: in-progress, Marketing: pending.

2. **System does:** Announces the resume: "Found partial generation. Internal docs complete. Resuming from External docs."
   **User sees:** Confirmation of what is already done and what remains.

3. **System does:** Re-runs Input Resolution to refresh context (the codebase may have changed slightly), then continues generating from the next pending audience.
   **User sees:** New files being written for the remaining audiences.

4. **System does:** Completes all audiences, updates `.hermes.md` to fully complete, writes/updates index.md.
   **User sees:** "Generation complete. {N} total documents across 3 audiences."

## Variations

- **User wants to start fresh instead of resuming:** User says "Regenerate from scratch." Hermes deletes `.hermes.md` and all existing generated docs, then starts a full generation.
- **Codebase changed between interruption and resume:** Hermes re-runs Input Resolution and may discover new features or changes. It merges these into the existing feature map and generates docs for them as part of the resume.

## Edge Cases

- **State says "in-progress" for an audience:** This means generation was interrupted mid-audience. Hermes cannot determine which individual docs were written. It regenerates the entire audience (some files may be overwritten with identical content).
- **Generated files were manually deleted but state still shows complete:** Hermes trusts the state file over disk. It will skip the "complete" audience. To force regeneration, delete `.hermes.md`.
- **Multiple interrupted runs:** Only the latest state matters. Each Hermes invocation updates `.hermes.md` with its own state.

## Data Impact

| Data | Action | Location |
|------|--------|----------|
| Remaining audience docs | Created | docs/generated/ (pending audiences only) |
| State file | Updated | docs/generated/.hermes.md (all audiences → complete) |
| Index | Updated | docs/generated/index.md |

## CS Notes

- Resume is automatic — users do not need to do anything special. Just re-invoke Hermes and it picks up where it left off.
- If a user reports that some docs are missing, check `.hermes.md` for the generation progress. Audiences marked `pending` were never started.
- The most common reason for interruption is context window limits in long Claude Code sessions. Recommend breaking large projects into single-audience mode runs to manage context usage.
