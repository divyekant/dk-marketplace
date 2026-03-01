---
type: faq
audience: internal
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Internal FAQ

## General

### Q: What is Hermes and how does it differ from tools like TypeDoc or Swagger?
**A:** Hermes generates documentation for three distinct audiences (internal, external, marketing) from a single codebase. Tools like TypeDoc and Swagger generate developer reference docs for one audience. Hermes translates technical understanding into audience-specific content — a feature handoff for CS, a user guide for developers, and a feature brief for marketing — all from the same source code analysis.

**Related:** [Multi-Audience Generation](feature-handoffs/fh-001-multi-audience-generation.md)

### Q: Does Hermes require any installation or setup?
**A:** No. Hermes is a single markdown file (`skills/hermes/skill.md`) that runs as a Claude Code skill. There are no dependencies, no build step, and no runtime to install. Just invoke it with "generate docs for this project."

**Related:** [Getting Started](../external/getting-started.md)

### Q: Can Hermes work without Carto?
**A:** Yes. Hermes is Carto-enhanced, not Carto-dependent. Without Carto, it reads the codebase directly (README, source directories, git history). Carto provides richer understanding (function-level detail, dependency graphs), but Hermes works on any project.

**Related:** [Tiered Input Resolution](feature-handoffs/fh-002-tiered-input-resolution.md)

## Usage

### Q: How do I generate docs for just one audience?
**A:** Use audience-specific invocations: "generate internal docs," "generate external docs," or "generate marketing docs." Hermes detects the audience from your keywords and generates only that audience's document set.

**Related:** [Mode System](feature-handoffs/fh-003-mode-system.md)

### Q: How do I update docs after code changes without regenerating everything?
**A:** Say "update docs" or "document what changed." Hermes reads the `.hermes.md` state file to find the last generation timestamp, identifies changed features from git history, and regenerates only the affected docs.

**Related:** [Incremental Update](use-cases/uc-002-incremental-update.md)

### Q: What if Hermes gets interrupted mid-generation?
**A:** Re-invoke Hermes in a new session. It reads `.hermes.md` for progress and resumes from the next pending audience. Completed audiences are not regenerated.

**Related:** [Resume Interrupted Generation](use-cases/uc-003-resume-interrupted-generation.md)

### Q: Can I scope generation to specific features rather than the whole project?
**A:** Yes. During feature discovery, Hermes presents a feature map and asks for confirmation. You can scope down to specific features at that point. Cross-feature docs (FAQ, glossary, changelog) will still reference all features for context.

**Related:** [First-Run Full Generation](use-cases/uc-001-first-run-full-generation.md)

## Output & Quality

### Q: Where do the generated docs go?
**A:** All docs are written to `docs/generated/` in the project root, organized by audience: `internal/`, `external/`, `marketing/`. A master index at `docs/generated/index.md` links to every generated document.

**Related:** [Template System](feature-handoffs/fh-005-template-system.md)

### Q: Are generated docs ready to publish immediately?
**A:** No. All generated docs have `status: draft` in their frontmatter. They are structurally complete and content-rich, but should be reviewed by a human before publishing. Marketing docs especially benefit from human editing for tone and messaging precision.

### Q: Why are some sections of my marketing docs sparse?
**A:** Marketing docs (especially Competitive Context and Proof Points) depend on business context files like competitive analyses, product roadmaps, and customer feedback. Without these, Hermes states what context is needed to populate those sections. Provide the relevant context files and regenerate.

**Related:** [Template System](feature-handoffs/fh-005-template-system.md)

### Q: Can I edit generated docs without them being overwritten on the next run?
**A:** Partially. If you run "update docs," only docs for changed features are regenerated. Docs for unchanged features are not touched. However, if you regenerate from scratch or Hermes detects a feature as changed, your edits will be overwritten. Consider maintaining edits in a separate published version.

## Troubleshooting

### Q: Hermes says "No documentable features found." What do I do?
**A:** The project likely lacks a recognizable source structure. Ensure it has at least a README.md or source directory (src/, lib/, api/). Alternatively, provide context files manually: "Generate docs, also use my-design.md."

**Related:** [Generation Failures](troubleshooting/ts-001-generation-failures.md)

### Q: Hermes uses Tier 2 when I expected Tier 1 (Carto). Why?
**A:** Hermes searches Memories for `carto/{project-directory-name}/`. If the project directory was renamed since Carto indexing, the names won't match. Re-run Carto from the current directory.

**Related:** [Input Resolution Issues](troubleshooting/ts-002-input-resolution-issues.md)

### Q: The changelog has poor quality entries. Can I fix this?
**A:** Changelog quality depends on git commit message quality. Projects using conventional commits (feat:, fix:, chore:) produce better changelogs. For projects with poor commit hygiene, consider providing a manually written CHANGELOG.md as a context file — Hermes will incorporate it.
