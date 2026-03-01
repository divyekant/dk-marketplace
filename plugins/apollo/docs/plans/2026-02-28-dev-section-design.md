# Design: `dev:` Section for Apollo Config

**Date:** 2026-02-28
**Status:** Design approved

## Problem

Agents start every session without knowing how to run the project locally — is it Docker or bare process? Which ports are in use? What's the start command? This leads to guessing, port conflicts, and running wrong commands (e.g., `npm start` on a containerized project).

## Solution

Add an optional `dev:` section to Apollo's config schema that captures local development environment details: runtime, services/ports, and commands. Agents get this context injected into their instructions on every session.

## Schema

```yaml
dev:
  runtime: docker-compose    # docker-compose | docker | local | podman
  services:                  # optional — map of service name to details
    api:
      port: 3001
      description: Backend API
    frontend:
      port: 5173
      description: Vite dev server
    redis:
      port: 6379
  commands:                  # optional — map of command name to shell command
    start: "docker compose up -d"
    stop: "docker compose down"
    build: "docker compose build"
    test: "docker compose exec api npm test"
    logs: "docker compose logs -f"
```

### Minimal (non-Docker) example

```yaml
dev:
  runtime: local
  commands:
    start: "npm start"
    test: "npm test"
    build: "npm run build"
```

### Field definitions

| Field | Required | Description |
|-------|----------|-------------|
| `runtime` | Yes (when `dev:` present) | How the project runs locally |
| `services` | No | Map of service name → `{ port, description? }` |
| `services.<name>.port` | Yes (per service) | Port number the service listens on |
| `services.<name>.description` | No | Human-readable description |
| `commands` | No | Map of command name → shell command string |

Common command keys: `start`, `stop`, `build`, `test`, `logs`. Users can add any custom key.

## Config Inheritance

Follows Apollo's existing three-tier resolution: `defaults.yaml` → `templates/<name>.yaml` → `.apollo.yaml`.

- `runtime` overrides at each tier (scalar)
- `services` merges by key — project-level services add to or override template-level ones
- `commands` merges by key — same behavior

A user who always uses Docker Compose sets `dev.runtime: docker-compose` in defaults.yaml and only overrides services/commands per project.

## CLAUDE.md Injection

When `dev:` is present, Apollo adds to the managed section:

```markdown
<!-- APOLLO:START -->
## Project Conventions (managed by Apollo)
- ...existing rules...
- Dev runtime: docker-compose
- Services: api (:3001), frontend (:5173), redis (:6379)
- Start: `docker compose up -d` | Stop: `docker compose down`
- Test: `docker compose exec api npm test`
<!-- APOLLO:END -->
```

Agents get the critical info inline without parsing `.apollo.yaml`.

## Onboarding Integration

During `/apollo config` or `/apollo init`, after the `stack:` questions:

```
Apollo: Does this project run locally or in containers?
        1. Local (bare process)  2. Docker Compose  3. Docker  4. Podman  5. Skip for now

Apollo: What services does it run? (name:port, comma-separated, or "skip")

Apollo: Start command?

Apollo: Stop command?

Apollo: Test command? (or "skip")

Apollo: Any other commands? (name: command, or "done")
```

The section is entirely optional — users can skip during onboarding and add later via `"add to Apollo: dev runtime is docker-compose, api on 3001"`.

## `/apollo check` Integration

When `dev:` is present, `apollo check` validates:

- No duplicate ports across services
- If runtime is `docker-compose`, warn if no `docker-compose.yaml` (or `compose.yaml`) exists in repo

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Section name | `dev:` | Short, clear, matches "local dev environment" |
| Structure | Flat (Approach A) | Matches Apollo's existing pattern (stack:, git:, testing:). Simple to scan. |
| Services in config vs compose file | Explicit in config | Agent gets info without parsing another file. Single source of truth. |
| Optional section | Yes | Not all projects have runtimes (e.g., Apollo itself is just YAML). |
| Commands as free-form map | Yes | Common keys (start/stop/test) are conventional, not enforced. Users can add any key. |
