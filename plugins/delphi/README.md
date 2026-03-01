# Delphi

*The Oracle that foresees all outcomes.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A skill for coding agents (Claude Code, Codex, Cursor, etc.) that generates and executes comprehensive test scenarios — **guided cases** — covering positive, negative, edge, accessibility, and security paths for any software.

## The Problem

Coding agents build software, run some tests, and call it done. But the gap between "tests pass" and "this actually works for users" is enormous. Delphi fills that gap by generating exhaustive test scenarios that humans can walk through and agents can execute automatically.

## Install

Clone the repo and symlink the skill:

```bash
git clone https://github.com/divyekant/delphi.git
ln -sf $(pwd)/delphi/skills/delphi ~/.claude/skills/delphi
```

## Usage

### Generate guided cases

After building software, invoke Delphi to generate test scenarios:

```
Generate guided cases for this project
Generate guided cases for the auth flow
Write test scenarios for the checkout module
```

Delphi will:
1. Analyze your code, docs, and running app
2. Discover testable surfaces (UI, API, CLI, background)
3. Present a surface map for your confirmation
4. Generate structured Markdown cases to `tests/guided-cases/`

### Execute guided cases

Run generated cases via browser automation or programmatic verification:

```
Execute guided cases
Run P0 guided cases
Execute UI cases for auth
```

Delphi executes each case step-by-step, captures evidence (screenshots, API responses), and generates a report to `tests/guided-cases/reports/`.

### Pipeline integration

Add to your `pipelines.yaml` (for [skill-conductor](https://github.com/divyekant/skill-conductor)):

```yaml
skills:
  delphi:
    source: external
    phase: verify
    type: phase

pipelines:
  feature:
    phases: [explore, plan, build, verify, review, finish]
    skills:
      verify:
        - verification-before-completion
        - delphi
```

## What's a Guided Case?

A structured Markdown file describing one testable scenario:

```markdown
# GC-001: Login with valid credentials

## Metadata
- **Type**: positive
- **Priority**: P0
- **Surface**: ui
- **Flow**: authentication

## Preconditions
- App running at http://localhost:3000
- Test user account exists

## Steps
1. Navigate to /login
   - **Expected**: Login page loads with email and password fields
2. Enter email and password
   - **Expected**: Fields accept input
3. Click "Sign In"
   - **Expected**: Redirect to /dashboard

## Success Criteria
- [ ] All expected outcomes match actual behavior
- [ ] No console errors
```

See `examples/` for complete reference cases.

## Docs

- [LLM Quickstart](docs/llm-quickstart.md) — paste into any LLM for full Delphi context
- [Vision & Scope](docs/VISION.md) — full project vision, principles, and format spec
- [Design](docs/plans/2026-02-27-delphi-design.md) — architecture decisions

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs welcome!

## License

[MIT](LICENSE)
