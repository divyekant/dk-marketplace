# Apollo: Agent-Agnostic Project Lifecycle Manager

**Date:** 2026-02-27
**Status:** Design approved

## Problem

Every new session with a coding agent, users repeat the same instructions: where to create projects, what stack to use, when to commit, how to structure repos, which workflows to follow. This compounds across projects and agents.

## Solution

Apollo is an agent-agnostic project lifecycle management system. It encodes user preferences into a universal config format (YAML) and enforces them by injecting rules into agent instruction files (CLAUDE.md, .cursorrules, etc.).

**Core principle:** The config format is the product. Skills/plugins are adapters that read it.

---

## End-to-End Scope

### Config System

**Location:** `~/.apollo/`

```
~/.apollo/
  defaults.yaml              # Global preferences
  templates/
    oss.yaml                 # Open source projects
    personal.yaml            # Side projects / learning
    work.yaml                # Corporate / work projects
    <user-created>.yaml      # Custom templates
```

**Per-project override:** `.apollo.yaml` in any repo. User chooses during init whether to gitignore or commit it.

**Resolution order:** `defaults.yaml` -> `templates/<type>.yaml` -> `.apollo.yaml`

**Config schema:**

```yaml
# Where to create projects
projects_dir: ~/Projects

# Dev preferences
stack:
  language: typescript
  package_manager: bun
  test_framework: vitest

# Git discipline
git:
  commit_style: conventional    # conventional | freeform
  auto_commit: false            # never auto-commit without asking
  branch_strategy: feature      # feature | trunk

# Coding style
code:
  style: concise
  comments: minimal             # minimal | thorough
  error_handling: boundaries    # boundaries | defensive

# Documentation
docs:
  readme: true
  changelog: true
  update_trigger: feature       # feature | release | manual

# OSS structure (when applicable)
oss:
  license: MIT
  contributing: true
  code_of_conduct: true
  issue_templates: true

# Testing
testing:
  code:
    approach: tdd               # tdd | test-after | none
    framework: vitest           # vitest | jest | pytest | go-test | etc.
    coverage_target: null       # e.g. 80 — null means no target
    run_before_commit: true     # enforce tests pass before committing
  product:
    tool: delphi                # delphi | manual | none
    surfaces: [ui, api, cli]    # which surfaces to test (ui | api | cli | background)
    trigger: feature            # feature | release | manual — when to generate test cases

# Skills / workflow
workflow:
  design_before_code: true
  tdd: true
  review_before_merge: true

# Release & versioning
release:
  versioning: semver            # semver | calver | manual
  changelog: auto               # auto | manual | none
  tag_on_release: true
  publish: false                # npm publish, pypi, etc.

# Local development environment (optional)
dev:
  runtime: docker-compose       # local | docker-compose | docker | podman
  services:
    api:
      port: 3001
      description: Backend API
  commands:
    start: "docker compose up -d"
    stop: "docker compose down"
    test: "docker compose exec api npm test"

# Secrets & env handling
secrets:
  env_pattern: ".env*"
  extra_ignores: []
  warn_on_commit: true
```

**Template files** inherit from defaults and override specific keys:

```yaml
# templates/oss.yaml
extends: defaults
oss:
  license: MIT
  contributing: true
  code_of_conduct: true
  issue_templates: true
docs:
  readme: true
  changelog: true
  update_trigger: feature
```

### Commands

| Command | When | Conversational? | Purpose |
|---------|------|-----------------|---------|
| `/apollo config` | First run / edit prefs | Yes | Onboarding Q&A, builds `defaults.yaml` |
| `/apollo init` | New project | Yes | Scaffolds project from template |
| `/apollo check` | Session start | No | Validates repo state, surfaces gaps |
| `/apollo` | Anytime | Yes | Context-aware "what should I do next?" |
| `/apollo release` | Ready to release | Yes | Guided bump + changelog + tag + publish |
| "add to Apollo: ..." | Mid-session | Yes | Natural language config update |

### Rule Adherence

Apollo writes a managed section into the project's agent instruction file:

```markdown
<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
- Language: TypeScript, package manager: bun
- Commits: conventional style, never auto-commit
- Testing: TDD with vitest, run tests before every commit
- Product testing: use Delphi for UI/API/CLI surfaces on new features
- Design before code: always invoke brainstorming first
- Docs: update README on every feature addition
<!-- APOLLO:END -->
```

**Agent file targets:**
- Claude Code: `CLAUDE.md`
- Cursor: `.cursorrules`
- Codex: `CODEX.md`
- Windsurf: `.windsurfrules`
- Others: extensible via config

Markers let Apollo update its section without touching user-written content.

### Versioning

**Projects with manifests** (`package.json`, `pyproject.toml`, `Cargo.toml`):
- Apollo reads/writes version from the manifest directly

**Projects without manifests:**
- Apollo tracks version internally in `.apollo.yaml`:
  ```yaml
  version: 0.3.0
  ```

**`/apollo release` flow:**
1. Detect current version (manifest or internal)
2. Analyze commits since last tag to suggest bump type
3. Ask: patch, minor, or major?
4. Update version in manifest or `.apollo.yaml`
5. Generate/update CHANGELOG.md
6. Create git tag
7. Ask about publish (npm, pypi, etc.) if applicable

### Memories Enrichment (Optional)

When Memories MCP is available, Apollo stores and retrieves project-level learnings:
- Decisions made during development
- Patterns discovered
- Release history and context

**YAML = "what I want"** (preferences, rules, templates)
**Memories = "what I've learned"** (project history, decisions, patterns)

Apollo queries Memories at `/apollo check` to surface relevant context. Zero degradation without Memories.

### Conversational Onboarding

`/apollo config` walks users through preferences via Q&A instead of manual YAML editing:

```
Apollo: Where do you keep your projects?
User:   ~/Projects

Apollo: Go-to language?
User:   TypeScript

Apollo: Package manager?
        1. npm  2. yarn  3. pnpm  4. bun
User:   bun

Apollo: Commit style?
        1. Conventional (feat:, fix:, etc.)  2. Freeform
User:   1

... (each config section)

Apollo: Saved to ~/.apollo/defaults.yaml
```

Same conversational pattern for `/apollo init`.

---

## Phased Implementation

### Phase 1: Foundation

**Goal:** Config format exists, onboarding works, project scaffolds.

**Deliverables:**
- [ ] Project repo setup (apollo/ with skill structure)
- [ ] Config schema definition (defaults.yaml, template schema, .apollo.yaml)
- [ ] Three-tier config resolution logic (defaults -> template -> project)
- [ ] `/apollo config` — conversational onboarding, generates `defaults.yaml`
- [ ] Example configs: `defaults.example.yaml`, 3 templates (oss, personal, work)
- [ ] SKILL.md with skill description and sub-command routing

**Exit criteria:** User can run `/apollo config`, answer questions, and get a valid `defaults.yaml` written to `~/.apollo/`.

### Phase 2: Project Creation

**Goal:** `/apollo init` creates fully scaffolded projects.

**Deliverables:**
- [ ] `/apollo init` — conversational project creation
- [ ] Template-based directory scaffolding
- [ ] Git init, .gitignore generation (including secrets patterns)
- [ ] CLAUDE.md instruction injection (managed section with markers)
- [ ] Ask whether to gitignore or commit `.apollo.yaml`
- [ ] OSS scaffolding (LICENSE, CONTRIBUTING, CODE_OF_CONDUCT) when template applies
- [ ] `.apollo.yaml` creation with project overrides

**Exit criteria:** User can run `/apollo init`, pick a template, answer questions, and get a fully scaffolded project with CLAUDE.md populated from their Apollo config.

### Phase 3: Session Management

**Goal:** Apollo is useful during ongoing development, not just at project start.

**Deliverables:**
- [ ] `/apollo check` — reads config, validates repo state, surfaces gaps (missing tests, stale docs, uncommitted changes)
- [ ] `/apollo` (no args) — context-aware guidance (detects lifecycle position, suggests next action)
- [ ] "add to Apollo: ..." — mid-session config updates via natural language
- [ ] Re-inject CLAUDE.md managed section when config changes
- [ ] Detect and warn about config drift (CLAUDE.md out of sync with config)

**Exit criteria:** User can run `/apollo check` in an existing project and get actionable feedback. Can update config mid-session and see CLAUDE.md update.

### Phase 4: Versioning & Release

**Goal:** First-class versioning for all projects, guided release workflow.

**Deliverables:**
- [ ] Version detection: manifest-based or internal (.apollo.yaml)
- [ ] `/apollo release` — guided flow (bump, changelog, tag, publish)
- [ ] Changelog generation from conventional commits
- [ ] Git tag creation
- [ ] Internal versioning for projects without manifests
- [ ] Publish step (optional, config-driven)

**Exit criteria:** User can run `/apollo release` on any project (with or without package.json) and get a versioned, tagged, changelogged release.

### Phase 5: Enrichment & Polish

**Goal:** Optional Memories layer, adapter interface, edge cases.

**Deliverables:**
- [ ] Memories MCP integration (query at check, store decisions/patterns)
- [ ] Document the adapter interface (how to write adapters for Cursor, Codex, etc.)
- [ ] User-created template support (guide for creating custom templates)
- [ ] Edge case handling (corrupt config, missing fields, conflicting overrides)
- [ ] First-run detection and auto-trigger of `/apollo config`

**Exit criteria:** Memories enrichment works when MCP is available, degrades gracefully without it. Adapter interface is documented for future agent support.

---

## Project Structure

```
~/Projects/apollo/
  skills/
    apollo/
      SKILL.md                # Claude Code adapter skill
  config/
    defaults.example.yaml     # Example for users to copy/reference
    templates/
      oss.yaml
      personal.yaml
      work.yaml
  docs/
    plans/
      2026-02-27-apollo-design.md   # This document
  README.md
  LICENSE
  .apollo.yaml                # Apollo manages itself with Apollo
```

**Installation:**
```bash
# Symlink skill into Claude Code
ln -s ~/Projects/apollo/skills/apollo ~/.claude/skills/apollo

# First run — Apollo walks you through setup
# Just invoke /apollo config
```

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Name | Apollo | Greek god of order, harmony, discipline. `/apollo` is clean and memorable. |
| Config location | `~/.apollo/` | Agent-agnostic. Not nested under `.claude/` so any agent can find it. |
| Enforcement | CLAUDE.md injection | No enforcement engine needed. The agent's own instruction system IS the enforcement. |
| Config format | YAML | Human-readable, widely supported, every agent can parse it. |
| Versioning | First-class, always-on | Internal tracking for projects without manifests. Every project gets a version. |
| Memories | Optional enrichment | YAML = source of truth. Memories adds context. Zero degradation without it. |
| Scope | Agent-agnostic, universal | Designed for all agents from day one. Claude Code adapter is first, others follow. |
| Per-project tracking | User's choice | `.apollo.yaml` gitignored or committed — asked during init. |
| Onboarding | Conversational | Q&A builds config. No manual YAML editing required. |
| Dev section | Optional, flat structure | Not all projects have runtimes. Flat matches existing config pattern. |
