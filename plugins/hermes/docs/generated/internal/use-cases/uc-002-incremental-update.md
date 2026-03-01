---
id: uc-002
type: use-case
audience: internal
topic: incremental-update
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Use Case: Incremental Documentation Update

## Trigger

User invokes Hermes in Update mode after documentation has already been generated. The project has changed (new commits, modified features) since the last generation, and the user wants docs to reflect those changes without regenerating everything.

## Preconditions

- `docs/generated/.hermes.md` exists with a valid "Last generated" timestamp
- Git history is available with commits since the last generation
- Previous generation completed successfully (all audiences marked `complete`)

## Flow

1. **User says:** "Update docs" or "Document what changed" or "Update docs since v1.1"
   **System does:** Detects Update mode. Reads `.hermes.md` for last generation timestamp and feature list.

2. **System does:** Runs change detection:
   - `git log --oneline --since="{last-generated-timestamp}"` to find new commits
   - `git diff --stat {last-commit}..HEAD` to identify changed files
   - Maps changed files to features in the feature map
   **User sees:** "{N} commits since last generation affecting {list of features}"

3. **System does:** Presents the affected features and asks for confirmation:
   **User sees:** "These features have changed: [list]. Update docs for all of them?"

4. **User says:** "Yes" (or scopes down)
   **System does:** Regenerates only the docs for affected features — all audiences, but only for changed features.

5. **System does:** Updates cross-feature docs (FAQ, glossary, changelog) to reflect changes
   **User sees:** Updated files listed. Changelog appended with new version section.

6. **System does:** Updates `.hermes.md` with new timestamp and updates index.md
   **User sees:** "Updated {N} documents. Changelog updated through {latest commit}."

## Variations

- **Version-scoped update:** User says "Document what changed since v1.0." Hermes uses git tags instead of timestamp: `git log v1.0..HEAD`.
- **Single-audience update:** User says "Update internal docs." Only internal doc types are regenerated for affected features.
- **No changes detected:** If git log shows no commits since last generation, Hermes reports: "No changes since last generation on {date}. Nothing to update."

## Edge Cases

- **Feature added since last run:** A new directory or module exists that was not in the original feature map. Hermes detects this as a new feature, adds it to the map, and generates full docs for it (not just a delta).
- **Feature removed since last run:** Files for a previously documented feature were deleted. Hermes flags this: "Feature {name} appears to have been removed. Delete its docs?" Waits for confirmation.
- **Renamed files:** If files were renamed (git detects as rename), Hermes updates the feature mapping and regenerates docs for the affected feature.
- **Corrupted state file:** If `.hermes.md` is malformed, Hermes falls back to a fresh generation and warns: "State file corrupted — running fresh generation."

## Data Impact

| Data | Action | Location |
|------|--------|----------|
| Affected feature docs | Updated | docs/generated/ (only changed features) |
| Changelog | Appended | docs/generated/external/changelog.md |
| Release notes | Created | docs/generated/internal/release-notes/rn-v{version}.md (if version-scoped) |
| State file | Updated | docs/generated/.hermes.md (new timestamp) |
| Index | Updated | docs/generated/index.md |

## CS Notes

- Update mode is the day-to-day usage pattern after initial generation. It should be fast since it only touches changed features.
- If a user says "update" but Hermes does a full regeneration, check whether `.hermes.md` exists. Without state, Hermes cannot do delta — it falls back to full.
- The changelog is the most visible output of update mode. Ensure users understand it is auto-generated from git history and may need editing for polish.
