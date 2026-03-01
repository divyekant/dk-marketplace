---
name: hermes
description: Use when software has been built and needs audience-specific documentation generated — internal docs (CS/Support), external docs (users/developers), or marketing docs (product marketing/sales). Translates code understanding into documentation for three distinct audiences from a single source.
---

# Hermes

*The messenger who speaks every audience's language.*

## Overview

Hermes generates audience-specific documentation from a single codebase. It analyzes code, docs, specs, git history, and optionally Carto's indexed knowledge to produce structured documentation for three audiences: internal teams (CS/Support), external users (developers/end users), and marketing (product marketing/sales).

**Core principle:** Same source, different lens. Every audience gets fundamentally different documents — different voice, different structure, different level of detail.

**Five modes:**
- **Generate** — full project documentation for all or selected audiences
- **Update** — change-scoped delta since last generation
- **Internal** — internal/CS docs only
- **External** — external/user docs only
- **Marketing** — marketing/sales docs only

## Mode Detection

| Invocation Pattern | Mode |
|-------------------|------|
| "Generate docs for X" / "Document this project" | Generate (all audiences) |
| "Generate internal docs" / "CS documentation" | Internal only |
| "Generate external docs" / "API docs" / "User docs" | External only |
| "Generate marketing docs" / "Feature briefs" / "Datasheet" | Marketing only |
| "Update docs" / "Document what changed" / "Release docs" | Update (delta) |
| "Generate and publish docs" | Generate, then publish |
| No docs exist + user says "document this" | Generate (full) |

**Default behavior:** If `docs/generated/` doesn't exist, always Generate full. If it exists and user says "update" or references a version/release, use Update mode.

## Resume Protocol

Every Hermes invocation starts here. Check disk state before doing any work.

1. Check if `docs/generated/.hermes.md` exists
2. **If no:** Fresh run — proceed to Input Resolution (Step 1)
3. **If yes:** Read `.hermes.md` — check generation state
   - If docs are partially generated (some audiences pending): resume from next pending audience
   - If all audiences are complete and user asked for update: proceed to Update mode
   - If all audiences are complete and user asked for generate: ask "Docs already exist. Regenerate from scratch or update with changes?"

**Key rule:** Never re-generate completed docs unless explicitly asked. Check disk state, skip completed work.

## Document Templates

Templates are stored in separate files by audience. **Read only the template file(s) needed for the current mode.**

| Audience | Template File | Doc Types |
|----------|--------------|-----------|
| Internal | `templates/internal.md` | Feature Handoff, Release Notes, Use Case Docs, FAQ, Troubleshooting Guide, Glossary |
| External | `templates/external.md` | Changelog, API Reference, Feature Docs, Getting Started, Config Reference, Error Reference, Migration Guide, Tutorial, Cookbook |
| Marketing | `templates/marketing.md` | Feature Brief, Product Datasheet, Release Announcement, Sales One-Pager, Blog Post, Social Posts, Email Announcement, Landing Page Copy |

### Template Resolution

Templates support per-project overrides. Resolution order (first match wins):

1. **Project override:** `.hermes/templates/{audience}.md` in the project root
2. **Bundled default:** `templates/{audience}.md` in the skill directory

**How to check:**
- Before loading a template, glob for `.hermes/templates/{audience}.md` in the project root
- If found: use the project override and announce "Using custom {audience} template"
- If not found: use the bundled template from the skill directory

**Override rules:**
- Overrides replace the ENTIRE audience template, not individual doc types within it
- Overrides must follow the same structure as bundled templates (same section headers, same frontmatter fields)
- To customize a single doc type, copy the full bundled template and modify the relevant section

**Setup for a project:**
```bash
mkdir -p .hermes/templates
# Copy a bundled template to customize it:
cp ~/.claude/skills/hermes/templates/internal.md .hermes/templates/internal.md
# Edit to taste, then Hermes will use it automatically
```

### Loading Rules

- **Generate (all):** Read all 3 template files, one at a time as you reach each audience
- **Internal/External/Marketing mode:** Read only that audience's template file
- **Update mode:** Read template files for audiences with changed features
- **Subagent dispatch:** Include the relevant template in the subagent prompt — subagents cannot read files from the skill directory

Template files are located relative to this skill at `templates/internal.md`, `templates/external.md`, and `templates/marketing.md`. Use the Read tool to load them when needed.

---

## Step-by-Step Process

### Step 1: Input Resolution

Resolve input sources in order. Announce what's available.

**1a. Check for Carto index:**
- Search Memories for source prefix `carto/{project-name}/`
- If found: pull entries for `layer:atoms`, `layer:blueprint`, `layer:zones`, `layer:patterns`
- Announce: "Found Carto index for {project} — using full code understanding."
- Set source-tier to `carto`

**1b. Fallback to direct codebase (if no Carto):**
- Glob for key files:
  - Project manifest: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`
  - Documentation: `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`
  - Config: `.apollo.yaml`, `*.config.*`, `.env.example`
  - Source directories: `src/`, `lib/`, `app/`, `api/`, `cmd/`, `pkg/`
  - API specs: `openapi.yaml`, `openapi.json`, `swagger.*`
- Read key files (README, CLAUDE.md, manifest, main entry points)
- Run: `git log --oneline -30` for recent history
- Run: `git tag -l --sort=-version:refname | head -5` for recent versions
- Announce: "No Carto index — reading codebase directly."
- Set source-tier to `direct`

**1c. Context file discovery (always runs):**
- Auto-discover:
  - `docs/plans/*.md` — design documents
  - `docs/decisions/*.md` — decision records
  - `.apollo.yaml` — project config
  - `CHANGELOG.md` — existing changelog
  - `docs/VISION.md` — project vision
- User-specified files: if user mentioned specific files, read those too
- Announce: "Also using {N} context files: {file list}"

**1d. Change detection (Update mode only):**
- Read `.hermes.md` for last generation timestamp
- Run: `git log --oneline --since="{timestamp}"` to find changes
- Run: `git diff --stat {last-commit}..HEAD` to see what files changed
- Identify affected features/components from changed files
- Announce: "{N} commits since last generation affecting {list of areas}"

### Step 2: Feature/Component Discovery

From gathered input, identify what to document.

**If Carto is available (Tier 1):**
- Use Carto zones as the feature grouping — each zone is a documentable feature area
- Use Carto atoms within each zone for detailed behavior
- Use Carto blueprint for the system overview

**If direct codebase (Tier 2):**
- Scan source directories for logical groupings:
  - Route files → user-facing features
  - API handlers → API surface
  - Models/schemas → data entities
  - Config files → configurable behavior
  - CLI commands → CLI surface
- Group related files into feature areas by directory structure and naming
- Read key files to understand purpose

**For both tiers:**
- Build a feature map:
  ```
  Feature: {name}
  Components: {list of files/modules}
  Surface: {ui|api|cli|library|service}
  Description: {1-sentence summary}
  ```

**Present the feature map to the user:**

> **Feature Map:**
>
> **authentication** (4 components)
> - `src/auth/` — login, registration, session management
> - Surface: UI + API
>
> **dashboard** (3 components)
> - `src/dashboard/` — stats, activity feed, widgets
> - Surface: UI
>
> Should I generate docs for all features, or focus on specific ones?

**Wait for user confirmation before proceeding.** The user may scope down.

**Write the state file:**

After user confirms, write `docs/generated/.hermes.md`:

```markdown
# Hermes State

## Configuration
- Source tier: {carto|direct}
- Context files: {list}
- Hermes version: 1.0.0

## Features
| Feature | Components | Status |
|---------|-----------|--------|
| {name} | {count} files | pending |

## Generation Progress
- Internal: pending
- External: pending
- Marketing: pending
- Last generated: never
```

### Step 3: Generate Documentation

**Resolve and read template file(s) now.** For each audience needed:
1. Glob for `.hermes/templates/{audience}.md` in the project root
2. If found: read it (announce "Using custom {audience} template")
3. If not found: read `templates/{audience}.md` from the skill directory

**Chunking: one audience at a time. Features within each audience can be parallel.**

Process audiences in this order: Internal → External → Marketing. This order matters because:
1. Internal docs force you to understand the feature deeply (edge cases, troubleshooting)
2. External docs build on that understanding but simplify for users
3. Marketing docs build on both but reframe for value

**For each audience (or only the selected audience if single-audience mode):**

**3a. Create output directory structure:**
```bash
mkdir -p docs/generated/internal/feature-handoffs
mkdir -p docs/generated/internal/release-notes
mkdir -p docs/generated/internal/use-cases
mkdir -p docs/generated/internal/troubleshooting
mkdir -p docs/generated/external/features
mkdir -p docs/generated/external/migration
mkdir -p docs/generated/marketing/feature-briefs
mkdir -p docs/generated/marketing/release-announcements
mkdir -p docs/generated/marketing/one-pagers
mkdir -p docs/generated/marketing/blog-posts
mkdir -p docs/generated/marketing/social
mkdir -p docs/generated/marketing/emails
mkdir -p docs/generated/marketing/landing-pages
mkdir -p docs/generated/external/tutorials
```

**3b. Generate docs for each confirmed feature:**

For each feature in the feature map, generate the per-feature doc types using the loaded templates:

**Internal per-feature docs:**
- Feature Handoff → `docs/generated/internal/feature-handoffs/fh-{NNN}-{slug}.md`
- Use Case Docs (one per scenario) → `docs/generated/internal/use-cases/uc-{NNN}-{slug}.md`
- Troubleshooting Guide → `docs/generated/internal/troubleshooting/ts-{NNN}-{slug}.md`

**External per-feature docs:**
- Feature Docs → `docs/generated/external/features/feat-{NNN}-{slug}.md`
- Tutorial (one per distinct user scenario) → `docs/generated/external/tutorials/tut-{NNN}-{slug}.md`

**Marketing per-feature docs:**
- Feature Brief → `docs/generated/marketing/feature-briefs/fb-{NNN}-{slug}.md`
- Sales One-Pager → `docs/generated/marketing/one-pagers/op-{NNN}-{slug}.md`
- Blog Post → `docs/generated/marketing/blog-posts/bp-{NNN}-{slug}.md`
- Social Posts → `docs/generated/marketing/social/sp-{NNN}-{slug}.md`
- Email Announcement → `docs/generated/marketing/emails/em-{NNN}-{slug}.md`
- Landing Page Copy → `docs/generated/marketing/landing-pages/lp-{NNN}-{slug}.md`

**3c. Generate cross-feature docs (not per-feature, but per-project):**

| Doc Type | Audience | Output Path |
|----------|----------|-------------|
| Release Notes | Internal | `internal/release-notes/rn-v{version}.md` |
| FAQ | Internal | `internal/faq.md` |
| Glossary | Internal | `internal/glossary.md` |
| Changelog | External | `external/changelog.md` |
| API Reference | External | `external/api-reference.md` |
| Getting Started | External | `external/getting-started.md` |
| Config Reference | External | `external/config-reference.md` |
| Error Reference | External | `external/error-reference.md` |
| Migration Guide | External | `external/migration/v{from}-to-v{to}.md` |
| Cookbook | External | `external/cookbook.md` |
| Product Datasheet | Marketing | `marketing/datasheet.md` |
| Release Announcement | Marketing | `marketing/release-announcements/ra-v{version}.md` |

**3d. After each audience is complete:**
- Update `.hermes.md` — mark audience as `done`, update timestamp
- If single-audience mode: stop here

### Step 4: Generate Index

Write `docs/generated/index.md`:

```markdown
# Hermes Documentation Index

Generated: {timestamp} | Source: {tier} | Hermes v1.0.0

## Internal ({count} docs)
| ID | Type | Topic | Generated |
|----|------|-------|-----------|
| fh-001 | Feature Handoff | {topic} | {date} |
| uc-001 | Use Case | {topic} | {date} |
| ts-001 | Troubleshooting | {topic} | {date} |
| rn-v{ver} | Release Notes | v{ver} | {date} |
| faq | FAQ | All | {date} |
| glossary | Glossary | All | {date} |

## External ({count} docs)
| ID | Type | Topic | Generated |
|----|------|-------|-----------|
| getting-started | Getting Started | All | {date} |
| feat-001 | Feature Doc | {topic} | {date} |
| tut-001 | Tutorial | {topic} | {date} |
| api-ref | API Reference | All | {date} |
| config-ref | Config Reference | All | {date} |
| error-ref | Error Reference | All | {date} |
| changelog | Changelog | All | {date} |
| migration | Migration Guide | v{X}→v{Y} | {date} |
| cookbook | Cookbook | All | {date} |

## Marketing ({count} docs)
| ID | Type | Topic | Generated |
|----|------|-------|-----------|
| fb-001 | Feature Brief | {topic} | {date} |
| op-001 | One-Pager | {topic} | {date} |
| bp-001 | Blog Post | {topic} | {date} |
| sp-001 | Social Posts | {topic} | {date} |
| em-001 | Email Announcement | {topic} | {date} |
| lp-001 | Landing Page | {topic} | {date} |
| ds-001 | Datasheet | Full Product | {date} |
| ra-v{ver} | Release Announcement | v{ver} | {date} |
```

### Step 5: Store in Memories

For each generated document, store a summary in Memories for AI consumption:

```
memory_add(
  source: "hermes/{project}/internal",
  text: "FEATURE-HANDOFF: {feature}. {2-sentence summary}. Generated: {date}. File: {path}."
)

memory_add(
  source: "hermes/{project}/marketing",
  text: "FEATURE-BRIEF: {feature}. ONE-LINER: {one-liner}. KEY-BENEFITS: {benefits}. Generated: {date}. File: {path}."
)

memory_add(
  source: "hermes/{project}/state",
  text: "GENERATION: {date}. Source: {tier}. Features: {count}. Internal: {count} docs. External: {count} docs. Marketing: {count} docs."
)
```

### Step 6: Finalize

Update `.hermes.md` with final state:

```markdown
## Generation Progress
- Internal: done ({count} docs)
- External: done ({count} docs)
- Marketing: done ({count} docs)
- Last generated: {timestamp}
- Last commit: {hash}
- Source tier: {tier}
```

Report to user:

> **Hermes Documentation Generated**
>
> Source: {tier} | Features: {count}
>
> | Audience | Docs | Path |
> |----------|------|------|
> | Internal | {N} | `docs/generated/internal/` |
> | External | {N} | `docs/generated/external/` |
> | Marketing | {N} | `docs/generated/marketing/` |
>
> Review the generated docs, then commit when ready.

---

## Update Mode

For change-scoped documentation (documenting what changed since last generation).

### Step 1: Detect Changes
1. Read `.hermes.md` for last generation timestamp and commit hash
2. Run `git log --oneline {last-commit}..HEAD` to find new commits
3. Run `git diff --name-only {last-commit}..HEAD` to find changed files
4. Map changed files to features using the feature map

### Step 2: Scope
- Only generate docs for features that have changed files
- Announce: "{N} features changed since last generation: {list}"

### Step 3: Generate Deltas
Read the relevant template files, then for each changed feature:
- **Internal:** Generate or update feature handoff, use case docs, troubleshooting guides, release notes, FAQ, glossary
- **External:** Generate or update feature docs, changelog, API reference, config reference, error reference, migration guide, getting started
- **Marketing:** Generate new feature brief for NEW features, update existing briefs for modified features. Sales one-pager for significant new features. Release announcement for new version.

### Step 4: Update State
- Update `.hermes.md` with new timestamp and commit hash
- Update index.md with new/modified entries
- Store updated summaries in Memories

---

## Post-Commit Hook

Hermes can auto-run in update mode after each git commit. This ensures docs stay current without manual invocation.

### Setup

To install the post-commit hook for a project:

```bash
# Create the hook
cat > .git/hooks/post-commit << 'HOOK'
#!/bin/bash
# Hermes post-commit hook — auto-update docs on commit
# To disable temporarily: HERMES_SKIP=1 git commit -m "..."

if [ "$HERMES_SKIP" = "1" ]; then
  exit 0
fi

# Only run if docs/generated exists (Hermes has been initialized)
if [ ! -d "docs/generated" ]; then
  exit 0
fi

# Run Hermes update in background to not block the commit
nohup claude -p "Run hermes update mode on this project. Auto-triggered by post-commit hook. Generate deltas only, no user interaction needed — use the feature map from .hermes.md." > /dev/null 2>&1 &

echo "Hermes: updating docs in background..."
HOOK
chmod +x .git/hooks/post-commit
```

### Teardown

To remove the hook:
```bash
rm .git/hooks/post-commit
```

### Skipping

To skip Hermes for a single commit:
```bash
HERMES_SKIP=1 git commit -m "chore: minor fix"
```

### Conductor Integration

When triggered via Conductor pipeline, the post-commit hook is NOT needed — Conductor handles invocation as part of the `communicate` phase. The hook is for standalone usage outside Conductor.

---

## Parallel Dispatch

When multiple features need documentation, dispatch subagents for parallel generation.

**Main agent responsibilities (NEVER delegated):**
- Input resolution (Step 1)
- Feature discovery (Step 2)
- State file management (.hermes.md)
- Index generation (Step 4)
- Memory storage (Step 5)
- Final reporting (Step 6)

**Subagent responsibilities (one per feature, per audience):**
- Receive: feature name, source files/Carto data, context files, template, voice guidelines
- Generate: one document per the template
- Write: to the correct output path
- Return: summary of what was generated

**Subagent prompt must include:**
1. The complete template for the doc type being generated (copied from the template file — subagents cannot read skill files)
2. Voice guidelines for the audience
3. All source data (file contents, Carto entries) — subagents cannot search Memories
4. Output file path
5. Generation rules

**After all subagents complete:**
1. Verify all expected files exist on disk
2. Generate the index
3. Update .hermes.md
4. Store in Memories

---

## Conductor Integration

Hermes slots into Conductor's pipeline as a `communicate` phase:

```yaml
skills:
  hermes:
    source: external
    phase: communicate
    type: phase

pipelines:
  feature:
    phases: [explore, plan, build, verify, communicate, review, finish]
    skills:
      communicate:
        - hermes
```

When triggered by Conductor:
- Mode defaults to `update` (document what was just built)
- Scope automatically limited to files changed in the current pipeline
- Runs after verify (Delphi), before review

---

## Voice Guide

### Internal Voice
- **Tone:** Practical, direct, thorough
- **Perspective:** Third person ("The system does X") or instructional ("Check the config for Y")
- **Assumption:** Reader is technical enough to understand system behavior but may not know THIS specific feature
- **Priority:** Accuracy over elegance. Be specific: name exact config keys, exact error messages, exact API responses
- **Anti-pattern:** Don't say "the feature works as expected" — describe WHAT it does specifically

### External Voice
- **Tone:** Clear, helpful, encouraging
- **Perspective:** Second person ("You can...", "To do X, run Y")
- **Assumption:** Reader may be new to the project. Don't assume knowledge of internals.
- **Priority:** Clarity over completeness. Lead with the most common use case.
- **Anti-pattern:** Don't expose internal architecture ("the middleware validates your token") — say "your request is authenticated automatically"

### Marketing Voice
- **Tone:** Confident, benefit-focused, concise
- **Perspective:** Product-centric ("Now you can...", "{Product} enables...")
- **Assumption:** Reader cares about outcomes, not mechanisms
- **Priority:** Value over detail. Every sentence should answer "so what?"
- **Anti-pattern:** Don't describe implementation ("built with React and PostgreSQL") — describe value ("instant, responsive interface that handles millions of records")

---

## Quality Checks

Before finalizing any document, verify:

**All docs:**
1. **Frontmatter is complete** — all required fields populated
2. **No placeholder text** — no `{TODO}`, `TBD`, or `[fill in]` remaining
3. **Voice matches audience** — internal docs aren't marketing-speak, marketing docs aren't technical jargon
4. **Cross-references are valid** — links to other docs point to files that exist

**Internal docs:**
5. **Feature Handoff has Common Questions** — never empty, minimum 3 Q&A pairs
6. **Use Case docs have complete flows** — every step has both user action and system response
7. **Troubleshooting has decision paths** — every branch terminates in resolution or escalation
8. **FAQ answers are actionable** — never "it depends" without specifics
9. **Glossary terms are alphabetical** — no exceptions

**External docs:**
10. **Changelog entries are user-facing** — no internal refactors or CI changes unless they affect users
11. **API Reference has curl examples** — every endpoint has a working example
12. **Getting Started works in under 5 steps** — if it takes more, simplify
13. **Config Reference has defaults** — every option shows its default value
14. **Error Reference has resolutions** — every error has actionable fix steps
15. **Migration Guide has before/after** — every breaking change shows old and new code
16. **Tutorials have verification steps** — every tutorial ends with "verify it works" with expected output
17. **Cookbook recipes are copy-pasteable** — no gaps, no `...`, complete working code

**Marketing docs:**
18. **Feature Briefs have Suggested Messaging** — never empty, minimum 2 messages
19. **Datasheet specs are factual** — only include what's verifiable from code/config, not aspirational
20. **One-Pagers are under 400 words** — must fit on one printed page
21. **Release Announcements lead with value** — headline is benefit-focused, not feature-named
22. **No technical jargon in marketing docs** — a VP should understand every word
23. **Blog Posts open with pain, not product** — first paragraph names the problem, not the solution
24. **Social Posts are platform-appropriate** — Twitter under 280 chars, LinkedIn has hashtags
25. **Email subject lines under 60 chars** — test with "would I open this?"
26. **Landing Page has exactly one primary CTA** — don't split attention
