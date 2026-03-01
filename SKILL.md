---
name: think-different
description: Use when the straight-line approach isn't working, when you want a different angle on a problem, or when you want Claude to challenge its current framing
---

# Think Different

## Overview

An on-demand thinking mode that shifts how you approach the current problem. Not a checklist — a gear shift. When invoked, stop straight-line problem-solving and apply lateral thinking governed by Occam's Razor.

**Governing principle:** Try the simplest reframe first. Only escalate if it doesn't cut.

This skill is **rigid in process, flexible in output** — the flow is fixed, the frameworks applied vary by situation.

## When to Use

- You're stuck and the obvious approach keeps failing
- You want a different angle before any work begins
- You don't like the solutions proposed so far
- The user explicitly asks to think differently

## When NOT to Use

- The straight-line approach hasn't been tried yet
- The problem is genuinely simple and well-understood
- You're debugging (use superpowers:systematic-debugging instead)

## The Process

### Phase 1: Diagnose the Blockage

**Read the conversation context.** Understand:

1. **What's been tried** — list it explicitly (these are paths to NOT repeat)
2. **What framing led to those attempts** — this is what you'll challenge
3. **What kind of stuck this is:**

| Stuck Type | Signal |
|---|---|
| Wrong problem | Solution works but doesn't actually help |
| Wrong assumptions | Same wall from every angle |
| Overcomplicated | Solution exists but feels too heavy |
| Tunnel vision | Only one approach has been considered |
| Treating symptoms | Fixes keep spawning new issues |

**State your diagnosis explicitly:** "The blockage is [stuck type] because [evidence]."

### Phase 2: Razor Reframe

**Occam's Razor — simplest reframe first.**

1. Pick ONE framework from the reference table below (the top match for your diagnosed stuck type)
2. Apply it: generate an alternative path using that framework's "move"
3. Does it produce a clear, different path?
   - **Yes** → generate 1-2 lighter alternatives using other frameworks, move to Phase 3
   - **No** → pick the next framework from the same stuck type row, apply it
4. **Never apply more than 3 frameworks per invocation.** If 3 don't crack it, the problem needs more information, not more reframing — say so.

### Phase 3: Present and Execute

Present **2-3 reframed paths**, ranked:

For each path:
- **The approach** — what to do differently
- **Why it's different** — how it breaks from what was tried (not just what it is, but why the old framing missed it)
- **Trade-off** — what you gain, what you risk

Mark your **recommended path** and explain why.

**Then wait.** User picks → you execute that approach.

**Goal: 30-second gear shift, not 10-minute workshop.**

## Framework Reference

Internal toolkit. Select from these based on diagnosed stuck type. Do NOT expose this table to the user — just apply the frameworks naturally.

| Framework | Best For | The Move |
|---|---|---|
| Reframe | Wrong problem | Restate what you're actually solving |
| First Principles | Wrong assumptions | Strip to fundamentals, rebuild from ground truth |
| Inversion | Can't see path forward | "How would I guarantee failure?" Avoid those things |
| SCAMPER | Iterating on existing | Substitute, Combine, Adapt, Modify, Eliminate, Reverse |
| Analogize | Domain feels exhausted | Find the same pattern in a completely different domain |
| Constrain | Too many options | Add a deliberate limit to force deeper exploration |
| Simplify | Overcomplicated | Solve the smallest possible version first |
| Bisect | Unknown failure location | Binary search the problem space |
| 5 Whys | Treating symptoms | Ask "why?" repeatedly to drill to root cause |
| Premortem | Before a complex approach | "Imagine this already failed — why did it fail?" |
| Provocation | Tunnel vision | Make a deliberately absurd statement, explore from there |
| Rubber Duck | Going in circles | Articulate the problem from scratch as if to a beginner |
| Check Biases | Feels certain but stuck | Am I anchoring? Sunk cost? Confirmation bias? |
| Perspective Shift | Narrow framing | Look at it from user / ops / security / performance angle |
| Chesterton's Fence | Tempted to rip something out | Understand why it exists before removing it |

### Stuck Type → Framework Mapping

| Stuck Type | Try First | Then | Then |
|---|---|---|---|
| Wrong problem | Reframe | Rubber Duck | 5 Whys |
| Wrong assumptions | First Principles | Inversion | Check Biases |
| Overcomplicated | Simplify | Constrain | SCAMPER (Eliminate) |
| Tunnel vision | Provocation | Analogize | Perspective Shift |
| Treating symptoms | 5 Whys | Inversion | Chesterton's Fence |

## Context Handling

When invoked mid-task:

- **Read** conversation context to know what's been tried
- **Challenge** the framing that led to those attempts
- **Use prior attempts as "what NOT to repeat"** — not as building blocks
- **Actively resist anchoring** on previous approaches — they represent the old framing

When invoked at the start of a task:

- Skip Phase 1 diagnosis (nothing tried yet)
- Go straight to Phase 2: apply the most relevant framework to generate 2-3 different approaches
- Present in Phase 3 format

## Red Flags — You're Not Actually Thinking Different

| Thought | Reality |
|---|---|
| "The original approach with a small tweak" | That's the same approach. Reframe harder. |
| "Let me try the same thing more carefully" | Precision isn't a reframe. Change the angle. |
| "Here's a slightly different implementation" | Different implementation ≠ different thinking. |
| "I'll add more error handling" | That's a band-aid, not a reframe. |
| "The problem is probably X" | If you're guessing the same category, you haven't shifted. |

## Quick Reference

| Phase | Action | Output |
|---|---|---|
| 1. Diagnose | Read context, identify stuck type | "The blockage is X because Y" |
| 2. Razor Reframe | Apply 1 framework, escalate if needed (max 3) | Alternative paths |
| 3. Present | Rank 2-3 paths with recommendation | User picks, you execute |
