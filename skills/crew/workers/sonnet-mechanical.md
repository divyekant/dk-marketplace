# Worker: Sonnet — Mechanical / Low-Level

**Spawn:** Agent tool, `model: "sonnet"` (general-purpose subagent).

## Owns

Test suites and fixtures, renames and codemods, boilerplate and
scaffolding, rote migrations, doc updates, lint/format sweeps, dependency
chores, repetitive multi-file edits with a clear pattern.

## Does not own

Anything requiring a design decision. If a "mechanical" task turns out to
need judgment (ambiguous naming, unclear pattern, behavioral choice), the
brief must say: stop and report, don't decide.

## Brief additions

On top of the standard brief template, include:

- An exact worked example of the pattern to apply (before/after of one
  instance), not a description of it.
- The complete file list when the sweep is enumerable — don't make the
  worker discover scope.
- For test-writing: which behaviors to cover, the test framework, and one
  existing test file to mirror for conventions.

## Review focus

Sonnet is fast and literal. Check:

- The pattern was applied everywhere it should be — grep for stragglers
  rather than trusting the worker's list.
- No over-literal application where the pattern didn't actually fit.
- Tests assert behavior, not implementation details.

## Why Sonnet

Cheap, fast, and reliable on well-specified low-ambiguity work — exactly
the profile of these tasks. Escalate to Opus only if two attempts produce
pattern misapplication.
