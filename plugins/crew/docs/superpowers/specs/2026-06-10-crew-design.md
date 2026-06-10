# Crew — Multi-Model Build Orchestrator: Design

Date: 2026-06-10 · Status: approved (design direction approved interactively; ownership of detail decisions delegated)

## Problem

dk works with one controller agent (Fable in Claude Code) but wants
implementation distributed to the models best suited per domain: Opus for
frontend, GPT‑5.5 (via Codex CLI) for backend, Sonnet for low-level
mechanical work. The controller must remain the single point of contact —
decomposing, briefing, reviewing, integrating. The setup must not break the
existing conductor pipeline system, which is shared between Claude Code and
Codex CLI hosts.

## Decisions

1. **Layer under conductor, not replace it** (user-selected). Conductor
   keeps classifying tasks and sequencing phases; crew owns execution inside
   the build phase. `crew` added to the build phase of the `feature` and
   `complex` pipelines. `small-fix` excluded **because** delegation overhead
   (2–5× tokens, per field reports) exceeds the value below multi-file scope.
2. **Fable delegates substantive, does trivial** (user-selected). Hard
   anti-pattern guard against orchestrator-as-god; sub-10-line single-file
   edits stay with the orchestrator because a brief costs more than the edit.
3. **Plain subagents, not agent teams** — agent teams remain experimental
   (env-flag gated, resume limitations) as of June 2026. Revisit **when**
   agent teams exit experimental status.
4. **Workers**: Opus via Agent tool `model: "opus"`; Sonnet via
   `model: "sonnet"`; GPT‑5.5 via the official codex plugin's
   `codex:codex-rescue` subagent (pure forwarder — one brief, one task call,
   write-capable default, auth reused from `codex login`).
5. **Cross-host seamlessness**: one portable SKILL.md (Agent Skills open
   spec, no Claude-only syntax in the body), symlinked into both
   `~/.claude/skills/crew` and `~/.agents/skills/crew`. A capability gate at
   the top makes non-orchestrator hosts (Codex) announce a one-line
   degradation and proceed with their normal build process. This means the
   shared pipelines.yaml entry is valid on both hosts — Codex never hits its
   "skill missing" fallback, and Claude Code gets full orchestration.
6. **Worker-side conductor bypass**: every brief opens with an explicit
   "do not invoke conductor or routing skills" preamble — both Claude
   subagents (which see CLAUDE.md's conductor mandate) and Codex runs (whose
   AGENTS.md routes non-trivial work to conductor) would otherwise re-enter
   routing inside a worker. Mirrors the superpowers SUBAGENT-STOP precedent.
7. **Review gate**: orchestrator reads every diff, runs tests itself
   (worker claims are not evidence), one targeted retry then
   reroute/takeover. GPT output is cross-model-reviewed by construction;
   high-risk Claude-authored diffs may optionally go to codex adversarial
   review. Codex unavailable → BE falls back to Opus, flagged.
8. **Brief protocol** (from researched field practice): self-contained
   briefs (workers see no orchestrator history), one-file-one-owner across
   concurrent workers, explicit out-of-scope, iteration cap of 3 on repeated
   failures, required return format. Contract-first decomposition for
   full-stack work: orchestrator authors the interface contract, FE/BE
   dispatch in parallel against it.

## Validation of the routing split

Community/practitioner reports (June 2026) support the direction: Claude
strongest on UI quality and cross-file reasoning; GPT/Codex strongest on
sustained autonomous execution, architecture calls, and structured output;
cross-model review catches disjoint error classes. Full findings with
citations: `docs/research/findings.md`.

## Deferred / future

- **Agent teams backend** for long-running teammates with mailboxes — when
  the feature exits experimental.
- **Reverse orchestration from Codex hosts** (Codex driving Claude workers
  via `claude -p`) — not needed **until** dk actually drives builds from
  Codex; the capability gate leaves room for it.
- **Per-worker token budgets / reviewer ratios** — YAGNI at current scale;
  reconsider if crew runs >5 workers per task.

## Files

- `skills/crew/SKILL.md` — the skill (portable core, both hosts)
- `skills/crew/workers/` — per-worker definitions (brief additions, review focus, failure modes)
- `skill-conductor/pipelines.yaml` — additive build-phase wiring
- `docs/research/` — research findings and sources

## Update 2026-06-10 (later same day): mainstreamed as OSS

Restructured to the house public-skill layout (`skills/crew/` like
hermes/delphi), added Apollo OSS scaffolding (`extends: oss`), plugin
manifest (`.claude-plugin/plugin.json`), Codex install guide, and
dk-marketplace listing. Repo made public at github.com/divyekant/crew,
tagged v0.1.0. Both host symlinks re-pointed to `skills/crew/`.
