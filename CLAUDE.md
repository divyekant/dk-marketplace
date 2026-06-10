<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
- Language: markdown, package manager: none
- Commits: conventional style (feat:, fix:, chore:, etc.)
- Never auto-commit — always ask before committing
- Branch strategy: feature branches
- Code style: concise, comments: minimal
- Design before code: always run brainstorming/design phase first
- Design entry: invoke conductor skill for all design/brainstorm work
- Maintain README.md
- Maintain CHANGELOG.md
- Maintain a Quick Start guide
- Maintain architecture documentation
- Track decisions in docs/decisions/
- Update docs on: feature
- Code review required before merging
- Versioning: semver
- Check for secrets before committing
<!-- APOLLO:END -->

# crew

Multi-model build orchestrator skill. The skill itself is
`skills/crew/SKILL.md`; worker definitions live in `skills/crew/workers/`.
Keep the SKILL.md body within the Agent Skills portable core — the
cross-host capability gate depends on it. Host-specific spawn mechanics
belong in the worker definition files.
