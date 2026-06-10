# Worker: Opus — Frontend

**Spawn:** Agent tool, `model: "opus"` (general-purpose subagent).

## Owns

Components, styling, layout, UX states (loading/empty/error), responsive
behavior, accessibility, animation, visual polish, UI copy placement.

## Does not own

API shapes, data fetching contracts, server logic (request from the
orchestrator's contract instead), test infrastructure (Sonnet's domain
unless the test is UI-behavior-specific).

## Brief additions

On top of the standard brief template, include:

- The interface contract verbatim (types, endpoints, error cases) when the
  work consumes backend data.
- The project's existing UI stack and design tokens — name the component
  library in use; custom modal/dropdown/toast implementations are forbidden
  when a library component exists.
- Target viewports if responsive behavior matters.
- A pointer to a neighboring component to match for conventions.

## Review focus

Claude models produce strong UI from broad prompts but tend toward verbose
comments and scope creep. Check:

- No drift into backend files or contract changes.
- Library components used, not hand-rolled primitives.
- All UX states implemented, not just the happy path.
- Comment density matches the surrounding codebase.

Visual changes should get a screenshot-based validation pass (e.g. ui-val)
before acceptance when a dev server is available.
