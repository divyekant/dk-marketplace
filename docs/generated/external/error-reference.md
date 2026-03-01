---
type: error-reference
audience: external
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Error Reference

## Error Format

Hermes communicates errors through natural language messages within the Claude Code session. There are no error codes or structured error responses — Hermes is a skill, not an API. Errors appear as descriptive messages explaining what went wrong and what to do about it.

## Errors

### No Documentable Features Found

- **Message:** "No documentable features found. Ensure the project has source code or provide context files."
- **Cause:** The project directory lacks recognizable source structure. No README.md, no source directories (src/, lib/, api/), no package manifests, and no Carto index available.
- **Resolution:**
  1. Ensure your project has at least a README.md describing its features
  2. Organize source code into standard directories (src/, lib/, app/)
  3. Alternatively, provide context files manually: "Generate docs, also use my-design-doc.md"
  4. For the best results, run Carto to index the project first

### No Carto Index Found

- **Message:** "No Carto index — reading codebase directly."
- **Cause:** Hermes checked Memories MCP for `carto/{project-name}/` and found no entries. This is informational, not an error — Hermes falls back to Tier 2.
- **Resolution:** This is normal for projects that have not been indexed by Carto. To get Tier 1 quality:
  1. Run Carto on the project: "Index this project with Carto"
  2. Re-run Hermes after Carto completes

### State File Corrupted

- **Message:** "State file corrupted — running fresh generation."
- **Cause:** The `.hermes.md` file at `docs/generated/.hermes.md` is malformed, truncated, or contains unparseable content. This can happen if a previous run crashed mid-write.
- **Resolution:**
  1. Delete the state file: `rm docs/generated/.hermes.md`
  2. Re-run Hermes — it will perform a fresh generation
  3. If the issue recurs, check for disk space issues or file system errors

### Docs Already Exist

- **Message:** "Docs already exist. Regenerate from scratch or update with changes?"
- **Cause:** You invoked Hermes with a "generate" keyword on a project that already has complete documentation. Hermes asks for clarification to avoid accidentally overwriting existing docs.
- **Resolution:** Choose one:
  - "Regenerate from scratch" — deletes existing docs and generates fresh
  - "Update with changes" — uses Update mode to generate delta only
  - "Update docs" — skip this prompt by using update-specific keywords

### No Changes Since Last Generation

- **Message:** "No changes since last generation on {date}. Nothing to update."
- **Cause:** Update mode checked git history since the last generation timestamp and found no new commits.
- **Resolution:** This is expected when nothing has changed. If you believe there are changes:
  1. Check the "Last generated" timestamp in `.hermes.md` — it may be more recent than expected
  2. Verify git history: `git log --oneline --since="{timestamp}"`
  3. If the timestamp is wrong, delete `.hermes.md` and run a fresh generation

### Feature Appears Removed

- **Message:** "Feature {name} appears to have been removed. Delete its docs?"
- **Cause:** During an update run, Hermes detected that source files for a previously documented feature no longer exist.
- **Resolution:** Confirm whether to delete the feature's documentation:
  - "Yes, delete them" — removes the feature's generated docs
  - "No, keep them" — preserves existing docs even though the source is gone
  - If the feature was renamed, not deleted, tell Hermes: "It was renamed to {new-name}"

### Partial Generation (Interrupted)

- **Message:** "Found partial generation. {Audience} docs complete. Resuming from {next audience} docs."
- **Cause:** A previous Hermes run was interrupted (session ended, context exhausted) before all audiences were completed.
- **Resolution:** This is automatic recovery. Hermes resumes from where it left off. If you want a fresh start instead, say "Regenerate from scratch" or delete `.hermes.md`.
