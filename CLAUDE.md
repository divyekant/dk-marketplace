# Kalos

Format-agnostic design governance tool — the "Apollo for design."

<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
<!-- This section defines the standard development practices for the kalos project -->
- Language: yaml, no package manager
  <!-- Primary tech stack: YAML with shell scripts -->
- Commits: conventional style (feat:, fix:, chore:, etc.)
  <!-- All commits must follow conventional commit format for clarity and automation -->
- Never auto-commit — always ask before committing
  <!-- Manual approval required to prevent accidental commits -->
- Branch strategy: feature branches
  <!-- Development uses feature branch workflow -->
- Code style: concise, comments: minimal
  <!-- Prioritize readable code over verbose comments -->
- Design before code: always run brainstorming/design phase first
  <!-- Design phase is mandatory and precedes implementation -->
- Design entry: invoke conductor skill for all design/brainstorm work
  <!-- Use conductor capability for structured design/brainstorm sessions -->
- Code review required before merging
  <!-- Pull request review is mandatory; no direct merges to main branches -->
- Maintain README.md
  <!-- Keep project README current with setup and usage instructions -->
- Maintain CHANGELOG.md
  <!-- Track all user-facing changes in CHANGELOG following semver -->
- Maintain a Quick Start guide
  <!-- Provide expedited onboarding documentation -->
- Maintain architecture documentation
  <!-- Document system design and component relationships -->
- Track decisions in docs/decisions/
  <!-- Record significant architectural decisions in decision records -->
- Update docs on: feature
  <!-- Update documentation when new features are added -->
- Versioning: semver
  <!-- Follow semantic versioning for releases -->
- Check for secrets before committing
  <!-- Scan for hardcoded credentials and API keys before any commit -->
<!-- APOLLO:END -->
