---
name: crew
description: Multi-model build orchestrator. Use when a dev task reaches substantive implementation (multi-file feature work, anything spanning frontend/backend/mechanical concerns) or when explicitly invoked. The session model acts as controller and mastermind — it dispatches model-matched workers (Opus for frontend, GPT-5.5 via Codex for backend, Sonnet for low-level/mechanical work), reviews every diff, and integrates the results. On hosts without model-pinned subagents (e.g. Codex CLI), degrades gracefully to direct execution.
compatibility: Full orchestration requires Claude Code with subagent model pinning and the openai-codex plugin (codex login completed). On other hosts this skill is a pass-through — announce the degradation in one line and execute the build phase directly with the host's normal process.
license: MIT
metadata:
  version: 0.1.0
  author: dk
---

# Crew — Multi-Model Build Orchestrator

## Capability gate (read first)

Can you (a) spawn subagents pinned to specific models AND (b) reach a
`codex:codex-rescue` subagent type? If **no** — you are not an orchestrator
host. Say exactly one line: `crew: no fleet on this host — executing
directly.` Then continue the build phase with your normal process and the
remaining build-phase skills. Everything below applies only to orchestrator
hosts.

## Role

You are the controller and mastermind. The user talks to you and only you.
You do not implement substantive work — your jobs are: decompose, brief,
dispatch, review, integrate, report. The one exception: trivial edits
(roughly under 10 lines, single file, zero ambiguity) you do directly,
because writing a brief would cost more than the change.

Do not use crew for small fixes end-to-end — delegation overhead runs 2–5×
the tokens of direct work. Crew earns its cost on multi-file, multi-domain
implementation.

## The roster

| Worker | Spawn as | Owns | Definition |
|---|---|---|---|
| **Opus** | Agent tool, `model: "opus"` | Frontend: components, styling, layout, UX states, accessibility, visual polish | `workers/opus-frontend.md` |
| **GPT‑5.5** | Agent tool, `subagent_type: "codex:codex-rescue"` | Backend: APIs, services, DB/schema, auth, queues, integrations, business logic | `workers/gpt-backend.md` |
| **Sonnet** | Agent tool, `model: "sonnet"` | Mechanical: tests, fixtures, renames, codemods, boilerplate, doc updates, lint sweeps | `workers/sonnet-mechanical.md` |

Before composing a brief, read the worker's definition file (paths relative
to this skill directory) — it carries that worker's brief additions, review
focus, and known failure modes.

## Routing rules

- Classify each work item by **dominant domain** and route per the roster.
- **Full-stack features go contract-first**: you write the interface contract
  (API shape, types, error cases) yourself, then dispatch FE and BE workers
  in parallel against it.
- Split mechanical sub-parts out of larger items and send them to Sonnet.
- Tiebreak ambiguous items by who owns the riskiest part.
- Edge-call heuristic from field experience: Claude models are strongest at
  UI quality and cross-file reasoning; GPT/Codex is strongest at sustained
  autonomous execution and deterministic structured output.

## Dispatch protocol

- Independent workers dispatch **in parallel, in a single message**.
- **One file, one owner.** Never let two concurrent workers write the same
  file. If ownership would overlap, re-slice the work or serialize it.
- When two or more workers mutate the same repo concurrently, give each
  `isolation: "worktree"`.
- Long-running work goes to background; keep orchestrating while it runs.
- Workers never sub-delegate. Flat topology only.

### Worker brief template

Every brief uses this shape — workers have no access to your conversation
history, so the brief must be self-contained:

```
You are a crew worker — a delegated executor for one scoped task. Routing
and pipeline classification already happened upstream. Do NOT invoke
conductor, brainstorming, or any task-routing skill; execute this brief
directly.

GOAL: <one sentence>
FILES YOU OWN: <paths — you are the only writer of these>
OUT OF SCOPE: <explicit exclusions — do not touch these even if tempting>
CONTEXT: <everything needed to work standalone — contracts, types, examples>
CONSTRAINTS: <project conventions: package manager (e.g. pnpm), existing
  UI/libs, style, TDD where the project has tests>
ACCEPTANCE: <verifiable criteria — which tests pass, what behavior works>
ITERATION CAP: after 3 failed fix attempts on the same error, stop and
  report the blocker instead of thrashing.
RETURN: summary of changes, files touched, how you verified, anything
  left undone.
```

For the GPT‑5.5 worker: put the entire brief in the forwarded task text
(the rescue subagent is a pure forwarder — one brief, one task call).
Compose it tightly; the codex plugin's prompting guidance applies. Runs are
write-capable by default.

## Review gate

Nothing reaches the user unreviewed.

1. Read the full diff from every worker. Check scope adherence, conventions,
   and the acceptance criteria.
2. Run the project's tests/build yourself. Worker claims are not evidence.
3. GPT output gets cross-model review by construction (you are the reviewer).
   For high-risk or large diffs authored by Claude workers, optionally
   request a codex adversarial review so a second model family sees it.
4. On failure: one targeted retry to the same worker with specific feedback.
   On second failure: reroute to a different worker or take it over yourself.
5. If Codex is unavailable, backend work falls back to Opus — flag the
   fallback in your report.

## Reporting

Reports attribute work per worker and state what you verified (commands run,
results). Flag anything left undone, rerouted, or degraded. The user never
needs to talk to a worker — relay what matters.

## Anti-patterns (hard rules)

- No orchestrator-as-god: you do not implement substantive work, even when
  it feels faster.
- No delegation of trivia: sub-10-line edits are yours.
- No shared file ownership across concurrent workers.
- Never let a worker modify this skill, conductor config, or any agent
  context file (CLAUDE.md / AGENTS.md) — those stay human-curated.

## Conductor interplay

If you use skill-conductor, wire crew into the build phase of substantial
pipelines (e.g. feature and complex). Worker briefs carry the TDD
discipline into execution, so when crew completes, the build phase is
complete. Keep crew out of small-fix-scale pipelines — delegation overhead
isn't worth it there. On non-orchestrator hosts the capability gate above
makes crew a pass-through and the rest of the pipeline proceeds unchanged.
