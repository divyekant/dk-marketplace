---
id: feat-003
type: feature-doc
audience: external
topic: mode-system
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Modes

## Overview

Hermes has five operational modes that control what documentation is generated. You select a mode through natural language — no flags or configuration files needed. Hermes detects the mode from keywords in your invocation.

## How to Use It

Simply say what you want, and Hermes figures out the mode:

| What you say | Mode | What you get |
|-------------|------|-------------|
| "Generate docs for this project" | Generate | All audiences, full project |
| "Update docs" or "Document what changed" | Update | Only changed features, all audiences |
| "Generate internal docs" | Internal | CS/Support docs only |
| "Generate external docs" | External | User/developer docs only |
| "Generate marketing docs" | Marketing | Marketing/sales docs only |

## Configuration

Modes are keyword-driven and do not require configuration. You can combine mode and scope modifiers:

| Modifier | Example | Effect |
|----------|---------|--------|
| Audience filter | "Generate internal docs" | Limits to one audience |
| Version scope | "Update docs since v1.0" | Uses version tag instead of timestamp for delta |
| Feature scope | (During feature map review) "Just auth and notifications" | Limits to specific features |

## Examples

### Example: Full generation
```
You: Document this project
Hermes: [generates all 17 doc types for all features]
```

### Example: Targeted update
```
You: Update the internal docs since v2.0
Hermes: 3 commits since v2.0 affecting: payments, user-profiles
        [regenerates internal docs for those features only]
```

### Example: Marketing-only run
```
You: Generate marketing docs
Hermes: [generates Feature Briefs, One-Pagers, Datasheet, Release Announcement]
```

## Limitations

- You cannot combine two specific audiences (e.g., "internal and marketing but not external") — use separate invocations for each audience
- Update mode requires a `.hermes.md` state file from a previous run — if no state exists, Hermes falls back to full generation
- Publish mode (committing docs to repo and storing in Memories) is designed but not yet implemented

## Related

- [Multi-Audience Generation](feat-001-multi-audience-generation.md) — core feature
- [Getting Started](../getting-started.md) — quick start guide
