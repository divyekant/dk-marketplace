# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-02

### Added
- `bin/pencil-start.sh` with `--check`, `--install`, `--start`, `--status` flags
- Automated Pencil.dev download and installation (ARM64 + x86_64)
- Port readiness polling with configurable timeout
- `skill.md` with full prototyping flow (install → launch → canvas → draw → capture)
- Conductor integration as always-available + shape phase skill
- bats test suite (13 tests)
- Design document and implementation plan
