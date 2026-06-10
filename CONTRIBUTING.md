# Contributing to Crew

Thanks for your interest in contributing! Here's how to get started.

## Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Make your changes
4. Commit with conventional style (`feat:`, `fix:`, `docs:`, etc.)
5. Open a pull request

## Development

Crew is a markdown-based agent skill — there is no build step. The skill
lives at `skills/crew/SKILL.md` with worker definitions under
`skills/crew/workers/`. Test changes by symlinking the skill directory
into a host (`~/.claude/skills/crew` for Claude Code, `~/.agents/skills/crew`
for Codex) and exercising it on a real multi-domain task.

Keep `SKILL.md` within the Agent Skills spec's portable core (no
host-specific syntax in the body) — the cross-host capability gate depends
on it. Worker definitions are the right place for host-specific spawn
mechanics.

## Code Style

- Concise, minimal commentary — skills are instructions, not essays
- Design before code — propose structural changes in an issue first
- Every behavioral rule in the skill should earn its tokens

## Reporting Issues

Use the GitHub issue templates for bug reports and feature requests.
