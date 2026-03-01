---
id: ts-002
type: troubleshooting
audience: internal
topic: input-resolution-issues
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Troubleshooting: Input Resolution Issues

## Symptoms

- "No Carto index" message when Carto has been run on the project
- Context files not being detected
- "Reading codebase directly" when Tier 1 was expected
- Sparse or inaccurate feature discovery

## Quick Check

1. Check the project directory name — Hermes searches Memories for `carto/{directory-name}/`. If the project directory was renamed after Carto indexing, the names won't match. Fix: run Carto again from the current directory, or manually note the Carto project name.

2. If not a Carto issue, check that context files are in expected locations: `docs/plans/`, `docs/decisions/`, or project root.

## Diagnostic Steps

### Step 1: Verify Carto index existence
- **Run:** Search Memories for `carto/` prefix
- **If entries exist with a different project name:** Carto used a different name. Hermes is looking for `carto/{current-dir-name}/`.
- **If no entries at all:** Carto has not been run. Tier 2 is correct.
- **If entries match:** Proceed to Step 2 — something else is wrong.

### Step 2: Verify context file locations
- **Run:** `ls docs/plans/ docs/decisions/ 2>/dev/null` and `ls *.md` in project root
- **If files exist in non-standard locations:** Hermes only auto-discovers `docs/plans/`, `docs/decisions/`, `.apollo.yaml`, `CHANGELOG.md`, `docs/VISION.md`. Files elsewhere must be specified manually.
- **If files are in expected locations:** Hermes should find them. Check if the skill.md is the latest version with context discovery logic.

### Step 3: Check git availability
- **Run:** `git log --oneline -5`
- **If git is not initialized or no commits:** Hermes cannot parse git history. Changelog and release notes will be minimal.
- **If git works:** Git-dependent features should work normally.

## Resolutions

### Carto project name mismatch
- **Fix:** Re-run Carto from the current project directory so the stored project name matches
- **Verify:** Search Memories for `carto/{current-dir-name}/` — entries should appear
- **Prevent:** Always run Carto from the same directory you will run Hermes from

### Missing context files
- **Fix:** Either move files to `docs/plans/` or specify them explicitly: "Generate docs, also use path/to/my-design.md"
- **Verify:** Hermes should announce "Also using {N} context files: {list}"
- **Prevent:** Follow the convention of placing design docs in `docs/plans/` and decisions in `docs/decisions/`

### No git history
- **Fix:** Initialize git and make at least one commit, or provide a CHANGELOG.md as a context file
- **Verify:** Changelog and release notes sections should populate from git or the provided changelog
- **Prevent:** Use git from the start of the project

## Escalation

- **Escalate to:** Carto skill maintainer (for Tier 1 issues) or Hermes skill maintainer (for Tier 2/3 issues)
- **Include:** Output of `ls -la` in project root, Memories search results for `carto/`, and the Hermes invocation used
- **SLA:** Not applicable

## Related

- [Tiered Input Resolution](../feature-handoffs/fh-002-tiered-input-resolution.md)
- [First-Run Full Generation](../use-cases/uc-001-first-run-full-generation.md)
