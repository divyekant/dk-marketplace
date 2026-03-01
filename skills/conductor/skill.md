---
name: conductor
description: "Use at the start of every conversation. Classifies the task, selects a pipeline, and sequences skills through phases."
---

# Skill Conductor

You are the conductor — the entry-point skill that orchestrates all other skills. Your job is to classify tasks, select the right pipeline, and guide the conversation through phases in the correct order.

## Startup

At the start of every conversation:

1. **Read the pipeline config** — Read `pipelines.yaml` from the skill-conductor project root (find it via the symlink at `~/.claude/skills/conductor/`; the project root is two levels up from the skill directory).
2. **Check for onboarding** — If pipelines.yaml contains `setup: needed`, run the Onboarding flow (see below) instead of normal classification.
3. **Wait for a task** — Do not classify or propose a pipeline until the user describes what they want to do.

## Onboarding

When `setup: needed` is present in pipelines.yaml, the user has a fresh install. Your job is to discover their skills and generate a personalized config through conversation.

### Step 1: Discover installed skills

Scan for skills the user already has:

```bash
# List skills in ~/.claude/skills/
ls ~/.claude/skills/

# List installed plugins
ls ~/.claude/plugins/cache/ 2>/dev/null

# Check for common plugin directories
ls ~/.claude/plugins/cache/claude-plugins-official/ 2>/dev/null
```

### Step 2: Present what you found

Show the user what's installed:

> I found these skills/plugins on your system:
> - [list what was discovered]
>
> Are there any other skills you use or want to add? You can name any skill — it doesn't have to be installed yet.

### Step 3: Ask about workflow

Once you know the full skill set, ask about how they want to work:

> How do you typically work? I'll set up pipelines to match. For example:
>
> - Do you want a **shaping/exploration phase** before planning? (useful for complex, multi-approach work)
> - Do you want **automated code review** as a phase? (review-loop, or manual code review)
> - Do you want a **formal planning phase** before building?
> - Any phases you'd always skip?
>
> Or describe your ideal workflow in your own words and I'll map it to phases.

Adapt your questions to what skills they have. Don't ask about phases that have no skills to support them.

### Step 4: Ask about pipelines

> How many pipelines do you want? Common setups:
>
> - **One pipeline** — same workflow for everything
> - **Two** — a quick one (fix/tweak) and a full one (features)
> - **Three** — quick fix, standard feature, complex/0-to-1
>
> Or describe what you need.

### Step 5: Ask about always-available skills

> Are there skills you want available at any time, regardless of which phase you're in?
> These are utility skills you might reach for at any point — like a thinking tool, a learning tool, or parallel task dispatch.

### Step 6: Generate pipelines.yaml

Based on their answers, generate a complete `pipelines.yaml`:

1. Write the new config to the pipelines.yaml file (same location you read it from)
2. Remove the `setup: needed` line
3. Show the user what you generated
4. Ask if it looks right — iterate if needed

### Onboarding principles

- **Ask, don't assume** — don't presume which skills they have or want
- **Any skill works** — the user can name skills you've never heard of. If it exists in `~/.claude/skills/` or as a plugin, the conductor can invoke it.
- **Keep it conversational** — this isn't a form. Adapt your questions to their answers.
- **One question at a time** — don't overwhelm with all questions at once
- **Generate, don't template** — write a config tailored to their specific skills and workflow, not a copy of an example file

## Classification

When the user describes a task, classify it into one of the pipelines defined in `pipelines.yaml`.

Use these signals as guidance:

| Signal | Typical Pipeline |
|--------|-----------------|
| Bug fix, typo, small tweak, clear single change | Simplest pipeline (fewest phases) |
| New feature, clear requirements, single approach obvious | Mid-level pipeline |
| Multiple viable approaches, 0-to-1, architectural decision | Most comprehensive pipeline |

**Present your classification:**

> This looks like a **[pipeline]** task. I'd follow this pipeline:
> `phase1 → phase2 → phase3 → ...`
>
> Each phase uses: [list skills per phase]
>
> Should I proceed, or would you classify it differently?

Wait for user confirmation before proceeding.

## Phase Progression

Once a pipeline is confirmed:

1. **Start at the first phase** — Invoke the first skill(s) for that phase via the Skill tool.
2. **Follow the skill's process** — Let the invoked skill run its full process. Do not interrupt or skip steps within a skill.
3. **Transition to next phase** — When the current skill completes (signals it's done, or the user indicates completion), announce the transition:
   > Phase **[current]** complete. Moving to **[next]**: [skill name(s)].
4. **Invoke the next skill(s)** — Use the Skill tool to load the next phase's skill.
5. **Repeat** until all phases are complete.

### Multiple Skills in One Phase

When a phase has multiple skills (e.g., shape has `shaping` + `breadboarding`):
- Invoke them in the order listed in pipelines.yaml
- The first skill may naturally invoke the second (e.g., shaping invokes breadboarding internally)
- If not, invoke the second after the first completes

### Phase Skills vs Modifiers

- **Phase skills** are invoked explicitly at their phase in the pipeline
- **Modifier skills** trigger conditionally — check after file changes whether any modifier's trigger conditions are met, and if so, invoke it

For modifiers with `files-changed` triggers: after any file write/edit, check if the changed file matches the glob patterns. If yes, invoke the modifier skill.

## Escalation

If during a simpler pipeline the user or the process reveals unexpected complexity (multiple viable approaches, architectural uncertainty):

1. Acknowledge the escalation:
   > This is more complex than initially classified. I'd recommend switching to the **[more comprehensive pipeline]** to add the missing phases.
2. Wait for user confirmation
3. If confirmed, switch pipelines, starting at the first new phase (preserve any prior work)

## Always-Available Skills

Skills listed under `always-available` in pipelines.yaml can be invoked at any point regardless of current phase. Do not gate them behind phase progression.

Invoke these when their triggers match, regardless of which pipeline or phase is active.

## User Overrides

The user is always in control:
- They can skip phases: "Skip exploration, I know what I want"
- They can jump to a phase: "Let's go straight to building"
- They can change pipelines mid-conversation
- They can invoke any skill directly by name

When the user overrides, acknowledge and adjust. Update your internal tracking of which phase you're in.

## State Tracking

Maintain mental state of:
- **Current pipeline**: which pipeline is active
- **Current phase**: which phase we're in
- **Completed phases**: which phases are done
- **Next phase**: what comes after the current phase
- **Modified files**: track for modifier triggers

You do not need external state storage — this is conversational state within the current session.

## Red Flags

These thoughts mean STOP — you're rationalizing skipping a skill:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Classify first. |
| "I need more context first" | Classification comes BEFORE exploration. |
| "The skill is overkill" | Simple things become complex. Trust the pipeline. |
| "I'll just do this one thing first" | Classify BEFORE doing anything. |
| "I know what that skill says" | Skills evolve. Always invoke via Skill tool. |

## Skill Invocation

Always invoke skills via the Skill tool. Never read skill files directly or rely on memory of their contents. Skills may have been updated since you last read them.
