# crew

**Multi-model build orchestrator for Claude Code.** Your session model acts
as controller and mastermind — it decomposes implementation work, dispatches
it to the model best suited per domain, reviews every diff, and integrates
the results. You only ever talk to the orchestrator.

| Worker | Model | Domain |
|---|---|---|
| Frontend | Claude Opus | Components, styling, layout, UX states, accessibility |
| Backend | GPT‑5.5 (via Codex CLI) | APIs, services, DB/schema, auth, business logic |
| Mechanical | Claude Sonnet | Tests, fixtures, renames, codemods, boilerplate |

The routing split follows mid-2026 practitioner consensus — Claude models
lead on UI quality and cross-file reasoning, GPT/Codex on sustained
autonomous execution and structured backend output — and every Codex diff
gets cross-model review by construction, which catches error classes
same-family review misses. Full cited research: [`docs/research/findings.md`](docs/research/findings.md).

## How it works

1. **Decompose** — the orchestrator classifies each work item by dominant
   domain. Full-stack features go contract-first: it authors the interface
   contract, then frontend and backend dispatch in parallel against it.
2. **Brief** — every worker gets a self-contained brief: goal, files it
   exclusively owns, out-of-scope list, constraints, acceptance criteria,
   iteration cap, return format. Per-worker specifics live in
   [`skills/crew/workers/`](skills/crew/workers/).
3. **Dispatch** — independent workers run in parallel; concurrent
   same-repo work gets git worktree isolation; one file, one owner.
4. **Review** — nothing ships unreviewed. The orchestrator reads every
   diff and runs the tests itself. One targeted retry, then reroute or
   takeover. Codex down → backend falls back to Opus, flagged.
5. **Report** — per-worker attribution plus what was verified.

The orchestrator never implements substantive work itself — and never
delegates trivia (sub-10-line edits), since multi-agent overhead runs 2–5×
the tokens of direct work. Small fixes don't need a crew.

## Install

### Claude Code (full orchestration)

Via marketplace:

```sh
claude plugin marketplace add divyekant/dk-marketplace
claude plugin install crew
```

Or manual:

```sh
git clone https://github.com/divyekant/crew.git
ln -s "$(pwd)/crew/skills/crew" ~/.claude/skills/crew
```

**Requirements:** Claude Code with subagent support; the
[openai-codex plugin](https://github.com/openai/codex-plugin-cc) with
`codex login` completed for the GPT‑5.5 backend worker (without it,
backend work falls back to Opus and is flagged in reports).

### Codex CLI (graceful pass-through)

See [`.codex/INSTALL.md`](.codex/INSTALL.md). Crew detects hosts that
can't spawn model-pinned subagents and steps aside in one line — useful
when a shared pipeline config references crew on both hosts.

## Usage

Just work normally — crew triggers when a task reaches substantive
multi-file implementation — or invoke it explicitly:

```text
/crew build the share-link feature: API endpoint + settings UI + tests
```

## Customize

- **Routing**: edit the roster and routing rules in
  [`skills/crew/SKILL.md`](skills/crew/SKILL.md).
- **Worker behavior**: each worker's domain, brief additions, and review
  focus live in their own file under
  [`skills/crew/workers/`](skills/crew/workers/) — swap models, tighten
  review, or add a worker type by adding a file and a roster row.
- **Pipelines**: using [skill-conductor](https://github.com/divyekant/skill-conductor)?
  Add `crew` to the build phase of your substantial pipelines; keep it out
  of small-fix pipelines.

## Docs

- Design spec: [`docs/superpowers/specs/2026-06-10-crew-design.md`](docs/superpowers/specs/2026-06-10-crew-design.md)
- Research (routing split, brief protocol, anti-patterns): [`docs/research/`](docs/research/)
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)

## License

[MIT](LICENSE)
