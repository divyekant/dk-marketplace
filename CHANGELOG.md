# Changelog

All notable changes to Argos will be documented in this file.

## [0.2.0] - 2026-03-07

### Changed
- **Breaking:** Replace action-based tiers (auto/approve/deny) with 5-level confidence model
  - Level 1: Should Fix (full autonomy)
  - Level 2: Fix + Summary Review (human glances at summary)
  - Level 3: Fix + Thorough Review (human reviews diff before PR opens)
  - Level 4: Needs Approval (investigate only, human decides)
  - Level 5: Can't Touch (label and flag, no action)
- Policy YAML redesigned: `floors` (paths, types, authors, minimum) replace `actions` tiers
- `deny` section replaces `protected_paths` — covers both actions and file paths
- Notification channels tagged `internal`/`external` — content shaped by audience
- `/watch` auto-starts `/loop` after onboarding (no manual copy-paste)
- `/watch` handles re-watch: asks to update policy, change interval, or restart
- Session-start hook simplified: no timeout logic, just pending count
- Onboarding flow asks about confidence floors, sensitive paths, author trust

### Added
- Context stack: Argos reads project files, Carto data, and Memories before triage
- `apply_floors` — computes effective level from AI assessment + policy constraints
- `is_action_denied` / `is_path_denied` — hard denial checks
- `get_channel_type` / `get_channels_by_type` — audience-aware notification routing
- `check_policy_format` — detects old action-based policies and refuses to process, directs user to `/watch` to migrate
- Pheme integration — optional MCP-level notification channel with urgency mapping (L1→low, L3-5→high, injection→critical)
- Calibration memories: stores human approve/reject decisions for future triage tuning
- Product boundary awareness via project docs and Carto integration

### Removed
- `get_action_tier`, `get_approval_mode`, `get_approval_timeout` — replaced by floors
- `is_path_protected`, `get_notification_channels` — replaced by deny/channel functions
- Timeout/wait/default approval modes — levels define oversight implicitly

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
