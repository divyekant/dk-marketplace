<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
<!-- This section defines the standard development practices for the pencil-prototyping project -->
- Language: shell, package manager: none
  <!-- Primary tech stack: Shell scripts with no package manager -->
- Commits: conventional style (feat:, fix:, chore:, etc.)
  <!-- All commits must follow conventional commit format -->
- Never auto-commit — always ask before committing
  <!-- Manual approval required to prevent accidental commits -->
- Branch strategy: feature branches
  <!-- Development uses feature branch workflow -->
- Code style: concise, comments: minimal
  <!-- Prioritize readable code over verbose comments -->
- Testing: TDD — write tests before implementation
  <!-- Test-driven development: tests are written first -->
- Test framework: bats
  <!-- Use bats (Bash Automated Testing System) for shell script testing -->
- Run tests before every commit
  <!-- Automated quality gate: no commits without passing tests -->
- Product testing: use Delphi for ui, api, cli surfaces
  <!-- Delphi tool is the standard for testing user-facing interfaces -->
- Design before code: always run brainstorming/design phase first
  <!-- Design phase is mandatory and precedes implementation -->
- Design entry: invoke conductor skill for all design/brainstorm work
  <!-- Use conductor capability for structured design/brainstorm sessions -->
- Code review required before merging
  <!-- Pull request review is mandatory -->
- Maintain README.md
  <!-- Keep project README current with setup and usage instructions -->
- Maintain CHANGELOG.md
  <!-- Track all user-facing changes in CHANGELOG following semver -->
- Maintain a Quick Start guide
  <!-- Provide expedited onboarding documentation -->
- Maintain architecture documentation
  <!-- Document system design and component relationships -->
- Track decisions in docs/decisions/
  <!-- Record significant architectural decisions -->
- Update docs on: feature
  <!-- Update documentation when new features are added -->
- Versioning: semver
  <!-- Follow semantic versioning for releases -->
- Check for secrets before committing
  <!-- Scan for hardcoded credentials and API keys before any commit -->
<!-- APOLLO:END -->
