# deep-research

A Claude Code skill for multi-step web research that goes beyond shallow single-query search. Orchestrates parallel agents with query variance, source-type filtering, and iterative deepening to produce cited, triangulated findings.

## What it does

A single WebSearch returns one slice of the information landscape. This skill runs **multiple queries in parallel** with different phrasing and domain filters, **actually reads the pages** (not just snippets), cross-references findings, fills gaps with a second wave, and produces structured output with confidence-tagged citations.

### The pipeline

```
SCOPE       → Classify question, break into sub-questions
PLAN        → Generate query variants × source-type filters
RETRIEVE    → Parallel agents: WebSearch → WebFetch top results
TRIANGULATE → Cross-reference, flag contradictions, identify gaps
DEEPEN      → Second wave targeting gaps (if needed)
SYNTHESIZE  → findings.md + sources.md with citations
```

### Output

The skill writes to `RESEARCH/[topic-slug]/`:

- **findings.md** — Executive summary, key findings with inline citations `[1]`, confidence tags (confirmed/single-source/contested), contradictions section, methodology notes
- **sources.md** — Every source URL with metadata, type classification, and confidence rating

## Install

```bash
# Clone and symlink
git clone https://github.com/dk/deep-research.git
mkdir -p ~/.claude/skills/research
ln -sf $(pwd)/deep-research/SKILL.md ~/.claude/skills/research/SKILL.md
```

Or copy `SKILL.md` directly to `~/.claude/skills/research/SKILL.md`.

## Usage

Once installed, the skill triggers automatically when you ask Claude Code to research something:

```
> Research the current state of WebAssembly outside the browser
> Compare SQLite vs Postgres for a new SaaS product
> What does the evidence say about AI coding assistant productivity?
```

Trigger phrases: "research", "deep dive", "investigate", "look into", "what's the state of", "compare X vs Y", or any question implying multiple sources and perspectives.

## Benchmark

Evaluated across 4 topics (SQLite production readiness, Wasm outside browsers, AI coding productivity, exactly-once semantics):

| Metric | With Skill | Without Skill | Delta |
|--------|-----------|---------------|-------|
| Pass Rate | **100%** | 70% | +30% |
| Avg Time | **325s** | 509s | 36% faster |
| Avg Tokens | **50K** | 53K | 5% less |

The skill's primary value: **structural discipline** (inline citations, confidence tagging, contradictions sections) and **focused execution** (36% faster by avoiding wandering). Content quality is comparable — the skill ensures it's properly cited and organized.

## Requirements

- [Claude Code](https://claude.ai/claude-code) with access to `WebSearch`, `WebFetch`, and `Agent` tools
- No additional MCP servers or dependencies

## How it works

Instead of adding new tools, the skill orchestrates existing Claude Code primitives:

| Tool | Role | Variance lever |
|------|------|---------------|
| `WebSearch` | Find sources | Query phrasing, domain filtering |
| `WebFetch` | Read pages deeply | Extraction prompt (facts vs opinions vs code) |
| `Agent` | Parallel execution | Each agent = independent search+read pipeline |

Key design decisions:
- **Parallel agents for variance** — different query angles + source types run concurrently
- **WebFetch is mandatory** — snippets lie, pages tell the truth
- **Two retrieval waves** — initial search, then gap-targeted follow-ups
- **Domain filtering** — official docs, community (Reddit/HN), code (GitHub), academic, news
- **15-min WebFetch cache** — different extraction prompts on same URL are essentially free

## License

MIT
