# Changelog

All notable changes to codex-cu are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-10-04

### Added

- Stdio proxy for the Codex computer-use server (`cua_repl`). The proxy adds Codex turn metadata to each tool call.
- Stop hook that releases the tabs of the ended turn for the same Claude session only.
- Self-check `test.mjs`.
