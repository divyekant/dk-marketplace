---
type: glossary
audience: internal
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Glossary

### Atom
**Definition:** A function-level unit of code understanding as indexed by Carto. Represents the smallest documentable behavior in a codebase.
**Context:** Used in Tier 1 input resolution when a Carto index is available. Atoms provide detailed behavioral understanding for feature handoffs and use case docs.
**Also known as:** Carto atom
**Not to be confused with:** Feature (which is a higher-level grouping of multiple atoms)

### Audience
**Definition:** One of three target groups for Hermes documentation: internal (CS/Support/Engineering), external (developers/end users), or marketing (product marketing/sales).
**Context:** Each audience receives a different set of document types with different voice, structure, and detail level. The audience is the primary axis for organizing Hermes output.

### Blueprint
**Definition:** A system-level architecture overview as indexed by Carto. Describes how major components relate to each other.
**Context:** Used in Tier 1 input resolution to inform system overviews and cross-feature documentation.
**Not to be confused with:** Feature map (which Hermes builds from either Carto or direct analysis)

### Carto
**Definition:** A code indexing skill in the skill ecosystem that analyzes source code at multiple layers (atoms, blueprint, zones, patterns) and stores the index in Memories MCP.
**Context:** Hermes checks for Carto indexes as its first-tier input source. Carto-indexed projects produce richer documentation.
**Also known as:** Carto index (when referring to the stored data)

### Claude Code
**Definition:** Anthropic's CLI tool for interacting with Claude in a development context. The runtime environment in which Hermes operates as a skill.
**Context:** All Hermes invocations happen within Claude Code sessions. Claude Code provides file system access, git integration, and Memories MCP connectivity.

### Conductor
**Definition:** An orchestration skill that manages multi-phase development pipelines. Can invoke Hermes as the "communicate" phase.
**Context:** Hermes integrates with Conductor as a pipeline phase: after build and verify, Conductor triggers Hermes to generate documentation.

### Context Files
**Definition:** Supplementary documents (design docs, PRDs, vision statements, competitive analyses) that provide business context not derivable from code alone.
**Context:** Tier 3 input source. Always layers on top of Carto or direct codebase analysis. Auto-discovered from `docs/plans/`, `docs/decisions/`, or user-specified.

### Delta Generation
**Definition:** Generating documentation only for features that changed since the last run, rather than regenerating everything.
**Context:** Triggered by Update mode. Uses git history and `.hermes.md` state to identify changes. Synonym for incremental update.
**Also known as:** Incremental update, change-scoped generation

### Feature Brief
**Definition:** The keystone marketing document. Defines what a feature is, who it is for, why it matters, and how it differs from alternatives. Other marketing docs derive from it.
**Context:** Generated per feature in the marketing audience. Used by product marketing and sales teams. The Suggested Messaging section provides ready-to-use copy.

### Feature Discovery
**Definition:** The process of identifying documentable features from a codebase. Maps source files and directories to logical feature areas.
**Context:** Step 2 of the Hermes pipeline. Uses Carto zones (Tier 1) or directory structure analysis (Tier 2) to build a feature map.

### Feature Handoff
**Definition:** An internal document that transfers knowledge about a feature from engineering to CS/Support. Covers what it does, how it works, edge cases, config, troubleshooting, and common questions.
**Context:** The highest-priority internal doc type. Addresses the #1 pain point in software orgs: the engineering-to-CS knowledge gap.

### Feature Map
**Definition:** A structured list of documentable features discovered by Hermes, including component files, surface type (UI/API/CLI), and description.
**Context:** Built during Feature Discovery, presented to the user for confirmation before generation begins. Stored in `.hermes.md`.

### Frontmatter
**Definition:** YAML metadata at the top of every generated markdown document, enclosed in `---` delimiters. Contains id, type, audience, topic, status, generation date, source tier, and Hermes version.
**Context:** Every Hermes doc has frontmatter. Used for programmatic parsing, indexing, and tracking document lineage.

### Hermes State File
**Definition:** The `.hermes.md` file at `docs/generated/.hermes.md` that tracks generation configuration, feature map, and per-audience progress.
**Context:** Enables resume on interrupted runs and delta detection for updates. Written after feature discovery, updated after each audience completes.
**Also known as:** `.hermes.md`, state file

### Keystone Document
**Definition:** A document from which other documents are derived. In Hermes, the Feature Brief is the keystone for marketing docs — sales one-pagers and release announcements draw from it.
**Context:** Marketing generation produces feature briefs first, then derives other marketing doc types from them.

### Mode
**Definition:** One of five operational states for Hermes: Generate (full), Update (delta), Internal, External, or Marketing.
**Context:** Detected from invocation keywords. Controls which audiences and doc types are generated.
**Not to be confused with:** Audience (mode selects scope; audience selects voice and template set)

### Skill
**Definition:** A markdown-based capability definition for Claude Code. A single file containing instructions, templates, and logic that Claude Code follows when invoked.
**Context:** Hermes is a skill. Other skills in the ecosystem include Apollo (scaffold), Carto (index), Delphi (test), and Conductor (orchestrate).

### Source Tier
**Definition:** The input quality level used for a generation run: `carto` (Tier 1, best), `direct` (Tier 2, good), or `context` (Tier 3, minimal).
**Context:** Recorded in the frontmatter of every generated document. Provides traceability for how each doc was produced.

### Zone
**Definition:** A feature-level grouping of related code as indexed by Carto. Represents a domain area within a codebase.
**Context:** Used in Tier 1 feature discovery. Each Carto zone maps to a documentable feature area.
