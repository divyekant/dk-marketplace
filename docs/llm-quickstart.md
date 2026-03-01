# Delphi — LLM Quickstart

> Paste this into any LLM (Claude, GPT, Codex, Gemini, etc.) to give it full context on Delphi. This is a standalone document — no other files needed.

---

## What is Delphi?

Delphi is a skill that instructs coding agents to generate and execute comprehensive test scenarios called **guided cases**. After software is built, Delphi analyzes the codebase and produces structured Markdown files describing every testable scenario — positive, negative, edge, accessibility, and security — that a human tester can follow step-by-step or an AI agent can execute automatically.

## Two Modes

**Generate** — Analyze code/docs/running app → produce guided cases
**Execute** — Read guided cases → run them via browser automation or shell commands

## How to Use

Tell your coding agent:
- `"Generate guided cases for this project"` — generates test scenarios
- `"Execute guided cases"` — runs them
- `"Generate and execute guided cases"` — both

## What Delphi Produces

A `tests/guided-cases/` directory containing individual Markdown files, one per scenario:

```
tests/guided-cases/
  index.md                              # Summary table of all cases
  authentication/
    gc-001-login-happy-path.md
    gc-002-login-invalid-password.md
    gc-003-login-rate-limiting.md
  dashboard/
    gc-010-dashboard-loads.md
    gc-011-dashboard-empty-state.md
```

## Guided Case Format

Every case follows this template:

```markdown
# GC-001: Login with valid credentials

## Metadata
- **Type**: positive | negative | edge | accessibility | performance | security
- **Priority**: P0 (critical) | P1 (important) | P2 (nice-to-have)
- **Surface**: ui | api | cli | background
- **Flow**: authentication
- **Tags**: login, auth, happy-path
- **Generated**: 2026-02-27
- **Last Executed**: never

## Preconditions
- Application is running at http://localhost:3000
- A test user account exists

## Steps
1. Navigate to http://localhost:3000/login
   - **Target**: Login page URL
   - **Expected**: Login page loads with email and password fields visible
2. Enter email test@example.com in the email field
   - **Target**: Email input field
   - **Input**: test@example.com
   - **Expected**: Email field shows entered text
3. Enter password and click Sign In
   - **Target**: Password field, then Sign In button
   - **Input**: TestPass123!
   - **Expected**: Redirect to /dashboard within 3 seconds

## Success Criteria
- [ ] All expected outcomes match actual behavior
- [ ] No console errors during the flow
- [ ] Authenticated state persists on page refresh

## Failure Criteria
- Any expected outcome does not match
- Page crashes or becomes unresponsive
- Login succeeds but redirect fails

## Notes
- If app uses OAuth/SSO, adapt this case accordingly
```

## Generate Mode Process

When generating, the agent follows these steps in order:

### 1. Context Gathering
Scan the project for:
- **Routes/pages**: `**/pages/**`, `**/app/**/page.*`, `**/routes/**`
- **API handlers**: `**/api/**`, `**/controllers/**`, `**/handlers/**`
- **CLI entry points**: `**/bin/**`, `**/cli/**`, `**/commands/**`
- **Docs**: `README.md`, `CLAUDE.md`, `docs/**/*.md`, OpenAPI specs
- **Existing tests**: `**/*.test.*`, `**/*.spec.*`
- **Git history**: recent commits and changed files

### 2. Surface Discovery
Group all discovered testable surfaces into logical flows:
- **UI**: every route/page
- **API**: every endpoint with method
- **CLI**: every command/subcommand
- **Background**: cron jobs, webhooks, queue workers

Present the surface map to the user and wait for confirmation before generating.

### 3. Case Generation
For each flow, generate cases across this coverage matrix:

| Dimension | Priority |
|-----------|----------|
| Happy path (end-to-end success) | P0 |
| Auth/permissions (each role) | P0 |
| Error states (500, timeout, network failure) | P0 |
| Security (XSS, CSRF, injection, auth bypass) | P0 |
| Input validation (per field, per rule) | P1 |
| Boundary values (empty, min, max) | P1 |
| State transitions (back, refresh, navigate away) | P1 |
| Empty/first-use states | P1 |
| Concurrency (double-click, duplicate submit) | P1 |
| Accessibility (keyboard nav, focus, screen reader) | P2 |

Additional dimensions for **API**: valid request, missing fields, invalid types, auth variations.
Additional dimensions for **CLI**: valid usage, missing args, invalid flags, help text.

### 4. Output
- Write each case as a `.md` file in `tests/guided-cases/[flow-name]/`
- Generate `index.md` with a table linking all cases (ID, title, type, priority, surface, flow, status)

## Execute Mode Process

### 1. Load Cases
Read `tests/guided-cases/index.md`, apply user filters (by priority, type, surface, flow, or ID range). Default: P0 only.

### 2. Route to Execution Method

| Surface | Method |
|---------|--------|
| `ui` | Browser automation (Chrome MCP, Playwright) |
| `api` | `curl` via shell |
| `cli` | Direct shell execution |
| `background` | Log inspection, DB queries, health checks |

### 3. Execute Step-by-Step
For each case: verify preconditions → execute each step → capture evidence (screenshots/responses) → compare against expected outcomes → record pass/fail.

On step failure: stop the case, record details, continue to next case.

### 4. Report
Write report to `tests/guided-cases/reports/YYYY-MM-DD-HH-MM-report.md` with pass/fail/skip counts, failure details with evidence, and update the index.

## Priority Definitions

- **P0**: Must work. Happy paths, auth, security, critical errors. Failure = broken software.
- **P1**: Should work. Validation, boundaries, state transitions. Failure = rough edges.
- **P2**: Nice to have. Accessibility, cosmetic, rare edges. Failure = affects some users in some situations.

## Installation (Claude Code)

```bash
git clone https://github.com/divyekant/delphi.git
ln -sf $(pwd)/delphi/skills/delphi ~/.claude/skills/delphi
```

## For Other Agents

Delphi is a Markdown instruction file. To use with any agent:
1. Read the content of `skills/delphi/skill.md`
2. Include it in the agent's system prompt or context
3. The agent will follow the instructions when asked to generate or execute guided cases

## Key Design Decisions

- **Structured Markdown** — no proprietary formats, Git-friendly, readable everywhere
- **Single skill file** — no external dependencies, no MCP server, no runtime
- **Dual audience** — cases work for human testers AND AI agents
- **Exhaustive by default** — generates all scenarios, users scope down
- **Agent-native** — lives in dotfiles, runs inside coding agents

## Links

- GitHub: https://github.com/divyekant/delphi
- Full vision: `docs/VISION.md` in the repo
- Design doc: `docs/plans/2026-02-27-delphi-design.md` in the repo
