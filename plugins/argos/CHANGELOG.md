# Changelog

All notable changes to Argos will be documented in this file.

## [0.1.0] - 2026-03-06

### Added
- Core Argos skill with issue triage, classification, and action pipeline
- Tiered autonomy: auto/approve/deny action tiers with per-action approval modes (wait/timeout/default)
- Shell libraries: poll.sh, state.sh, notify.sh, policy.sh
- Pluggable notification adapters: github-comment, system (macOS), session
- Commands: /watch, /unwatch, /argos-status, /argos-approve
- Guided onboarding flow for policy creation via /watch
- SessionStart hook for pending approval injection
- Default policy template with guardrails (rate limiting, protected paths, dry run)
- Prompt injection detection and security-review labeling
- Memories MCP integration for cross-session learning
- Duplicate issue detection via title similarity

### Fixed
- Shell injection in commit messages and PR titles (sanitize untrusted input)
- Shell injection in github-comment adapter (use --body-file pipe)
- Path traversal in adapter name dispatch (regex validation)
- Stored prompt injection via session file (sanitize before write)
- Expanded prompt injection detection to 12+ patterns
- Label action validates classification against whitelist
- `git add -A` replaced with explicit staging + protected path check
- `create_branch` default changed from auto-proceed to auto-skip

### Security
- Issue content treated as untrusted input throughout
- Security rules in SKILL.md (section 6) with explicit injection defense
- Protected paths guardrail prevents committing secrets
- Rate limiting caps actions per hour
- Dry run mode as first-class safety valve
