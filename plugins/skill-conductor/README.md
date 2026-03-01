# Skill Conductor

A skill composition framework for [Claude Code](https://claude.com/claude-code). Compose skills from multiple sources into configurable pipelines with a runtime router.

## The Problem

As the Claude Code skill ecosystem grows, you accumulate skills from different sources. Each works great alone, but:

- **Trigger conflicts** — multiple skills fire on the same task type
- **No sequencing** — nothing declares which skill runs before which
- **No composition** — skills that should work together are independent peers
- **Manual wiring** — every new skill means figuring out how it fits

## The Solution

A **conductor skill** that reads a `pipelines.yaml` config and:

1. **Classifies** your task into a pipeline
2. **Selects** the right workflow
3. **Sequences** skills through phases in order
4. **Handles** escalation, modifiers, and user overrides

## Quick Start

```bash
git clone --recursive https://github.com/divyekant/skill-conductor.git ~/.local/share/skill-conductor
cd ~/.local/share/skill-conductor
./install.sh
```

This symlinks the conductor and vendored skills into `~/.claude/skills/`. Start a new Claude Code session — the conductor loads automatically.

### What gets installed

| Skill | Source |
|-------|--------|
| conductor | This repo — the runtime router |
| shaping | [rjs/shaping-skills](https://github.com/rjs/shaping-skills) |
| breadboarding | [rjs/shaping-skills](https://github.com/rjs/shaping-skills) |
| breadboard-reflection | [rjs/shaping-skills](https://github.com/rjs/shaping-skills) |

Existing skills in `~/.claude/skills/` are untouched. If a name conflicts, the installer asks before overriding.

### First-run onboarding

On your first conversation after install, the conductor detects a fresh setup and walks you through configuration:

1. **Discovers** what skills and plugins you already have installed
2. **Asks** what other skills you want to include
3. **Learns** your preferred workflow (how many pipelines, which phases matter)
4. **Generates** a `pipelines.yaml` tailored to your setup

No manual YAML editing needed. Just have a conversation.

## How It Works

### Phases

Ordered slots in a development lifecycle. Define as many or few as you need:

```
explore → shape → plan → build → verify → review → finish
```

### Skill Types

- **Phase skills** — run as a step in the pipeline sequence
- **Modifier skills** — trigger conditionally (e.g., visual validation after `.tsx` edits)
- **Always-available skills** — invokable at any point regardless of current phase

### Pipelines

Named workflows that select which phases and skills to use:

```yaml
pipelines:
  quick-fix:
    phases: [build, verify]
    skills:
      build: [my-debugging-skill]
      verify: [my-verification-skill]

  feature:
    phases: [explore, plan, build, verify, review]
    skills:
      explore: [brainstorming]
      plan: [writing-plans]
      build: [tdd]
      verify: [verification]
      review: [code-review]
```

### Usage

```
You: Add a search bar to the dashboard

Claude: This looks like a **feature** task. I'd follow this pipeline:
       explore → plan → build → verify → review

       Should I proceed, or would you classify it differently?

You: Proceed

Claude: [invokes first skill in explore phase...]
```

**User overrides** — you're always in control:
- Skip phases: "Skip exploration, I know what I want"
- Jump ahead: "Let's go straight to building"
- Change pipeline: "Actually this needs more shaping"
- Invoke directly: call any skill by name at any time

## Customization

### Edit pipelines.yaml

The default config ships with a minimal pipeline using vendored shaping skills. Customize it for your workflow:

```yaml
skills:
  my-skill:
    source: external          # or vendor/..., plugin/...
    phase: build              # which phase this skill belongs to
    type: phase               # phase or modifier

pipelines:
  my-workflow:
    description: My team's workflow
    phases: [explore, build, verify]
    skills:
      explore: [brainstorming]
      build: [my-skill]
      verify: [my-verification]
```

### Add a new skill

1. Add an entry to `pipelines.yaml` under `skills:`
2. Ensure the skill is available in `~/.claude/skills/` (symlink, clone, or plugin)
3. Reference it in the appropriate pipeline

No adapters needed — Claude reads any skill directly.

### Full example with Superpowers

See [`examples/pipelines-superpowers.yaml`](examples/pipelines-superpowers.yaml) for a complete setup wiring together:
- [Superpowers](https://github.com/obra/superpowers) (brainstorming, TDD, debugging, code review)
- [Shaping skills](https://github.com/rjs/shaping-skills) (Shape Up methodology)
- [Review loop](https://github.com/hamelsmu/claude-review-loop) (automated Codex review)
- [ui-val](https://github.com/AshDevFr/ui-val) (visual validation)

Copy it to `pipelines.yaml` to use it:

```bash
cp examples/pipelines-superpowers.yaml pipelines.yaml
```

## Architecture

```
skill-conductor/
├── pipelines.yaml          # Your pipeline config (customize this)
├── skills/
│   └── conductor/          # The runtime router skill
│       └── skill.md
├── vendor/                 # Git submodules (pinned versions)
│   ├── shaping-skills/
│   └── review-loop/
├── vendor.lock             # Human-readable version pins
├── examples/               # Example configs for common setups
├── install.sh              # Symlinks skills into ~/.claude/skills/
└── uninstall.sh            # Removes symlinks
```

### Vendor management

External skills are pinned via git submodules. Update a vendor:

```bash
cd vendor/shaping-skills
git pull origin main
cd ../..
git add vendor/shaping-skills
git commit -m "chore: update shaping-skills"
```

## Uninstall

```bash
cd ~/.local/share/skill-conductor
./uninstall.sh
```

Removes only the symlinks this project created. Restores backups if any were made during install.

## Credits

Built on ideas from:
- [superpowers](https://github.com/obra/superpowers) by [@obra](https://github.com/obra)
- [shaping-skills](https://github.com/rjs/shaping-skills) by [@rjs](https://github.com/rjs)
- [claude-review-loop](https://github.com/hamelsmu/claude-review-loop) by [@hamelsmu](https://github.com/hamelsmu)

## LLM Quickstart

Want to give this to a different LLM? See [LLM-QUICKSTART.md](LLM-QUICKSTART.md) — a single page that explains the entire system in a format any LLM can consume.

## License

MIT
