---
id: rn-v0.1.0
type: release-notes
audience: internal
version: 0.1.0
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Release Notes: Argos v0.1.0

**Release Date:** 2026-03-06
**Tag:** v0.1.0
**Type:** Initial release

## Overview

Argos v0.1.0 is the initial release of the All-Seeing Issue Guardian -- a Claude Code plugin that watches GitHub repositories for new issues and acts on them within configurable tiered-autonomy boundaries. This release delivers the complete core feature set: polling, classification, tiered autonomy (auto/approve/deny), pluggable notifications, guided onboarding, and security defenses against prompt injection.

## What's New

### Core Infrastructure

- **Plugin scaffold** (`917f2dc`) -- Plugin manifest (`plugin.json`), project README, and directory structure.
- **Default policy template** (`978aa8e`) -- A conservative, production-ready `config/default-policy.yaml` with tiered autonomy, filters, notifications, and guardrails pre-configured.

### Shell Libraries

- **State management** (`9f7b4e1`) -- `lib/state.sh` provides per-repo state tracking: watermarks for seen issues, pending approval queues, hourly action counting, and rate limiting. Full test coverage in `tests/test-state.sh`.
- **Issue polling** (`1a7bdd0`) -- `lib/poll.sh` fetches issues via `gh` CLI with filtering by labels, ignore labels, issue age, and watermark. Full test coverage in `tests/test-poll.sh`.
- **Notification system** (`4161edd`) -- `lib/notify.sh` dispatches event payloads to pluggable adapters in parallel. Three built-in adapters: `github-comment` (posts on the issue), `system` (macOS notification), `session` (injects into CC session context). Full test coverage in `tests/test-notify.sh`.
- **Policy loader** (`2ca2c9e`) -- `lib/policy.sh` loads YAML policies (via `python3`/`pyyaml`), resolves action tiers, approval modes, timeouts, guardrails, and protected path patterns. Full test coverage in `tests/test-policy.sh`.

### Agent Logic

- **Core skill** (`a70aa00`) -- `skills/argos/SKILL.md` defines the complete triage and action pipeline: issue classification (bug/enhancement/duplicate/question/other), action execution with tier checks, rate limiting, dry run mode, error handling, and Memories MCP integration for cross-session learning.

### Commands

- **`/watch` and `/unwatch`** (`60a3a76`) -- Start and stop monitoring repos. `/watch` includes prerequisite checks, policy loading, and dry run preview.
- **`/argos-status` and `/argos-approve`** (`47109c7`) -- Status dashboard (active watches, pending approvals, recent actions, guardrail utilization) and approval/rejection interface.

### Onboarding & Hooks

- **Guided onboarding flow** (`36347c2`) -- 9-step conversational policy creation within `/watch`, with checkbox-style options, sensible defaults, and an interactive confirmation loop. Covers filter labels, auto/approve actions, approval modes, poll interval, notification channels, and guardrails.
- **Session-start hook** (`f2327af`) -- `hooks/session-start.sh` runs on CC session startup, summarizes pending approvals, processes expired timeouts, and injects context via `additional_context` JSON.

### Testing

- **End-to-end test** (`3c73841`) -- `tests/test-e2e.sh` simulates a full Argos cycle with mock data: state initialization, policy loading, issue parsing, filtering, tier checking, rate limiting, approval queuing, notification dispatch, and state updates (15 assertions).

### Project Configuration

- **Apollo config, CHANGELOG, LICENSE** (`2986428`) -- Apollo configuration for bash/TDD conventions, initial CHANGELOG, MIT LICENSE, and CLAUDE.md with project conventions.

## Security Fixes

All security fixes were applied in commits `f5fa445` and `6fe1452`:

- **Shell injection in commit messages and PR titles** -- Issue titles are now sanitized with `tr -cd '[:alnum:][:space:]._-'` before interpolation into shell commands.
- **Shell injection in github-comment adapter** -- Switched from direct string interpolation to `printf` with `--body-file -` (piped stdin), preventing shell expansion of untrusted content.
- **Path traversal in adapter name dispatch** -- `dispatch_to_adapter` now validates adapter names against `^[a-zA-Z0-9_-]+$`, rejecting names with slashes, dots, or special characters.
- **Stored prompt injection via session file** -- The session adapter now sanitizes details to alphanumeric characters and truncates to 200 characters before writing to the session context file.
- **Prompt injection detection expanded** -- 12+ detection patterns covering instruction overrides, identity manipulation, system prompt manipulation, LLM control tokens, and obfuscation techniques (base64, zero-width Unicode).
- **Label whitelist validation** -- The `label` action validates classifications against `"bug enhancement duplicate question other security-review"`, preventing arbitrary label application via manipulated LLM output.
- **Explicit file staging** -- `git add -A` replaced with explicit per-file staging plus protected path checking before every commit.
- **AppleScript injection prevention** -- System notification adapter sanitizes body and title before osascript interpolation.
- **Markdown injection prevention** -- GitHub comment adapter wraps details in code blocks to prevent rendered markdown from untrusted content.
- **`create_branch` approval mode** -- Default changed from `default` (auto-proceed on timeout) to `timeout` (auto-skip on timeout) for safer behavior.

## Technical Changes

### Commit Summary (16 commits)

| Category | Commits | Description |
|----------|---------|-------------|
| Design & Planning | 2 | Design document, implementation plan |
| Infrastructure | 4 | Plugin scaffold, default policy, state management, polling |
| Features | 5 | Notification system, policy loader, core skill, commands (watch/unwatch, status/approve) |
| Onboarding | 2 | Guided onboarding flow, session-start hook |
| Testing | 1 | End-to-end integration test |
| Code Review | 1 | Address code review findings (8 items) |
| Security | 1 | Fix critical and high security findings |
| Project Config | 1 | Apollo config, CHANGELOG, LICENSE |

### File Structure

```
argos/
  .claude-plugin/plugin.json
  commands/watch.md, unwatch.md, argos-status.md, argos-approve.md
  hooks/hooks.json, session-start.sh
  skills/argos/SKILL.md
  lib/poll.sh, state.sh, notify.sh, policy.sh
  lib/adapters/github-comment.sh, system.sh, session.sh
  config/default-policy.yaml
  tests/test-poll.sh, test-state.sh, test-notify.sh, test-policy.sh, test-e2e.sh
  evals/evals.json
```

### Runtime Data Locations

| Path | Purpose |
|------|---------|
| `~/.claude/argos/policies/<owner>-<repo>.yaml` | Per-repo policy files |
| `~/.claude/argos/state/<owner>-<repo>.json` | Per-repo runtime state |
| `~/.claude/argos/session-context.txt` | Session context log (ephemeral) |

## Known Limitations

1. **Single repo per `/watch` command.** Multi-repo configuration in a single policy file is not supported.
2. **No `/loop stop` API.** Stopping a watch requires manually terminating the `/loop` instance.
3. **50-issue fetch cap.** Repos with high issue velocity may miss issues beyond the 50-per-poll limit.
4. **English-only classification heuristics.** Keyword-based classification (crash, error, broken, etc.) only works for English-language issues. Labels work in any language.
5. **No rolling rate limit window.** The hourly action counter resets at clock-hour boundaries, not on a rolling 60-minute window.
6. **Duplicate detection is heuristic.** Title similarity uses substring and keyword overlap, not embedding-based similarity. False positives and false negatives are possible.
7. **Injection detection has false positives.** Legitimate issues containing phrases like "ignore previous instructions" (e.g., quoted error messages) trigger the security scanner.
8. **macOS-only system notifications.** The `system` adapter only works on Darwin. No fallback for Linux.

## Dependencies

| Dependency | Purpose | Required |
|------------|---------|----------|
| `gh` CLI | GitHub API access (issues, PRs, comments) | Yes |
| `jq` | JSON processing in shell scripts | Yes |
| `python3` | YAML policy parsing | Yes |
| `pyyaml` | Python YAML library (`pip3 install pyyaml`) | Yes |
| Memories MCP | Cross-session learning and pattern storage | Yes |
| Claude Code | Runtime environment (provides `/loop`, skills, hooks, commands) | Yes |
