# think-different Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a standalone on-demand Claude Code skill that shifts problem-solving approach using Occam's Razor-governed lateral thinking.

**Architecture:** Single SKILL.md file containing the full skill (rigid process + framework reference table). install.sh copies SKILL.md to superpowers plugin directory. No hooks, no MCP, no external dependencies.

**Tech Stack:** Markdown (SKILL.md), Bash (install.sh), Git

**Design doc:** `docs/plans/2026-02-22-think-different-design.md`

---

### Task 1: Create SKILL.md

**Files:**
- Create: `SKILL.md`

**Step 1: Write the SKILL.md file**

```markdown
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
```

**Step 2: Verify the file looks correct**

Read `SKILL.md` end-to-end and verify:
- YAML frontmatter has `name` and `description`
- Three phases are clearly separated
- Framework table is complete (15 entries)
- Stuck type mapping has all 5 types
- Red flags table is present
- Quick reference table is present

**Step 3: Commit**

```bash
git add SKILL.md
git commit -m "feat: add think-different skill definition"
```

---

### Task 2: Create install.sh

**Files:**
- Create: `install.sh`

**Step 1: Write the install.sh script**

The script should:
1. Detect the superpowers plugin version directory
2. Create the skill directory at `$SKILLS_DIR/<version>/skills/think-different/`
3. Copy `SKILL.md` into that directory
4. Print success message

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"

# Find the latest version directory
VERSION_DIR=$(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | sort -V | tail -1)

if [ -z "$VERSION_DIR" ]; then
    echo "Error: Could not find superpowers plugin directory at $SKILLS_DIR"
    echo "Make sure you have the superpowers plugin installed in Claude Code."
    exit 1
fi

DEST="$VERSION_DIR/skills/think-different"
mkdir -p "$DEST"
cp "$SCRIPT_DIR/SKILL.md" "$DEST/SKILL.md"

echo "think-different skill installed to: $DEST"
echo ""
echo "Restart Claude Code to pick up the new skill."
echo "Usage: invoke with /think-different or say 'use the think-different skill'"
```

**Step 2: Make it executable**

```bash
chmod +x install.sh
```

**Step 3: Test installation locally**

```bash
./install.sh
```

Expected output: `think-different skill installed to: /Users/divyekant/.claude/plugins/cache/claude-plugins-official/superpowers/<version>/skills/think-different`

**Step 4: Verify the file was copied**

```bash
ls -la ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/think-different/SKILL.md
```

Expected: file exists with correct content.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "feat: add install script for skill registration"
```

---

### Task 3: Create README.md

**Files:**
- Create: `README.md`

**Step 1: Write the README**

```markdown
# think-different

An on-demand Claude Code skill that shifts how Claude approaches problems. When the straight-line approach isn't working, invoke this skill to get Claude to think laterally.

## What It Does

When invoked, the skill:

1. **Diagnoses** what kind of stuck you're in (wrong problem, wrong assumptions, overcomplicated, tunnel vision, treating symptoms)
2. **Reframes** using the simplest applicable thinking framework (Occam's Razor governs — only escalate if needed)
3. **Presents** 2-3 alternative paths ranked with a recommendation

It draws from 15 established thinking frameworks including First Principles, Inversion, SCAMPER, 5 Whys, Premortem, and others — but you never see the machinery. You just get fresh angles.

## Install

```bash
git clone https://github.com/divyekant/think-different.git
cd think-different
./install.sh
```

Then restart Claude Code.

## Usage

Invoke it when you need a different angle:

- "Use the think-different skill"
- "Think different about this problem"
- "I'm stuck, help me reframe"
- `/think-different`

### When to use it

- You've hit a wall and the same approach keeps failing
- You want Claude to challenge its current framing
- You want creative alternatives before starting work
- The proposed solutions don't feel right

### When NOT to use it

- The obvious approach hasn't been tried yet
- You're debugging (use `systematic-debugging` instead)
- The problem is genuinely straightforward

## How It Works

**Governing principle: Occam's Razor.** Start with the simplest reframe. Only go deeper if it doesn't cut.

The skill diagnoses your blockage type, then selects from its internal framework toolkit:

| Stuck Type | Example Signal |
|---|---|
| Wrong problem | "Solution works but doesn't help" |
| Wrong assumptions | "Same wall from every angle" |
| Overcomplicated | "This feels too heavy" |
| Tunnel vision | "Only one approach considered" |
| Treating symptoms | "Fixes keep spawning new issues" |

Each stuck type maps to 3 ranked frameworks. The skill applies the top match first, escalates only if needed, never applies more than 3 per invocation.

## Research Basis

Built from 15 established thinking frameworks:

- Lateral Thinking (de Bono), First Principles (Aristotle/Musk), Inversion (Munger)
- TRIZ, Constraint-based Creativity, Oblique Strategies (Eno)
- 5 Whys (Toyota), Rubber Duck Debugging, Analogical Thinking
- SCAMPER, Premortem (Klein), Polya's Problem-Solving
- Hammock-Driven Development (Hickey), Chesterton's Fence, Cognitive Bias Awareness

## License

MIT
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with install and usage instructions"
```

---

### Task 4: Create GitHub repo and push

**Step 1: Create the GitHub repository**

```bash
cd /Users/divyekant/Projects/think-different
gh repo create divyekant/think-different --public --source=. --push --description "On-demand lateral thinking skill for Claude Code"
```

**Step 2: Verify the repo exists**

```bash
gh repo view divyekant/think-different
```

Expected: repo is public, has all commits.

---

### Task 5: Test the skill end-to-end

**Step 1: Run install.sh**

```bash
cd /Users/divyekant/Projects/think-different
./install.sh
```

**Step 2: Verify SKILL.md is in the right location**

```bash
cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/think-different/SKILL.md | head -5
```

Expected: YAML frontmatter with `name: think-different`.

**Step 3: Restart Claude Code and verify skill appears**

Restart Claude Code. The skill should appear in the available skills list as:
```
- superpowers:think-different: Use when the straight-line approach isn't working...
```

**Step 4: Test invocation**

In a new Claude Code session, say "use the think-different skill" while working on any problem. Verify:
- Phase 1 diagnosis happens
- Phase 2 applies a framework
- Phase 3 presents 2-3 ranked paths
