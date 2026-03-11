# Changelog

All notable changes to Skill Conductor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2026-03-11

### Added
- Codex install guide at `.codex/INSTALL.md`
- Root `AGENTS.md` so the repo itself is first-class in Codex

### Changed
- README now documents Codex discovery via `~/.agents/skills/`
- The conductor skill now scans both `~/.claude/skills/` and `~/.agents/skills/` when looking for installed skills
