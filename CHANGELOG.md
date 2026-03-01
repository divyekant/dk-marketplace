# Changelog

All notable changes to Delphi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-02-28

### Added
- Precondition classification: Environment (can't create) vs Data (tagged with local-db/external/inline source)
- Test data strategy: inline crafted values for boundary, validation, negative, and security cases
- Phase-aware model selection: generate defaults to opus, execute subagents default to sonnet, user-overridable
- Data strategy guidance in coverage matrix section
- Concrete precondition examples in guided case template

### Changed
- Generation rule 4 expanded with specific guidance for happy path, boundary, validation, and negative test values
- Execute Step 3a now uses two-pass precondition verification (environment first, data second)
- Subagent dispatch lines include explicit model parameter

## [1.0.0] - 2026-02-27

### Added
- Skill definition with frontmatter, overview, mode detection, and guided case format
- Generate mode: context gathering, surface discovery, case generation with coverage matrix
- Execute mode: case loading, browser/API/CLI execution, evidence capture, reporting
- Resume protocol for idempotent re-invocation across sessions
- Discovery file (.discovery.md) for progress tracking
- Flow-by-flow chunking in generate mode with parallel subagent dispatch
- Priority-tier-per-flow chunking in execute mode
- Parallel subagent dispatch for execute mode (non-UI flows run concurrently)
- Flow classification: UI flows sequential, API/CLI/background flows parallel
- Report fragment merge from parallel subagents
- External evidence storage (evidence/gc-XXX/ directories)
- Incremental report writing in execute mode
- Reference guided case examples for positive and negative paths
- LLM quickstart guide for pasting into any LLM context
- OSS scaffolding: MIT license, contributing guide, code of conduct
- Apollo project configuration

### Changed
- Step 5 (Write Output) is now incremental bookkeeping, not batch output
- Evidence referenced by path in reports, never embedded inline
