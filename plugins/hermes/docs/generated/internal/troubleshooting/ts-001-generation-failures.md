---
id: ts-001
type: troubleshooting
audience: internal
topic: generation-failures
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Troubleshooting: Generation Failures

## Symptoms

- Hermes starts but produces no output files
- Hermes announces "No documentable features found"
- Generated docs are empty or contain only frontmatter
- Generation stops partway through with no error message

## Quick Check

1. Check if the project has recognizable source structure — at minimum, a README.md or a source directory (src/, lib/, app/, api/). If the project is empty or contains only configuration files, Hermes cannot discover features. Fix: add source files or provide context files manually.

2. If the project has source files, check if `.hermes.md` exists and is corrupted. Fix: delete `.hermes.md` and retry.

## Diagnostic Steps

### Step 1: Verify project structure
- **Run:** `ls -la` in the project root
- **If no README.md, no src/, no lib/:** Hermes has nothing to analyze. Provide context files or ensure the project has a standard layout.
- **If structure looks normal:** Proceed to Step 2.

### Step 2: Check state file
- **Run:** `cat docs/generated/.hermes.md` (if it exists)
- **If file is malformed (truncated, missing sections):** Delete it: `rm docs/generated/.hermes.md` and retry.
- **If file shows all audiences "complete":** Hermes thinks docs are already done. Delete it for a fresh run, or use "regenerate from scratch."
- **If file looks normal or doesn't exist:** Proceed to Step 3.

### Step 3: Check Memories MCP connectivity
- **Run:** Try a memory search within Claude Code
- **If Memories is unresponsive:** Hermes cannot check for Carto index. This is not fatal (falls back to Tier 2), but if the session itself is unstable, generation may fail.
- **If Memories works:** Proceed to Step 4.

### Step 4: Check context window
- **If the session is near context limit:** Hermes may silently fail to generate remaining docs. Resume in a new session — Hermes will pick up from `.hermes.md` state.
- **If context is fresh:** The issue is likely a parsing problem with the project structure. Try providing explicit context files.

## Resolutions

### Empty feature map
- **Fix:** Ensure the project has at least one of: README.md with feature descriptions, source directories (src/, lib/, api/), or user-provided context files
- **Verify:** Re-run Hermes and confirm features are listed in the feature map
- **Prevent:** Run Carto on the project first for comprehensive feature discovery

### Corrupted state file
- **Fix:** `rm docs/generated/.hermes.md` and re-invoke Hermes
- **Verify:** Check that `.hermes.md` is recreated with proper structure after feature discovery
- **Prevent:** Allow Hermes to complete without interruption when possible

### Context window exhaustion
- **Fix:** Start a new Claude Code session and re-invoke Hermes. It will resume from the last completed audience.
- **Verify:** Check `.hermes.md` — the previously completed audiences should show as `complete`
- **Prevent:** For large projects, run one audience at a time: "generate internal docs", then "generate external docs" in separate sessions

## Escalation

- **Escalate to:** Project maintainer / skill developer
- **Include:** The `.hermes.md` state file, the project's directory listing (`ls -R`), and the exact invocation used
- **SLA:** Not applicable (open-source skill)

## Related

- [State Tracking & Resume](../feature-handoffs/fh-004-state-tracking.md)
- [First-Run Full Generation](../use-cases/uc-001-first-run-full-generation.md)
