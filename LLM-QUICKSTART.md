# Skill Conductor — LLM Quickstart

Give this page to any LLM to explain the skill conductor system.

---

## What is Skill Conductor?

Skill Conductor is a framework for composing AI coding skills into ordered pipelines. Instead of skills firing independently (and conflicting), a **conductor** routes tasks through **phases** in sequence, invoking the right skills at the right time.

## Core Concepts

**Phase** — An ordered step in a development workflow. Standard phases:

| Phase | Order | Purpose |
|-------|-------|---------|
| explore | 10 | Understand the problem |
| shape | 20 | Define requirements and solution options |
| plan | 30 | Create implementation plan |
| build | 40 | Write code |
| verify | 50 | Test and validate |
| review | 60 | Code review |
| finish | 70 | Ship it |

**Skill** — A markdown file with instructions for the LLM. Skills are assigned to phases. Three types:
- **Phase skill** — runs as a step in the pipeline
- **Modifier skill** — triggers conditionally (e.g., after `.tsx` edits, run visual validation)
- **Always-available skill** — can be invoked anytime regardless of current phase

**Pipeline** — A named workflow that selects which phases and skills to use. Examples:
- `quick-fix`: build → verify
- `feature`: explore → plan → build → verify → review → finish
- `complex`: explore → shape → plan → build → verify → review → finish

## How It Works

1. User describes a task
2. Conductor reads `pipelines.yaml` config
3. Conductor classifies the task → selects a pipeline
4. Conductor presents the pipeline to the user for confirmation
5. Conductor invokes skills phase by phase via the Skill tool
6. At each phase transition, conductor announces: "Phase X complete. Moving to Y."
7. User can override, skip phases, change pipeline, or invoke any skill directly

## Configuration File: pipelines.yaml

```yaml
# Define phases
phases:
  explore: { order: 10, description: Understand the problem }
  build:   { order: 40, description: Write code }
  verify:  { order: 50, description: Test and validate }

# Map skills to phases
skills:
  my-brainstorming-skill:
    source: plugin/my-plugin    # source is documentation only
    phase: explore
    type: phase

  my-tdd-skill:
    source: ~/.claude/skills/tdd
    phase: build
    type: phase

  ui-validator:
    source: external
    phase: verify
    type: modifier
    triggers:
      files-changed: ["*.tsx", "*.css"]

# Skills available at any time
always-available:
  - my-thinking-skill
  - my-learning-skill

# Define pipelines
pipelines:
  quick:
    description: Fast fix
    phases: [build, verify]
    skills:
      build: [my-tdd-skill]
      verify: [ui-validator]

  full:
    description: Full feature workflow
    phases: [explore, build, verify]
    skills:
      explore: [my-brainstorming-skill]
      build: [my-tdd-skill]
      verify: [ui-validator]
```

## Key Rules for the Conductor

1. **Classify before acting** — always determine the pipeline before doing anything
2. **Present and confirm** — show the user the proposed pipeline, wait for approval
3. **Invoke skills via Skill tool** — never read skill files directly or rely on memory
4. **Announce transitions** — tell the user when moving between phases
5. **Allow overrides** — user can skip, jump, change pipeline, or invoke skills directly
6. **Escalate when needed** — if a task turns out more complex, suggest a bigger pipeline
7. **Track state conversationally** — no external storage needed, just mental tracking of current pipeline/phase

## Onboarding (First Run)

If `pipelines.yaml` contains `setup: needed`, run an onboarding flow:

1. Scan `~/.claude/skills/` and plugins for installed skills
2. Ask the user what skills they want to include (any skill — not limited to a menu)
3. Ask about workflow preferences (phases, number of pipelines)
4. Generate a personalized `pipelines.yaml`
5. Remove the `setup: needed` flag

## File Structure

```
skill-conductor/
├── pipelines.yaml          # User's pipeline config
├── skills/conductor/       # The conductor skill (this document describes its behavior)
├── vendor/                 # External skills (git submodules)
├── examples/               # Example configs for reference
├── install.sh              # Symlinks skills into ~/.claude/skills/
└── uninstall.sh            # Removes symlinks
```

## Adding a New Skill

1. Add entry to `pipelines.yaml` under `skills:`
2. Ensure the skill is available (in `~/.claude/skills/`, as a plugin, or anywhere the Skill tool can find it)
3. Add it to the appropriate pipeline under `pipelines:`

That's it. No adapters, no wrappers. The LLM reads the skill directly.
