# Changelog

## [Unreleased]

## [1.0.1] - 2026-03-11

### Added
- Codex install guide at `.codex/INSTALL.md`
- Root `AGENTS.md` so the Apollo repo itself is first-class in Codex

### Changed
- README now documents Codex skill discovery via `~/.agents/skills/`

## [1.0.0] - 2026-02-28

### Added
- `dev:` section in config for local development environment (runtime, services/ports, commands)
- Onboarding questions for dev environment setup
- `/apollo check` validates dev environment (duplicate ports, compose file existence)
- Natural language support for adding dev config ("we use docker compose", "api on 3001")
- Session start hook with project status one-liner
- Multi-agent support (Cursor, Codex, Windsurf, Copilot, Aider)
- OSS scaffolding (LICENSE, CONTRIBUTING, CODE_OF_CONDUCT)

### Fixed
- Session start hook shows status only on first response of session

## [0.1.0] - 2026-02-27

### Added
- Apollo skill (SKILL.md) with all sub-commands: config, init, check, release, bare, add-to-apollo
- Config schema with full documented example (defaults.example.yaml)
- Three built-in templates: oss, personal, work
- Three-tier config resolution: defaults -> template -> project override
- Conversational onboarding via /apollo config
- CLAUDE.md instruction injection with managed section markers
- Versioning support (manifest-based and internal)
- Optional Memories MCP enrichment layer
- Agent-agnostic design: config at ~/.apollo/, adapters per agent platform
- README with install, commands, and config reference
- Design document and implementation plan
