---
id: fh-003
type: feature-handoff
audience: internal
topic: mode-system
status: draft
generated: 2026-02-28
source-tier: direct
context-files: [docs/plans/2026-02-28-hermes-design.md]
hermes-version: 1.0.0
---

# Feature Handoff: Mode System

## What It Does

Hermes supports five operational modes that control what documentation is generated and for which audiences. Modes are detected automatically from the user's invocation keywords, making the system feel natural to use without requiring explicit configuration or flags.

The mode system enables both full-project documentation (all 17 doc types for all audiences) and surgical generation (just internal docs, just marketing briefs, or just the delta since last run).

## How It Works

Mode detection parses the user's invocation for keywords and maps them to one of five modes:

| Mode | Trigger Keywords | Scope |
|------|-----------------|-------|
| **Generate** | "generate docs", "document this project" | All audiences, full project |
| **Update** | "update docs", "document what changed", "release docs" | Delta since last generation |
| **Internal** | "generate internal docs", "CS documentation" | Internal audience only |
| **External** | "generate external docs", "API docs", "user docs" | External audience only |
| **Marketing** | "generate marketing docs", "feature briefs", "datasheet" | Marketing audience only |

**Default behavior rules:**
- If `docs/generated/` does not exist, always default to Generate (full) mode regardless of keywords
- If docs exist and user says "update" or references a version/release, use Update mode
- If docs exist and user says "generate" without audience qualifier, ask: "Docs already exist. Regenerate from scratch or update with changes?"

**Audience processing order (for Generate mode):**
1. Internal — forces deep feature understanding (edge cases, troubleshooting, config)
2. External — simplifies that understanding for end users
3. Marketing — reframes for value and benefits

This order is intentional: each audience builds on the understanding gained from the previous one. Single-audience modes skip directly to the requested audience.

## User-Facing Behavior

Users invoke Hermes with natural language and the mode is inferred:
- "Generate docs for this project" triggers Generate mode
- "Just update the marketing docs" triggers Marketing mode with update scoping
- "What changed since v1.0?" combined with "generate release docs" triggers Update mode

Hermes confirms the detected mode at the start: "Mode: Generate (all audiences)" or "Mode: Internal only."

## Configuration

The mode system has no configuration. It is entirely keyword-driven.

| Keyword Pattern | Detected Mode |
|----------------|--------------|
| "generate" + no audience qualifier | Generate |
| "update" or "changed" | Update |
| "internal" or "CS" or "support" | Internal |
| "external" or "API" or "user" | External |
| "marketing" or "brief" or "datasheet" or "sales" | Marketing |

## Edge Cases & Limitations

- **Ambiguous invocations** — "Document the API changes" could be either External mode (API docs) or Update mode (changes). Hermes defaults to External mode in this case. The user can clarify by saying "update the API docs."
- **Publish mode is not yet implemented** — The design mentions a Publish mode ("generate and publish docs") for committing to repo and storing in Memories, but this is planned for a future version.
- **No combined single-audience modes** — You cannot say "generate internal and marketing docs" to get two audiences without the third. This triggers Generate mode (all audiences). To generate two specific audiences, run Hermes twice.

## Common Questions

**Q: Can I generate docs for just one feature?**
A: Mode controls audience scope, not feature scope. Feature scoping happens during the Feature Discovery step after mode is selected. You can generate all audiences for one feature, or one audience for all features.

**Q: What if I want to update only the internal docs?**
A: Say "update internal docs." This combines Update mode (delta) with Internal audience filtering.

**Q: Does Update mode update all doc types or just the ones for changed features?**
A: Update mode identifies which features changed via git history, then regenerates all doc types for those features only. Unchanged features are not touched.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Hermes generating all audiences when only one was requested | Invocation did not include audience-specific keywords | Use explicit keywords: "internal", "external", or "marketing" |
| Hermes asking whether to regenerate when update was intended | The word "update" or "changed" was not in the invocation | Include "update" or "what changed" in the prompt |
| Partial docs generated (some audiences missing) | Previous run was interrupted | Check `.hermes.md` for generation progress; resume by re-invoking Hermes |

## Related

- [Multi-Audience Generation](fh-001-multi-audience-generation.md) — the core generation feature
- [State Tracking & Resume](fh-004-state-tracking.md) — how state enables resumable generation
