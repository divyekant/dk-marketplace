# Installing Skill Conductor for Codex

## Installation

1. Clone the repo with vendors into your Codex workspace:

   ```bash
   git clone --recursive https://github.com/divyekant/skill-conductor.git ~/.codex/skill-conductor
   ```

2. Symlink the conductor and bundled shaping skills into Codex discovery:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/skill-conductor/skills/conductor ~/.agents/skills/conductor
   ln -s ~/.codex/skill-conductor/vendor/shaping-skills/shaping ~/.agents/skills/shaping
   ln -s ~/.codex/skill-conductor/vendor/shaping-skills/breadboarding ~/.agents/skills/breadboarding
   ln -s ~/.codex/skill-conductor/vendor/shaping-skills/breadboard-reflection ~/.agents/skills/breadboard-reflection
   ```

3. Restart Codex so it discovers the skills.

## Usage

Invoke the conductor in natural language, for example:

```text
Use conductor for this task.
Route this through the right pipeline.
```

The conductor reads `pipelines.yaml` from the repo root and uses the skills available in `~/.agents/skills/`.
