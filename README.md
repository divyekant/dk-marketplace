# Hermes

*The messenger who speaks every audience's language.*

Hermes is a Claude skill that generates audience-specific documentation from a single codebase. It reads your code, docs, specs, and git history — then produces structured documentation for three distinct audiences.

## The Problem

Software teams ship code. Then the translation tax kicks in:

- **CS/Support** finds out about features from customers asking "what does this do?"
- **Marketing** reverse-engineers announcements from Slack threads and Jira tickets
- **Docs team** reads the code because nobody wrote it down

The knowledge exists — in the code, the PRDs, the design docs, the git history. But it's locked in engineering-speak.

## The Solution

Hermes reads one source and generates documentation for three audiences:

| Audience | Voice | Doc Types |
|----------|-------|-----------|
| **Internal** (CS/Support) | Practical, scenario-driven | Feature Handoffs, Use Cases, Troubleshooting, Release Notes, FAQ, Glossary |
| **External** (Users/Devs) | Clear, second-person | API Reference, Feature Docs, Getting Started, Changelog, Config Reference, Error Reference, Migration Guide |
| **Marketing** (PMM/Sales) | Benefit-focused, value-driven | Feature Briefs, Product Datasheets, Release Announcements, Sales One-Pagers |

Same source. Different lens. Different voice. Different structure.

## Quick Start

### Install

```bash
# Clone the repo
git clone https://github.com/divyekant/hermes.git

# Symlink into Claude Code skills
ln -s $(pwd)/hermes/skills/hermes ~/.claude/skills/hermes
```

### Use

```
# Generate full documentation for a project
"Generate docs for this project"

# Single audience
"Generate internal docs"
"Generate marketing docs"

# Update after changes
"Update docs"

# Scope to a version
"Generate release docs for v2.0"
```

## How It Works

### Input (Tiered Sources)

Hermes is **Carto-enhanced, not Carto-dependent**:

| Tier | Source | Quality |
|------|--------|---------|
| 1. Carto index | Atoms, blueprint, zones, patterns | Best — function-level understanding |
| 2. Direct codebase | Source files, README, manifests, git log | Good — works for any project |
| 3. Context files | PRDs, design docs, specs | Layers on top of either tier |

### Output

- **Repo files:** Markdown in `docs/generated/` — human-readable, version-controlled
- **Memories:** Structured entries for AI consumption

Every document has YAML frontmatter for programmatic parsing.

### Modes

| Mode | Trigger | What It Does |
|------|---------|-------------|
| Generate | "generate docs" | Full project documentation |
| Update | "update docs" | Delta since last generation |
| Internal/External/Marketing | "generate internal docs" | Single-audience generation |

## Context Optimization

The skill is split for efficient context usage:

- **skill.md** (525 lines) — orchestration logic, always loaded
- **templates/internal.md** (334 lines) — loaded only when generating internal docs
- **templates/external.md** (404 lines) — loaded only when generating external docs
- **templates/marketing.md** (227 lines) — loaded only when generating marketing docs

Single-audience runs use ~750-930 lines instead of the full 1,490.

## Custom Templates

Override any audience's templates per-project:

```bash
mkdir -p .hermes/templates
cp ~/.claude/skills/hermes/templates/internal.md .hermes/templates/internal.md
# Edit to taste — Hermes uses project overrides first
```

## Post-Commit Hook

Auto-update docs on every commit:

```bash
# Install (one-time per project)
# See skill.md "Post-Commit Hook" section for the hook script

# Skip for a single commit
HERMES_SKIP=1 git commit -m "chore: minor fix"
```

## Ecosystem

```
Apollo (scaffold) → Carto (index) → Delphi (test) → Conductor (orchestrate) → Hermes (communicate)
```

Hermes is the final mile — it takes everything the ecosystem knows about a codebase and makes it useful to everyone in the org.

## License

[MIT](LICENSE)
