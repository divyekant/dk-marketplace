# Research: Multi-Model Orchestrator/Worker Coding Setups (mid-2026)

> Researched 2026-06-10 | 17 sources consulted | 12 sources cited

## Executive Summary

The orchestrator/worker pattern with model-matched workers is now a mainstream, officially-supported practice. Claude Code supports per-subagent model pinning natively (frontmatter `model` field + per-invocation `model` parameter), and OpenAI ships an official Claude Code plugin (`openai/codex-plugin-cc`) whose `codex:codex-rescue` subagent is the sanctioned path for delegating tasks to Codex/GPT [1][2][3].

The community-validated routing split is close to, but subtly different from, "FE=Claude, BE=GPT". The stronger consensus: **Claude excels at UI quality, holistic cross-file reasoning, and proactive analysis/review; GPT/Codex excels at sustained autonomous execution, architectural decisions, and deterministic structured output** [4][5][6]. "Opus for frontend, GPT-5.x for backend, cheaper Claude for mechanical work" is directionally consistent with reported experience. The single most-repeated practice across sources is **cross-model review** — each model family catches error categories the other misses [4][6][7].

For cross-host portability (one skill working in both Claude Code and Codex CLI), the settled pattern is **content-only portability**: stick to the Agent Skills open spec (agentskills.io), avoid host-specific syntax in the body, declare host expectations in the `compatibility` frontmatter field, and install via symlinks into each host's discovery path (`~/.claude/skills/` and `~/.agents/skills/` are different directories with no overlap) [8][9][10]. Hosts silently ignore unknown frontmatter, so Claude-Code-only keys are safe to include.

## Key Findings

### 1. Claude Code model pinning is official and layered

Subagent model resolution order: `CLAUDE_CODE_SUBAGENT_MODEL` env var → per-invocation `model` parameter → subagent definition frontmatter → main conversation model. Subagents cannot spawn subagents (flat topology enforced). Agent teams (experimental, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, v2.1.32+) add long-running teammates with shared task lists and mailboxes, but have resume limitations and are off by default — plain subagents are the stable v1 choice [1][11].

**Confidence**: confirmed · **Sources**: [1], [11], [12]

### 2. Codex-as-worker has three wiring options; the official plugin is the lowest-friction

(a) `codex exec` headless (`--json`, `--output-last-message`, `--sandbox workspace-write`, auth via existing `codex login` state); (b) `codex mcp-server` (v0.129.0+, exposes `codex()`/`codex-reply()` tools, no streaming, one shared process); (c) the official `openai/codex-plugin-cc` Claude Code plugin — wraps the CLI, reuses local auth, exposes `--background/--wait/--resume/--fresh` execution control and review commands (`/codex:review`, `/codex:adversarial-review`). Model selection via `~/.codex/config.toml` or per-call `--model` [2][3][13].

**Confidence**: confirmed · **Sources**: [2], [3], [13]

### 3. Domain routing: the validated split

- Claude/Opus: better UIs from broad prompts ("Claude still creates better UIs when given a broad task" — HN), cross-file reasoning, QA-style proactive analysis, security audits [4][5][6].
- GPT-5.x/Codex: sustained autonomous execution (46+ min unattended loops reported), early architectural decisions, deterministic/structured outputs, bulk mechanical work at scale on cost grounds [4][5].
- Caveat: Codex first-pass output described as "quite sloppy" but improvable with review passes — supports a mandatory orchestrator review gate on Codex output [5].
- Thomson Reuters Labs routes by **role** (plan/execute/review across different model families) rather than domain — the value is failure-mode diversity, not domain specialization per se [7].

**Confidence**: confirmed (direction), contested (exact FE/BE assignment — one vendor source flips it) · **Sources**: [4], [5], [6], [7]

### 4. Worker briefs: the make-or-break factor

Confirmed practices: briefs must be fully self-contained (workers never see orchestrator history); scope to specific files with **one file, one owner** across parallel workers; name concrete deliverables; state out-of-scope explicitly ("the card said CSV export only"); include iteration caps (workers are time-blind and will thrash); review gates run fail-fast (format → lint → types → tests → diff-size guard → review). Multi-agent token overhead is 2–5× single-agent for equivalent work — **do not delegate trivia** [11][14][15].

**Confidence**: confirmed · **Sources**: [11], [14], [15]

### 5. Named anti-patterns

"Orchestrator-as-god" (one LLM holds all state and also implements — latency stacks, one bad token poisons the run); "every-agent-can-call-every-agent" (mesh topology, no audit point); lead implementing tasks itself instead of waiting (flagged in official docs); LLM-self-updating context files (reduces success ~3%, +20% cost — keep skill/config files human-curated); naive sequential chaining (39–70% context degradation cited) [11][14][15].

**Confidence**: confirmed · **Sources**: [11], [14], [15]

### 6. Cross-host skill portability

Agent Skills open spec is the portable layer: `name` + `description` frontmatter, natural-language body, optional `compatibility` field for host requirements. Claude Code extensions (`!` injection, `$ARGUMENTS`, `context: fork`, `model`, `hooks`) are not portable — Codex renders them as literal text or silently ignores frontmatter keys. Discovery paths differ: CC `~/.claude/skills/`, Codex `~/.agents/skills/` (+ repo `.agents/skills/`) — symlink into both. Superpowers (174k stars) proves the content-only strategy at scale: same SKILL.md folder runs on CC, Codex, Cursor, Gemini CLI [8][9][10][16].

**Confidence**: confirmed · **Sources**: [8], [9], [10], [16]

## Contradictions & Open Questions

- **Codex for frontend?** emergent.sh (vendor) positions Codex as better for "tight iterative frontend loops"; HN community and the dual-wielding practitioner report the opposite (Claude better UIs). Community + first-person reports weighted higher; vendor framing discounted [4][5][6].
- **Agent teams vs plain subagents** for the orchestrator host: teams add persistence and mailboxes but are experimental with resume limitations. No source benchmarks one against the other for build-phase work. Plain subagents chosen for v1; revisit when teams exit experimental.
- The exact net cost/quality delta of model-matched routing vs single-model fleets is unquantified anywhere — all sources argue from failure-mode diversity, not controlled benchmarks.

## Methodology

Five parallel retrieval agents (Sonnet), each running WebSearch + full-page WebFetch on 2–3 sources: (A1) official Claude Code subagent/model docs, (A2) Codex headless/MCP/plugin mechanics, (A3) community routing experience (HN, practitioner blogs), (A4) Agent Skills spec + cross-host portability, (A5) orchestration patterns/anti-patterns (Osmani, TR Labs, dev.to). Local recon of the user's own setup (`~/.codex/AGENTS.md`, `~/.agents/skills/`, conductor `pipelines.yaml`, codex plugin runtime contract) grounded the host-specific findings. Second research wave skipped — all sub-questions reached confirmed coverage.
