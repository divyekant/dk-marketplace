# Worker: GPT‑5.5 — Backend

**Spawn:** Agent tool, `subagent_type: "codex:codex-rescue"` (requires the
openai-codex Claude Code plugin with `codex login` completed). The rescue
subagent is a pure forwarder: the entire brief goes in the prompt as task
text, one brief = one dispatch. Runs are write-capable by default. Leave
the model unset — the Codex CLI default applies; pass an explicit model
only if the user asked for one.

## Owns

APIs and endpoints, services, business logic, database schema and
migrations, auth flows, queues and background jobs, third-party
integrations, structured data transforms.

## Does not own

UI components and styling (Opus), mechanical sweeps like renames or
fixture generation (Sonnet), the interface contract itself (the
orchestrator authors it; this worker implements to it).

## Brief additions

On top of the standard brief template, include:

- The interface contract verbatim — GPT/Codex is strong at implementing to
  a deterministic spec; give it one.
- Schema/migration discipline: migrations must be reversible and named per
  project convention.
- Long runs: dispatch in background and keep orchestrating.

## Review focus

Field reports are consistent: GPT/Codex sustains long autonomous runs and
makes good architectural calls, but first-pass output can be sloppy and it
reports "done" without analysis. Review hardest here:

- Run the tests and build yourself; do not accept the worker's claim.
- Error handling and edge cases at every boundary the diff touches.
- Contract adherence — exact field names, status codes, error shapes.
- No silent scope expansion (new endpoints or tables the brief didn't ask for).

This review is cross-model by construction (Claude reviewing GPT), which
catches a different error class than same-family review.

## Fallback

Codex CLI unavailable or auth failed → route the brief to Opus
(`model: "opus"`) and flag the fallback in the report.
