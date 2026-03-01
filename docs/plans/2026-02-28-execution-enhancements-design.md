# Delphi — Execution Enhancements Design

**Date**: 2026-02-28
**Status**: Draft
**Ref**: [Original Design](./2026-02-27-delphi-design.md)

## Context

Three enhancements to Delphi's execution mode, informed by real-world testing gaps:
1. Test data strategy
2. Precondition classification
3. Phase-aware model selection

---

## 1. Test Data Strategy

### Problem

Delphi generates cases assuming ideal data exists. In real environments, data is often absent — especially for external services (Stripe, Salesforce, etc.). Reactive skip-if-missing causes large percentages of cases to go unexecuted.

### Decision: Two-path approach, no infrastructure layer

Delphi is a test intelligence tool, not a test infrastructure tool. It does not provision data, manage mock servers, or maintain fixture systems.

**Path A — Crafted/boundary inputs (Delphi generates inline)**

For validation, edge cases, and negative testing, the generate phase emits specific test values directly in the case steps. No external data needed.

Examples:
- "Enter `-50` in amount field → verify error message"
- "Submit form with empty required fields → verify validation"
- "Enter `<script>alert(1)</script>` in name field → verify sanitization"
- "Enter string exceeding 500 char limit → verify truncation"

This is where Delphi's exhaustive-by-default philosophy delivers the most value. A human tester forgets boundary values. Delphi generates them systematically.

**Path B — Real environment data (developer provides or case skips)**

For integration verification and happy-path flows that depend on existing data (user accounts, products, transaction history), cases are tagged with a data dependency profile. If data isn't available, the case skips with a clear gap report.

The gap report itself is valuable — it tells the team exactly what data is needed to achieve full coverage.

### What Delphi does NOT do

- Create data in external/third-party systems
- Manage cleanup/teardown
- Run mock servers or fixture systems
- Handle auth for data creation APIs

---

## 2. Precondition Classification

### Current state

Preconditions are a flat list. The execution agent checks each one and either sets it up or skips the case. No distinction between types.

### Enhancement: Split into two categories

**Environment preconditions** — Things the agent cannot create:
- Application is running and reachable
- API endpoint is available
- CLI tool is installed
- External service is accessible
- User has required permissions/role

Action on failure: **skip** with reason. These represent genuine environment gaps.

**Data preconditions** — Things the agent can attempt to create or generate inline:
- User account exists → create via API/UI if possible
- Product in cart → add via UI flow
- Specific input value needed → generated inline in the case (Path A)

Action on failure: **attempt setup**, then skip only if setup fails.

### Case metadata format

```markdown
## Preconditions

### Environment
- [ ] Application running at http://localhost:3000
- [ ] Stripe test mode API key configured

### Data
- [ ] User account exists (source: local-db, setup: POST /api/users)
- [ ] Product catalog has ≥1 item (source: local-db, setup: seed or UI)
- [ ] Stripe customer exists (source: external/stripe, setup: dev-provided)
```

The `source` tag classifies where data lives:
- `local-db` — app's own database, agent can likely create
- `external/<service>` — third-party service, dev must provide or case skips
- `inline` — value is crafted in the case step itself, no dependency

---

## 3. Phase-Aware Model Selection

### Problem

Delphi currently has no model selection logic. All phases inherit whatever model the user invoked. But the work profile differs dramatically across phases — generation is creative/analytical, execution is procedural/mechanical, and execution spawns multiple subagents (cost multiplier).

### Decision: Sensible defaults, user-overridable

| Phase | Default Model | Reasoning |
|-------|--------------|-----------|
| Generate | opus | Deep analysis, creative edge case discovery, architectural reasoning |
| Execute (orchestrator) | session model | Loads cases, classifies flows, merges reports — moderate reasoning |
| Execute (subagents) | sonnet | Procedural step-following, click-verify-record. Volume is high. |

**User override**: Explicit instruction overrides defaults.
- "generate with sonnet" → uses sonnet for generation
- "execute with opus" → uses opus for subagents

**Implementation**: The `model` parameter on Agent tool calls in the parallel dispatch section. The orchestrator passes the selected model when spawning subagents.

### Cost profile

Generate runs once per invocation. Execute spawns N subagents where N = number of non-UI flows. Using a cheaper model for subagents is the highest-leverage cost optimization.

---

## Summary of Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| Test data | Two-path: inline crafted values + tagged skip-with-gap-report | Keeps Delphi as test intelligence, not infrastructure |
| Preconditions | Split: environment (skip) vs data (attempt setup) | Clearer failure taxonomy, reduces unnecessary skips |
| Model selection | Phase-aware defaults (opus/sonnet), user-overridable | Matches reasoning demand to cost, optimizes at the volume point |
