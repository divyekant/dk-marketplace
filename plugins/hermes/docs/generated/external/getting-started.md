---
type: getting-started
audience: external
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Getting Started

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and configured
- A project with source code you want to document (any language, any framework)
- The Hermes skill available in your skill ecosystem (typically at `skills/hermes/skill.md`)

**Optional but recommended:**
- Git initialized in the project (enables changelog and release notes generation)
- Carto index of the project (enables Tier 1 input resolution for richer docs)

## Installation

Hermes is a single markdown file — no package installation required. To add it to your project:

```bash
mkdir -p skills/hermes
cp /path/to/hermes/skills/hermes/skill.md skills/hermes/skill.md
```

Or, if Hermes is available in your shared skill ecosystem, Claude Code will discover it automatically.

## Quick Start

### 1. Navigate to your project

Open a Claude Code session in your project directory:
```bash
cd /path/to/your/project
claude
```

### 2. Generate documentation

Tell Hermes to document your project:
```
You: Generate docs for this project
```

### 3. Review the feature map

Hermes analyzes your project and presents the features it discovered:
```
Hermes: No Carto index — reading codebase directly.
        Also using 1 context file: VISION.md

        Feature Map:
        - authentication (4 components) — UI + API
        - dashboard (3 components) — UI

        Generate docs for all features?
```

Confirm to proceed:
```
You: Yes, all features
```

### 4. Wait for generation

Hermes generates docs in order: Internal, then External, then Marketing. Progress is tracked in `.hermes.md` so interrupted runs can resume.

### 5. Verify it works

Check the generated output:
```bash
ls docs/generated/
```

Expected output:
```
.hermes.md
index.md
internal/
external/
marketing/
```

Open the master index to see all generated documents:
```bash
cat docs/generated/index.md
```

## Next Steps

- [Multi-Audience Generation](features/feat-001-multi-audience-generation.md) — understand the core feature and its options
- [Mode System](features/feat-003-mode-system.md) — learn how to generate docs for specific audiences or incremental changes
- [Configuration Reference](config-reference.md) — all configurable options
- [Tiered Input Resolution](features/feat-002-tiered-input-resolution.md) — improve doc quality with Carto indexing or context files
