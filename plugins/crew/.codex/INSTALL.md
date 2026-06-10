# Installing Crew for Codex

Crew is host-adaptive: on Codex it runs as a graceful pass-through (Codex
cannot spawn model-pinned subagents), announcing the degradation in one
line and continuing the build phase normally. Installing it keeps shared
pipeline configs (e.g. skill-conductor) valid across both Claude Code and
Codex without divergence.

## Installation

1. Clone Crew into your Codex workspace:

   ```bash
   git clone https://github.com/divyekant/crew.git ~/.codex/crew
   ```

2. Symlink the Crew skill into Codex discovery:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/crew/skills/crew ~/.agents/skills/crew
   ```

3. Restart Codex so it discovers the skill.

## Behavior on Codex

When invoked (directly or via a shared pipeline), Crew's capability gate
detects the missing fleet and emits:

```text
crew: no fleet on this host — executing directly.
```

The build then proceeds with Codex's normal process and any remaining
build-phase skills. Full orchestration (Opus/GPT-5.5/Sonnet workers)
requires Claude Code — see the root README.
