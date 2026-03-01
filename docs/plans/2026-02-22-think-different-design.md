# think-different: Design Document

**Date:** 2026-02-22
**Status:** Approved

## What It Is

An on-demand Claude Code skill that shifts how Claude approaches a problem. Not a checklist — a thinking mode. When invoked, Claude stops straight-line problem-solving and applies lateral thinking through a razor-governed process.

## Governing Principle

Occam's Razor. Try the simplest reframe first. Only escalate if it doesn't cut.

## Skill Properties

- **Type:** Rigid process, flexible output
- **Trigger:** User invokes explicitly — never auto-triggered
- **Standalone repo:** `github.com/divyekant/think-different`
- **No dependencies:** No hooks, no MCP, no external tools. Pure thinking.

## The Flow

### Phase 1: Diagnose the Blockage

Read conversation context to understand:
- What's been tried (to avoid repeating)
- What framing led to those attempts (to challenge it)
- What kind of stuck this is:

| Stuck type | Signal |
|---|---|
| Wrong problem | Solution works but doesn't help |
| Wrong assumptions | Same wall from every angle |
| Overcomplicated | Solution exists but feels too complex |
| Tunnel vision | Only one approach considered |
| Treating symptoms | Fixes keep spawning new issues |

### Phase 2: Razor Reframe

- Start with ONE framework (most relevant to diagnosed stuck type)
- Generate an alternative path from that reframe
- If single reframe produces a clear path → present it with 1-2 lighter alternatives
- If it doesn't cut deep enough → layer one more framework, repeat
- Never apply more than 3 frameworks per invocation

### Phase 3: Present and Execute

- Present 2-3 reframed paths, ranked with recommendation
- Explain *why* each path differs from what was tried (not just *what*)
- User picks → Claude executes that approach

Goal: 30-second gear shift, not 10-minute workshop.

## Framework Reference Table

Internal toolkit — Claude selects from these, never exposes the table to the user.

| Framework | Best for | The move |
|---|---|---|
| Reframe | Wrong problem | Restate what you're actually solving |
| First Principles | Wrong assumptions | Strip to fundamentals, rebuild |
| Inversion | Can't see path forward | "How would I guarantee failure?" |
| SCAMPER | Iterating on existing | Substitute, Combine, Adapt, Modify, Eliminate, Reverse |
| Analogize | Domain exhausted | Find same pattern in different domain |
| Constrain | Too many options | Add deliberate limit to force depth |
| Simplify | Overcomplicated | Solve the smallest version first |
| Bisect | Unknown failure location | Binary search the problem space |
| 5 Whys | Treating symptoms | Drill to root cause |
| Premortem | Before complex approach | "Imagine this already failed — why?" |
| Provocation | Tunnel vision | Make absurd statement, explore from there |
| Rubber Duck | Going in circles | Articulate as if to a beginner |
| Check Biases | Certain but stuck | Question anchoring, sunk cost, confirmation bias |
| Perspective Shift | Narrow framing | Look from user/ops/security/perf angle |
| Chesterton's Fence | Tempted to rip out | Understand why it exists before removing |

### Stuck Type → Framework Mapping

- **Wrong problem** → Reframe, Rubber Duck, 5 Whys
- **Wrong assumptions** → First Principles, Inversion, Check Biases
- **Overcomplicated** → Simplify, Constrain, SCAMPER (Eliminate)
- **Tunnel vision** → Provocation, Analogize, Perspective Shift
- **Treating symptoms** → 5 Whys, Inversion, Chesterton's Fence

Claude picks the top match from the relevant stuck type. If it doesn't land, picks next from same row.

## File Structure

```
think-different/
├── SKILL.md        ← entire skill (flow + framework table)
├── README.md       ← what it is, install, usage examples
└── install.sh      ← registers in Claude Code settings
```

## Context Handling

When invoked mid-task, the skill:
- Reads conversation context to know what's been tried
- Challenges the framing that led to those attempts
- Uses prior attempts as "what NOT to repeat" rather than "what to build on"
- Avoids anchoring on previous approaches

## Research Basis

Built from 15 established thinking frameworks:
- Lateral Thinking (de Bono), First Principles (Aristotle/Musk), Inversion (Munger)
- TRIZ, Constraint-based creativity, Oblique Strategies (Eno)
- 5 Whys (Toyota), Rubber Duck Debugging, Analogical Thinking
- SCAMPER, Premortem (Klein), Polya's Problem-Solving
- Hammock-Driven Development (Hickey), Chesterton's Fence, Cognitive Bias Awareness
