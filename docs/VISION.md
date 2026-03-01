# Hermes — Vision

_One codebase. Three audiences. Zero manual translation._

## The Problem

Software teams build features. Then the translation tax kicks in:

- **Engineering** ships code, writes a commit message, maybe updates a changelog
- **CS/Support** finds out about the feature from a customer asking "what does this do?"
- **Marketing** scrambles to write about it from Slack threads and Jira tickets
- **Docs team** reverse-engineers behavior from the code because nobody wrote it down
- **Sales** promises capabilities they heard about in a standup

The knowledge exists — it's in the code, the PRDs, the design docs, the git history. But it's locked in engineering-speak. Every other team has to manually translate it into their own language, their own format, their own context. This translation is expensive, slow, error-prone, and almost always incomplete.

**The result:** Internal teams are perpetually behind. Documentation is stale. Marketing copy doesn't match reality. CS answers questions with "let me check with engineering." The gap between what was built and what the org understands widens with every release.

## The Insight

Nobody is solving the translation layer.

The market is full of tools that understand code (Swagger, TypeDoc, Carto) and tools that understand audiences (MadCap Flare, Mintlify, GitBook). But these two groups don't talk to each other.

- **Code-aware tools** generate developer reference docs. One audience, one format.
- **Audience-aware tools** require manual writing. Humans do the translation.
- **AI doc tools** (DocuWriter, Swimm) generate developer docs from code. Still one audience.

Nobody combines **code-aware + audience-aware + AI-generated**. That intersection is empty.

## The Solution

Hermes reads a codebase (or a PR, or a commit range, or a release) and generates documentation for three distinct audiences from that single technical source:

1. **Internal** — CS, Support, Engineering, Product
2. **External** — End users, developers, integrators
3. **Marketing** — Product marketing, sales, content teams

Same source. Different lens. Different voice. Different structure.

## How It Works

### Input Layer (Tiered Sources)

Hermes is **Carto-enhanced, not Carto-dependent.** It works with whatever context is available:

| Tier | Source | Quality |
|------|--------|---------|
| **1. Carto index** | Atoms, blueprint, zones, patterns from Memories | Best — function-level understanding, dependency graphs, domain groupings |
| **2. Direct codebase** | Source files, README, CLAUDE.md, package manifests, git log | Good — works for any project without Carto |
| **3. Context files** | PRDs, design docs, specs, competitive briefs provided by user | Layers on top — adds business context code alone can't provide |

Tier 1 is checked first. If unavailable, Tier 2 kicks in. Tier 3 always layers on top of either.

### Output Layer (Three Audiences)

Each audience gets fundamentally different documents — same source, different lens:

#### Internal Docs (CS, Support, Engineering, Product)

| Document | Description | Auto-gen Potential |
|----------|-------------|-------------------|
| **Feature Handoff** | What it does, how it works, edge cases, config options, common questions, CS notes. The #1 pain point in software orgs — the engineering-to-CS knowledge gap. | Very High |
| **Use Case Docs** | Scenario-driven: "When a user does X, the system does Y." Organized by user workflows, not code modules. Includes triggers, behavior, edge cases, CS notes. | High |
| **Internal Release Notes** | Everything that changed — granular, technical, includes breaking changes, migration steps, config changes, feature flag status. More detailed than external notes. | Very High |
| **Troubleshooting Guide** | Symptom-based decision trees: "If user sees X, check Y." Diagnostic steps, resolution paths, escalation triggers. Generated from error handling code and known failure modes. | Medium |
| **Internal FAQ** | Common questions with authoritative answers, organized by topic. Derived from feature handoffs and use case docs. Reduces repetitive questions to engineering. | High |
| **Glossary** | Product-specific and domain-specific term definitions. Eliminates confusion when teams use the same word differently. | Medium |

**Voice:** Practical, scenario-driven. "When a user does X, the system does Y."
**Goal:** CS can answer customer questions without asking engineering.

#### External Docs (End Users, Developers, Integrators)

| Document | Description | Auto-gen Potential |
|----------|-------------|-------------------|
| **API Reference** | Endpoints, schemas, auth, rate limits, error codes, code samples. The gold standard for auto-generation — derivable from code and OpenAPI specs. | Very High |
| **Getting Started** | Minimum path to "hello world." Fewest steps to a working result. | Medium |
| **Feature Docs** | What each feature does, how to use it, configuration options, limitations. Task-oriented, not feature-oriented. | High |
| **Changelog** | Chronological list of all changes: Added, Changed, Deprecated, Removed, Fixed, Security. Follows Keep a Changelog format. | Very High |
| **Migration Guide** | Breaking changes between versions, before/after code examples, step-by-step upgrade path. Generated from API diffs and deprecation annotations. | High |
| **Config Reference** | Every configuration option: type, default, valid range, description, effect. Derivable from schema definitions and config parsing code. | Very High |
| **Error Reference** | Every error code, its meaning, common causes, resolution steps. Extracted from error handling code. | High |

**Voice:** Clear, second-person. "You can...", "To configure X, do Y."
**Goal:** A new user can understand and use the project without asking anyone.

#### Marketing Docs (Product Marketing, Sales, Content)

| Document | Description | Auto-gen Potential |
|----------|-------------|-------------------|
| **Feature Brief** | The keystone document. Per-feature: What is it? Who is it for? Why does it matter? How is it different? Value-driven, benefit-first. Cascades into all other marketing content. | High |
| **Release Announcement** | User-facing "what's new" narrative. Focus on value and impact, not technical details. Screenshots/visuals suggested but not generated. | High |
| **Product Datasheet** | Technical specs, feature list, integrations, compliance, deployment options, pricing tiers. Almost entirely derivable from code and config. | Very High |
| **Sales One-Pager** | 3-4 key benefits, compelling proof point, use case vignette, CTA. Derived from feature briefs. | Medium-High |

**Voice:** Value-driven, benefit-first. "Now you can Y — here's why that matters."
**Goal:** Marketing/product team can write announcements, landing pages, and sales enablement from Hermes output.

### Modes of Operation

| Mode | Trigger | What It Does |
|------|---------|-------------|
| `generate` | "generate docs", "document this project" | Full project documentation — all audiences |
| `update` | "update docs", "document what changed" | Change-scoped delta since last generation |
| `internal` / `external` / `marketing` | "generate internal docs" | Single-audience generation |
| `publish` | "publish docs" | Commits to repo + stores in Memories |

### Scope Modes

| Mode | When | What |
|------|------|------|
| **Full project** | First run, periodic refresh | Comprehensive docs for entire codebase |
| **Change-scoped** | Per PR, per release, per commit range | Documents only what changed — delta-based |

### Integration

**As a Conductor pipeline phase:**
```yaml
skills:
  hermes:
    source: external
    phase: communicate
    type: phase
```

**Standalone invocation:**
```
"Generate docs for this project"
"Document what changed since last release"
"Generate marketing briefs for the auth feature"
```

### Output Targets

| Target | Format | Who Benefits |
|--------|--------|-------------|
| **Repo files** | Markdown in `docs/generated/` | Humans — browsable, version-controlled, reviewable |
| **Memories MCP** | Structured entries with `hermes/{project}/` prefixes | AI — searchable, composable, context-aware |

### Output Structure

```
docs/generated/
  .hermes.md                    # State: generation status, timestamps, tier used
  index.md                      # Master index linking all generated docs
  internal/
    overview.md                 # System overview for internal teams
    feature-handoffs/
      fh-001-[feature].md       # Per-feature handoff for CS/Support
    use-cases/
      uc-001-[scenario].md      # Scenario-driven behavior docs
    release-notes/
      rn-v1.2.0.md              # Internal release notes per version
    troubleshooting/
      ts-001-[symptom].md       # Symptom-based diagnostic guides
    faq.md                      # Internal FAQ
    glossary.md                 # Term definitions
  external/
    overview.md                 # User-facing project overview
    getting-started.md          # Quick start guide
    features/
      feat-001-[feature].md     # Per-feature user docs
    api-reference.md            # API endpoint reference
    config-reference.md         # Configuration option reference
    error-reference.md          # Error code reference
    changelog.md                # Structured changelog
    migration/
      v1-to-v2.md               # Version migration guides
  marketing/
    overview.md                 # Value proposition, positioning
    feature-briefs/
      fb-001-[feature].md       # Per-feature: what, who, why, how different
    release-announcements/
      ra-v1.2.0.md              # User-facing release narratives
    datasheet.md                # Product specs and capabilities
    one-pagers/
      op-001-[feature].md       # Sales one-pagers per feature
```

### Artifact Metadata

Every generated document has frontmatter for programmatic consumption:

```yaml
---
id: fh-001
type: feature-handoff
audience: internal
topic: user-authentication
status: draft
generated: 2026-02-28
source-tier: carto          # or "direct" or "context-only"
context-files: [auth-prd.md]
hermes-version: 0.1.0
---
```

### Memories Schema

| Source Prefix | Content |
|--------------|---------|
| `hermes/{project}/internal` | Internal doc summaries |
| `hermes/{project}/external` | External doc summaries |
| `hermes/{project}/marketing` | Marketing brief summaries |
| `hermes/{project}/state` | Generation metadata |

## Architecture

### Skill Structure

Single-file skill: `skills/hermes/skill.md`

Follows the Delphi pattern:
- YAML frontmatter with name, description, triggers
- Mode detection from invocation keywords
- Disk-based state tracking (`.hermes.md`)
- Subagent coordination for parallel doc generation
- Resume protocol — check disk state before starting work

### Pipeline

```
Input Resolution
  ├── Check Memories for carto/{project}/ → Tier 1
  ├── Fallback: glob project, read key files → Tier 2
  └── Always: scan docs/plans/, .apollo.yaml → Tier 3
        │
Audience Router
  ├── Internal generator
  │     ├── Feature Handoffs
  │     ├── Use Case Docs
  │     ├── Internal Release Notes
  │     ├── Troubleshooting Guides
  │     ├── FAQ
  │     └── Glossary
  ├── External generator
  │     ├── API Reference
  │     ├── Getting Started
  │     ├── Feature Docs
  │     ├── Changelog
  │     ├── Migration Guide
  │     ├── Config Reference
  │     └── Error Reference
  └── Marketing generator
        ├── Feature Briefs (keystone)
        ├── Release Announcements
        ├── Product Datasheet
        └── Sales One-Pagers
              │
Output Writer
  ├── Write to docs/generated/ (repo)
  ├── Store in Memories (hermes/{project}/)
  └── Update .hermes.md (state)
```

## What Hermes Is Not

- **Not a docs hosting platform.** Hermes generates files. Where you host them (GitBook, Mintlify, Confluence, your repo) is your choice.
- **Not a replacement for human writing.** Tutorials, thought leadership, and strategic positioning still need humans. Hermes handles the grind — the translation work that nobody wants to do.
- **Not Carto.** Carto indexes code. Hermes translates that index (or raw code) into audience-specific documentation. Complementary, not overlapping.
- **Not a one-time generator.** Hermes tracks state and generates deltas. It's designed to run on every meaningful change, keeping docs current automatically.

## Success Criteria

Hermes is successful when:

1. **CS can answer a customer question about a new feature without asking engineering** — because the feature handoff doc exists and is accurate
2. **External docs update automatically when code changes** — no manual changelog writing
3. **Marketing has a feature brief within minutes of a release** — not days of reverse-engineering
4. **The docs are actually used** — measured by whether teams stop maintaining separate, manual versions
5. **It works without Carto** — any project can benefit, not just Carto-indexed ones

## Phased Rollout

### Phase 1: Foundation (v0.1.0)
Skill skeleton + the 5 highest-value, most automatable doc types:
- Feature Handoff (internal) — the #1 pain point
- Internal Release Notes (internal) — from git history
- Changelog (external) — structured, from git
- Feature Brief (marketing) — the keystone document
- Product Datasheet (marketing) — almost entirely from code

### Phase 2: Depth (v0.2.0)
Expand each audience with the next tier:
- Use Case Docs (internal)
- Internal FAQ (internal)
- API Reference (external)
- Feature Docs (external)
- Release Announcement (marketing)

### Phase 3: Completeness (v0.3.0)
Round out all doc types:
- Troubleshooting Guide (internal)
- Glossary (internal)
- Getting Started (external)
- Config Reference (external)
- Error Reference (external)
- Migration Guide (external)
- Sales One-Pager (marketing)

### Phase 4: Product (v1.0.0)
- Web UI for non-dev teams to browse/search generated docs
- CI/CD hook for auto-generation on merge
- Diff view: what changed in docs since last generation
- Review workflow: generated → reviewed → published

## The Ecosystem

```
Apollo (scaffold) → Carto (index) → Delphi (test) → Conductor (orchestrate) → Hermes (communicate)
```

Hermes is the final mile — the skill that takes everything the ecosystem knows about a codebase and makes it useful to everyone in the org, not just engineers.
