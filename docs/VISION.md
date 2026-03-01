# Delphi — Vision & Scope

*The Oracle that foresees all outcomes.*

## What Is Delphi?

Delphi is a skill for coding agents (Claude Code, Codex, Cursor, etc.) that generates comprehensive, structured test scenarios — called **guided cases** — after software is built. These guided cases serve two audiences simultaneously:

1. **Human testers** who walk through flows step-by-step
2. **AI agents** with browser or programmatic access who execute them automatically

Delphi has two modes:
- **Generate** — analyze available context (code, docs, specs, running app) and produce guided cases
- **Execute** — read generated cases and run them via browser automation or programmatic verification

## The Problem

Coding agents build software, run some unit/integration tests, and call it done. But the gap between "tests pass" and "this actually works for users" is enormous:

- Agents don't think about the 47 ways a user might misuse a form
- They don't test what happens when you click Back mid-flow
- They don't verify that error states render correctly
- They don't check that a flow works on mobile viewports
- They don't explore negative paths, edge cases, or race conditions from a user's perspective

Manual QA catches these — but manual QA is slow, inconsistent, and doesn't scale. Writing test plans is tedious. Nobody does it thoroughly.

## The Gap in the Market

Existing tools fall into three categories, none of which solve this:

| Category | Examples | What's Missing |
|----------|----------|----------------|
| **Code-level test generators** | Qodo Cover, EvoMaster, Keploy | Generate unit/API tests, not user-journey scenarios |
| **AI QA platforms** | Momentic, QA Wolf, Meticulous, mabl, Octomind | SaaS platforms with proprietary formats — not portable, not agent-native |
| **Browser automation frameworks** | Playwright Agents, Cypress cy.prompt() | Focus on execution, not comprehensive scenario discovery |

**The gap**: No tool takes "here's what I just built" and produces a complete set of human-readable, agent-executable test scenarios covering positive, negative, and edge cases — formatted for both manual walkthrough and automated execution — as a native part of the coding agent workflow.

Delphi fills this gap.

## Core Principles

### 1. Context-Hungry
Delphi consumes everything available: source code (routes, components, handlers, models), design docs, specs, READMEs, commit history, and optionally the running application. More context = better cases.

### 2. Dual-Audience Output
Every guided case must be clear enough for a junior tester to follow AND structured enough for an agent to execute without ambiguity. This is a hard constraint, not a nice-to-have.

### 3. Exhaustive by Default
Delphi generates ALL scenarios: happy paths, error paths, edge cases, boundary conditions, accessibility concerns, state transitions, concurrent usage, and permission variations. The default is comprehensive. Users can scope down, never up.

### 4. Agent-Native
Delphi is a skill, not a SaaS platform. It lives in your dotfiles. It runs inside your coding agent. No accounts, no dashboards, no vendor lock-in.

### 5. Format Simplicity
Structured Markdown. No proprietary formats. Version-controllable in Git. Readable in any editor. Parseable by any agent.

## What Is a Guided Case?

A guided case is a structured Markdown document describing one testable scenario. It contains:

```markdown
# GC-001: [Scenario Title]

## Metadata
- **Type**: positive | negative | edge | accessibility | performance
- **Priority**: P0 (critical) | P1 (important) | P2 (nice-to-have)
- **Surface**: ui | api | cli | background
- **Flow**: [which user flow this belongs to]
- **Tags**: [searchable tags]

## Preconditions
What must be true before this test starts.
- User is logged in as admin
- At least 3 items exist in the database
- Feature flag X is enabled

## Steps
1. Navigate to `/dashboard`
   - **Expected**: Dashboard loads with header showing username
2. Click "Create New" button in the top-right
   - **Expected**: Modal appears with empty form
3. Leave the "Name" field empty and click "Submit"
   - **Expected**: Validation error appears: "Name is required"
   - **Expected**: Form is NOT submitted
   - **Expected**: Focus moves to the Name field
4. ...

## Success Criteria
- [ ] All expected outcomes match actual behavior
- [ ] No console errors during the flow
- [ ] Page remains responsive throughout

## Failure Criteria
- Any step's expected outcome does not match
- Unhandled exception or crash
- UI becomes unresponsive

## Notes
Any additional context, known issues, or things to watch for.
```

### Case Organization

Cases are organized in a directory structure:

```
tests/guided-cases/
  index.md              # Summary table of all cases with status
  auth/
    gc-001-login-happy-path.md
    gc-002-login-invalid-password.md
    gc-003-login-rate-limiting.md
    ...
  dashboard/
    gc-010-dashboard-loads.md
    gc-011-dashboard-empty-state.md
    ...
```

The `index.md` file provides a table linking to all cases with their type, priority, surface, and execution status.

## Scope of Testable Surfaces

Delphi is NOT limited to UI testing. It covers any testable surface:

### UI / Browser
- Page navigation and routing
- Form interactions (validation, submission, error states)
- Component interactions (modals, dropdowns, tabs, accordions)
- Responsive behavior across viewports
- Accessibility (keyboard navigation, screen reader compatibility)
- Visual states (loading, empty, error, success)
- Authentication and authorization flows

### API
- Endpoint request/response validation
- Error codes and error message formats
- Authentication and authorization
- Rate limiting behavior
- Input validation and sanitization
- Edge cases (empty payloads, oversized payloads, malformed JSON)

### CLI
- Command execution and output format
- Flag and argument combinations
- Error messages and exit codes
- Help text accuracy
- Interactive prompts and confirmations

### Background / System
- Job execution and completion
- Webhook delivery and retry behavior
- Cron schedule accuracy
- Data migration correctness
- Cache invalidation

## Two Modes of Operation

### Mode 1: Generate

**Input**: Available project context (code, docs, specs, running app)

**Process**:
1. Discover testable surfaces by analyzing code structure
2. Map user flows and state transitions
3. For each flow, generate cases covering:
   - Happy path (positive)
   - Each validation rule (negative)
   - Boundary conditions (edge)
   - Permission variations (auth)
   - Error/failure states (negative)
   - Accessibility requirements (accessibility)
4. Write cases as structured Markdown files
5. Generate index with summary table

**Output**: `tests/guided-cases/` directory with all case files + index

### Mode 2: Execute

**Input**: Generated guided cases (the Markdown files)

**Process**:
1. Parse the case files
2. For each case, determine execution method:
   - **UI cases**: Use browser automation (Claude-in-Chrome MCP, Playwright MCP, or similar)
   - **API cases**: Use curl/fetch via shell commands
   - **CLI cases**: Use shell execution
   - **Background cases**: Use log inspection + database queries
3. Execute steps sequentially
4. Compare actual outcomes against expected outcomes
5. Capture evidence (screenshots for UI, response bodies for API, output for CLI)
6. Generate execution report

**Output**: Execution report with pass/fail per case, evidence artifacts, and failure details

## Workflow Integration

### As a Pipeline Skill (Verify Phase)
Wired into the conductor pipeline after the build phase. Automatically generates cases for whatever was just built. Can optionally execute them if browser/tool access is available.

```
explore → shape → plan → build → [delphi:generate] → [delphi:execute] → review → finish
```

### On-Demand
Invoked manually at any time:
- "Generate guided cases for the auth flow"
- "Generate guided cases for the whole app"
- "Execute all P0 guided cases"
- "Execute guided cases in the payments/ folder"

## Success Metrics

Delphi is successful when:
1. A coding agent can generate guided cases without human prompting beyond "generate cases"
2. A human tester can pick up any case file and execute it without asking questions
3. An AI agent can parse and execute any case file to completion
4. Cases cover scenarios that the original developer didn't think to test
5. The generate → execute loop catches real bugs that unit/integration tests miss

## What Delphi Is NOT

- **Not a test framework** — it doesn't replace Jest, Pytest, or Playwright. It generates scenarios, not test code.
- **Not a CI/CD tool** — it runs inside a coding agent session, not in a pipeline runner.
- **Not a bug tracker** — it finds issues but doesn't manage them.
- **Not a replacement for unit tests** — it complements them by covering the user-journey layer.

## Inspiration & Prior Art

- **Playwright Planner Agent**: Explores apps, produces Markdown test plans. Closest existing implementation to Delphi's generate mode.
- **OpenObserve's Council of Sub-Agents**: Eight Claude Code slash commands automating QA. Proved the model works.
- **BrowserStack Test Case Generator**: Parses requirements into structured test cases. Good format reference.
- **NVIDIA HEPH**: End-to-end pipeline from requirements to test specs including positive AND negative scenarios.
- **Manual Tests MCP Server**: YAML-based test case management via MCP. Format inspiration.

## Phased Delivery

### Phase 1: Generate (Core)
- Skill file with generate mode
- Structured Markdown output format
- Code analysis for surface discovery
- Comprehensive case generation (positive, negative, edge)
- Index generation

### Phase 2: Execute (Browser)
- UI case execution via Chrome MCP tools
- Screenshot capture as evidence
- Pass/fail reporting
- Execution report generation

### Phase 3: Execute (Non-UI)
- API case execution via shell commands
- CLI case execution
- Log/database inspection for background cases
- Unified reporting across all surfaces

### Phase 4: Intelligence
- Learn from execution results to improve case generation
- Detect redundant cases and prune
- Suggest cases based on code changes (diff-aware generation)
- Priority scoring based on code complexity and change frequency
