---
id: uc-001
type: use-case
audience: internal
topic: first-run-full-generation
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Use Case: First-Run Full Documentation Generation

## Trigger

User invokes Hermes on a project that has never been documented before. No `docs/generated/` directory or `.hermes.md` state file exists.

## Preconditions

- The project has a recognizable structure (at minimum, a README.md or source directory)
- Claude Code is running with access to the project directory
- The Hermes skill is available (either locally in `skills/hermes/skill.md` or via the skill ecosystem)

## Flow

1. **User says:** "Generate docs for this project" or "Document this project"
   **System does:** Detects Generate mode from keywords. Checks for `docs/generated/.hermes.md` — not found. Confirms fresh run.

2. **System does:** Runs Input Resolution:
   - Checks Memories for `carto/{project}/` prefix — if found, uses Tier 1
   - If not found, globs for key files (README, CLAUDE.md, package manifest, src/)
   - Reads key files and recent git history
   - Auto-discovers context files in docs/plans/, docs/decisions/
   **User sees:** "No Carto index — reading codebase directly. Also using 2 context files: VISION.md, hermes-design.md"

3. **System does:** Runs Feature Discovery — analyzes source structure and content to identify documentable features
   **User sees:** Feature map with list of features, component counts, and surface types. Prompt: "Should I generate docs for all features, or focus on specific ones?"

4. **User says:** "All features" (or scopes down)
   **System does:** Creates `docs/generated/` directory structure. Writes initial `.hermes.md` with all features marked `pending`.

5. **System does:** Generates Internal docs (feature handoffs, use cases, troubleshooting for each feature; cross-feature FAQ, glossary, release notes)
   **User sees:** Progress as files are written. State file updated: "Internal: complete"

6. **System does:** Generates External docs (feature docs, getting started, API reference, config reference, error reference, changelog)
   **User sees:** More files written. State file updated: "External: complete"

7. **System does:** Generates Marketing docs (feature briefs, then derived one-pagers, release announcement, datasheet)
   **User sees:** Final batch of files. State file updated: "Marketing: complete"

8. **System does:** Writes `docs/generated/index.md` — master index linking all generated docs with metadata
   **User sees:** Summary: "Generated {N} documents across 3 audiences. See docs/generated/index.md for the full index."

## Variations

- **If Carto index exists:** Step 2 uses Tier 1 instead of Tier 2. Feature discovery in step 3 uses Carto zones rather than directory scanning. Doc quality is higher due to function-level understanding.
- **If user scopes to specific features:** Steps 5-7 only generate docs for the confirmed features. Cross-feature docs (FAQ, glossary, changelog) still include all features for completeness.
- **If user requests single audience:** Steps 5-7 are reduced to just the requested audience. The order still starts from Internal if multiple are requested.

## Edge Cases

- **Empty project (no source files):** Feature discovery produces an empty map. Hermes reports: "No documentable features found. Ensure the project has source code or provide context files." No docs are generated.
- **Project with only a README:** Hermes uses the README as the primary source. Feature discovery may be limited. Generated docs will be thin but structurally correct.
- **Very large project (100+ source files) without Carto:** Tier 2 reads key files but cannot analyze everything. Feature map may be incomplete. Recommend running Carto first for comprehensive results.

## Data Impact

| Data | Action | Location |
|------|--------|----------|
| Generated docs | Created | docs/generated/ (17+ markdown files) |
| State file | Created | docs/generated/.hermes.md |
| Index | Created | docs/generated/index.md |
| Memories (optional) | Created | hermes/{project}/ prefix in Memories MCP |

## CS Notes

- First-run generation is the most common invocation. Users discovering Hermes will almost always start here.
- If a user reports "Hermes generated empty docs," check whether the project has recognizable source structure. A project with only config files and no src/ directory will produce minimal output.
- The feature map confirmation step is important — it prevents Hermes from documenting irrelevant directories (test fixtures, build output, etc.).
