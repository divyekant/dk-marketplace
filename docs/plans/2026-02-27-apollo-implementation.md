# Apollo Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build Apollo — an agent-agnostic project lifecycle manager with YAML config, conversational onboarding, CLAUDE.md injection, versioning, and optional Memories enrichment.

**Architecture:** Single Claude Code skill (SKILL.md) reads YAML config from `~/.apollo/`, routes sub-commands (`/apollo config`, `/apollo init`, `/apollo check`, `/apollo release`), and injects managed rules into agent instruction files. Config is the universal product; the skill is just the first adapter.

**Tech Stack:** YAML config format, Claude Code SKILL.md, Bash for scaffolding commands, Memories MCP (optional enrichment).

---

## Phase 1: Foundation

### Task 1: Project scaffolding & .gitignore

**Files:**
- Create: `~/Projects/apollo/.gitignore`
- Create: `~/Projects/apollo/LICENSE`

**Step 1: Create .gitignore**

```gitignore
# Apollo user config (never commit personal preferences)
.apollo.yaml

# OS
.DS_Store
Thumbs.db

# Editor
.idea/
.vscode/
*.swp
```

**Step 2: Create MIT LICENSE**

Standard MIT license with year 2026.

**Step 3: Commit**

```bash
git add .gitignore LICENSE
git commit -m "chore: add .gitignore and MIT license"
```

---

### Task 2: Config schema — defaults.example.yaml

**Files:**
- Create: `config/defaults.example.yaml`

**Step 1: Write the full documented example config**

This is the reference document for the entire config schema. Every key must have an inline comment explaining its purpose and valid values.

```yaml
# Apollo Configuration — Global Defaults
# Copy to ~/.apollo/defaults.yaml and customize
# Docs: https://github.com/<owner>/apollo

# Where new projects are created
projects_dir: ~/Projects

# Dev preferences
stack:
  language: typescript          # Your primary language
  package_manager: bun          # npm | yarn | pnpm | bun | pip | cargo | go
  test_framework: vitest        # vitest | jest | pytest | go-test | cargo-test | etc.

# Git discipline
git:
  commit_style: conventional    # conventional | freeform
  auto_commit: false            # If true, agent may commit without asking
  branch_strategy: feature      # feature | trunk

# Coding style
code:
  style: concise                # concise | verbose
  comments: minimal             # minimal | thorough
  error_handling: boundaries    # boundaries (validate at edges) | defensive (validate everywhere)

# Documentation
docs:
  readme: true                  # Generate/maintain README
  changelog: true               # Generate/maintain CHANGELOG.md
  update_trigger: feature       # feature | release | manual — when to update docs

# Testing
testing:
  code:
    approach: tdd               # tdd | test-after | none
    framework: vitest           # Should match stack.test_framework
    coverage_target: null       # Number (e.g. 80) or null for no target
    run_before_commit: true     # Enforce tests pass before committing
  product:
    tool: delphi                # delphi | manual | none
    surfaces: [ui, api, cli]    # ui | api | cli | background
    trigger: feature            # feature | release | manual

# OSS structure (applied when template includes OSS)
oss:
  license: MIT                  # MIT | Apache-2.0 | GPL-3.0 | none
  contributing: true            # Generate CONTRIBUTING.md
  code_of_conduct: true         # Generate CODE_OF_CONDUCT.md
  issue_templates: true         # Generate .github/ISSUE_TEMPLATE/

# Skills / workflow preferences
workflow:
  design_before_code: true      # Always run brainstorming/design phase first
  tdd: true                     # Use TDD approach for implementation
  review_before_merge: true     # Code review before merging

# Release & versioning
release:
  versioning: semver            # semver | calver | manual
  changelog: auto               # auto (from commits) | manual | none
  tag_on_release: true          # Create git tags (v1.2.3)
  publish: false                # Auto-publish to registry (npm, pypi, etc.)

# Secrets & env handling
secrets:
  env_pattern: ".env*"          # Glob pattern for env files to gitignore
  extra_ignores: []             # Additional patterns to always gitignore
  warn_on_commit: true          # Warn if secrets might be staged
```

**Step 2: Commit**

```bash
git add config/defaults.example.yaml
git commit -m "feat: add defaults.example.yaml with full config schema"
```

---

### Task 3: Template configs

**Files:**
- Create: `config/templates/oss.yaml`
- Create: `config/templates/personal.yaml`
- Create: `config/templates/work.yaml`

**Step 1: Write oss.yaml**

```yaml
# Apollo Template: Open Source Project
# Extends defaults with OSS-specific settings
extends: defaults

docs:
  readme: true
  changelog: true
  update_trigger: feature

oss:
  license: MIT
  contributing: true
  code_of_conduct: true
  issue_templates: true

release:
  versioning: semver
  changelog: auto
  tag_on_release: true
```

**Step 2: Write personal.yaml**

```yaml
# Apollo Template: Personal / Side Project
# Lighter-weight — fewer docs requirements, flexible workflow
extends: defaults

docs:
  readme: true
  changelog: false
  update_trigger: manual

oss:
  license: none
  contributing: false
  code_of_conduct: false
  issue_templates: false

workflow:
  design_before_code: true
  tdd: true
  review_before_merge: false

release:
  versioning: semver
  changelog: none
  tag_on_release: false
```

**Step 3: Write work.yaml**

```yaml
# Apollo Template: Work / Corporate Project
# Stricter discipline, thorough docs, review-gated
extends: defaults

code:
  comments: thorough
  error_handling: defensive

docs:
  readme: true
  changelog: true
  update_trigger: feature

workflow:
  design_before_code: true
  tdd: true
  review_before_merge: true

testing:
  code:
    run_before_commit: true
  product:
    tool: delphi
    surfaces: [ui, api, cli, background]
    trigger: feature

release:
  versioning: semver
  changelog: auto
  tag_on_release: true
```

**Step 4: Commit**

```bash
git add config/templates/
git commit -m "feat: add oss, personal, and work templates"
```

---

### Task 4: SKILL.md — Frontmatter & sub-command router

**Files:**
- Create: `skills/apollo/SKILL.md`

This is the core skill file. We build it incrementally across tasks 4-12. Start with the skeleton: frontmatter, overview, sub-command routing, and the config resolution logic.

**Step 1: Write SKILL.md skeleton**

The SKILL.md must include:
- Frontmatter with `name: apollo` and trigger-only description
- Overview section explaining what Apollo is
- Sub-command routing table (how to detect which command the user invoked)
- Config resolution logic (three-tier: defaults -> template -> project)
- Placeholders for each sub-command section (filled in subsequent tasks)

Key skill content:
- **Name:** `apollo`
- **Description:** `Use when starting a new project, beginning a development session, managing releases, or when the user says 'apollo', '/apollo', or 'add to Apollo'. Also triggers on 'set up project', 'new project', 'project preferences', or 'release'.`
- **Sub-command detection:** Check the user's argument — `init`, `config`, `check`, `release`, or bare
- **Config resolution:** Read `~/.apollo/defaults.yaml`, then template if `extends` is set, then `.apollo.yaml` in current directory. Merge in order, later values override.

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add SKILL.md skeleton with routing and config resolution"
```

---

### Task 5: SKILL.md — `/apollo config` (conversational onboarding)

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Write the `/apollo config` section**

This section defines the conversational onboarding flow. Key behaviors:
- If `~/.apollo/` doesn't exist, create it with `defaults.yaml` and `templates/`
- Walk through each config category one question at a time using AskUserQuestion
- Question order: projects_dir -> stack (language, pkg manager, test framework) -> git (commit style, auto commit, branch strategy) -> code style -> docs -> testing -> workflow -> release -> secrets
- Use multiple choice where possible
- After all questions, write the assembled config to `~/.apollo/defaults.yaml`
- Copy template files from the Apollo repo's `config/templates/` to `~/.apollo/templates/`
- Confirm: "Saved to ~/.apollo/defaults.yaml. Run /apollo config anytime to update."

Also handle: `/apollo config` when config already exists — show current values and ask what to change.

**Step 2: Verify by invoking `/apollo config`**

Run `/apollo config` in a test session. Verify:
- Questions are asked one at a time
- Multiple choice options are presented
- `~/.apollo/defaults.yaml` is written correctly
- Templates are copied

**Step 3: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add /apollo config conversational onboarding"
```

---

### Task 6: Install & verify Phase 1

**Step 1: Symlink the skill**

```bash
ln -sf ~/Projects/apollo/skills/apollo ~/.claude/skills/apollo
```

**Step 2: Test `/apollo config` end-to-end**

Open a new Claude Code session and run `/apollo config`. Walk through the full onboarding. Verify:
- `~/.apollo/defaults.yaml` exists with correct values
- `~/.apollo/templates/` contains oss.yaml, personal.yaml, work.yaml
- Re-running `/apollo config` shows existing values

**Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: phase 1 verification fixes"
```

---

## Phase 2: Project Creation

### Task 7: SKILL.md — `/apollo init` (project scaffolding)

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Write the `/apollo init` section**

Conversational project creation flow:
1. Ask project name
2. Ask project type (show available templates from `~/.apollo/templates/`)
3. Ask for any overrides to the template defaults (or accept all)
4. Ask whether to gitignore or commit `.apollo.yaml`
5. Scaffold:
   - Create `<projects_dir>/<project_name>/`
   - `git init`
   - Generate `.gitignore` (include secrets.env_pattern, secrets.extra_ignores, `.DS_Store`, editor files)
   - Create `.apollo.yaml` with `extends: <template>` and any overrides
   - If oss template: generate LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, `.github/ISSUE_TEMPLATE/`
   - Generate initial README.md with project name
   - If `.apollo.yaml` should be gitignored: add to `.gitignore`
6. Inject CLAUDE.md managed section (see Task 8)
7. Initial commit: `chore: initialize <project_name> with Apollo`
8. Confirm: "Project created at <path>. Run /apollo check to verify state."

**Step 2: Verify by running `/apollo init`**

Create a test project. Verify directory structure, git init, .gitignore, README, .apollo.yaml are all correct.

**Step 3: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add /apollo init project scaffolding"
```

---

### Task 8: SKILL.md — CLAUDE.md injection logic

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Write the instruction injection section**

This is a reusable procedure called by `/apollo init`, `/apollo check`, and "add to Apollo". Define it as a named procedure in the skill:

**Injection procedure:**
1. Determine target file based on project context:
   - If `.cursorrules` exists → Cursor project → target `.cursorrules`
   - If `CODEX.md` exists → Codex project → target `CODEX.md`
   - Default → `CLAUDE.md`
2. Read the resolved config (three-tier merge)
3. Generate the managed section content from config values:
   - One line per meaningful config value, written as an instruction
   - e.g. `stack.language: typescript` + `stack.package_manager: bun` → "Language: TypeScript, package manager: bun"
   - e.g. `workflow.tdd: true` + `testing.code.framework: vitest` → "Testing: TDD with vitest, run tests before every commit"
   - e.g. `git.commit_style: conventional` → "Commits: conventional style (feat:, fix:, chore:, etc.)"
   - e.g. `workflow.design_before_code: true` → "Design before code: always run brainstorming/design phase first"
4. If target file exists:
   - Look for `<!-- APOLLO:START -->` and `<!-- APOLLO:END -->` markers
   - If found: replace content between markers
   - If not found: append managed section at end of file
5. If target file doesn't exist:
   - Create it with only the managed section
6. Write the file

**Step 2: Verify by checking a scaffolded project's CLAUDE.md**

After running `/apollo init`, read the generated CLAUDE.md. Verify markers and content match config.

**Step 3: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add CLAUDE.md managed section injection"
```

---

### Task 9: Verify Phase 2 end-to-end

**Step 1: Full flow test**

1. Run `/apollo init`
2. Create a project named "test-apollo" with OSS template
3. Verify:
   - Directory created at `<projects_dir>/test-apollo/`
   - `.gitignore` has secrets patterns + `.DS_Store` + editor files
   - `.apollo.yaml` has `extends: oss`
   - `CLAUDE.md` has managed section with correct rules
   - `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` exist
   - `README.md` exists with project name
   - Git repo initialized with initial commit

**Step 2: Test with personal template (no OSS scaffolding)**

1. Run `/apollo init` again with personal template
2. Verify no LICENSE/CONTRIBUTING/CODE_OF_CONDUCT files
3. Verify CLAUDE.md reflects personal template config

**Step 3: Clean up test projects and commit fixes**

```bash
rm -rf <projects_dir>/test-apollo <projects_dir>/test-personal
git add skills/apollo/SKILL.md
git commit -m "fix: phase 2 verification fixes"
```

---

## Phase 3: Session Management

### Task 10: SKILL.md — `/apollo check` (health check)

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Write the `/apollo check` section**

Non-conversational health check. Reads config and repo state, outputs a report:

**Checks to perform:**
1. **Config loaded** — confirm `.apollo.yaml` or `~/.apollo/defaults.yaml` found, show resolved template
2. **CLAUDE.md sync** — compare managed section against current config, flag drift
3. **Git state** — uncommitted changes, unpushed commits, branch name vs strategy
4. **Docs freshness** — if `docs.readme: true`, check README exists; if `docs.changelog: true`, check CHANGELOG exists
5. **Test state** — if `testing.code.run_before_commit: true`, remind to run tests
6. **Version state** — current version (from manifest or `.apollo.yaml`), last tag, commits since tag
7. **Secrets check** — if `secrets.warn_on_commit: true`, scan staged files for env patterns

**Output format:**
```
Apollo Check — <project_name>
Template: oss | Config: ~/.apollo/defaults.yaml + .apollo.yaml

[OK] CLAUDE.md in sync with config
[WARN] 3 uncommitted changes
[OK] README.md exists
[MISSING] CHANGELOG.md not found (docs.changelog: true)
[OK] Version: 0.2.0 (from .apollo.yaml)
[INFO] 5 commits since last tag (v0.1.0)
[OK] No secrets detected in staged files
```

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add /apollo check health check"
```

---

### Task 11: SKILL.md — `/apollo` bare command (what next?)

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Write the bare `/apollo` section**

Context-aware guidance. Apollo reads the project state and suggests the next action:

**Detection logic:**
- No `~/.apollo/` → suggest `/apollo config`
- Not in a git repo → suggest `/apollo init`
- In a repo but no `.apollo.yaml` → suggest creating one or running `/apollo init`
- In a repo with config:
  - Uncommitted changes + tests not run → "Run tests, then commit"
  - Many commits since last tag → "Consider a release: /apollo release"
  - CLAUDE.md out of sync → "Config changed. Re-injecting CLAUDE.md..."
  - Stale docs → "README/CHANGELOG needs updating"
  - Everything clean → "Project is in good shape. What are you working on?"

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add bare /apollo context-aware guidance"
```

---

### Task 12: SKILL.md — "add to Apollo" handler

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Write the "add to Apollo" section**

Natural language config update. When the user says something like "add to Apollo: always use bun" or "apollo: never auto-commit":

1. Parse the instruction into a config key-value update
2. Ask: "Should this apply globally (defaults.yaml) or just this project (.apollo.yaml)?"
3. Read the target file
4. Update the relevant key
5. Write the file
6. Re-inject the CLAUDE.md managed section
7. Confirm: "Updated <key> to <value> in <file>. CLAUDE.md re-synced."

**Trigger detection:** The skill description should include "add to Apollo" as a trigger phrase. In the SKILL.md, include a section that handles natural language like:
- "add to Apollo: ..."
- "apollo: remember that ..."
- "update Apollo config: ..."
- "Apollo should always ..."

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add 'add to Apollo' natural language config updates"
```

---

### Task 13: Verify Phase 3

**Step 1: Test `/apollo check` in an existing project**

Navigate to a project with `.apollo.yaml`. Run `/apollo check`. Verify output matches expected format and checks are accurate.

**Step 2: Test bare `/apollo` in various states**

- In a clean repo → should say "in good shape"
- With uncommitted changes → should suggest commit
- With many commits since tag → should suggest release

**Step 3: Test "add to Apollo"**

Say "add to Apollo: always use pytest instead of vitest". Verify:
- Config updated
- CLAUDE.md re-injected with new value

**Step 4: Commit fixes**

```bash
git add skills/apollo/SKILL.md
git commit -m "fix: phase 3 verification fixes"
```

---

## Phase 4: Versioning & Release

### Task 14: SKILL.md — `/apollo release` (guided release flow)

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Write the `/apollo release` section**

Guided conversational release flow:

1. **Detect current version:**
   - Check `package.json` → `version` field
   - Check `pyproject.toml` → `[project] version`
   - Check `Cargo.toml` → `[package] version`
   - Fallback: `.apollo.yaml` → `version` key
   - If no version found anywhere: ask user for initial version (default: `0.1.0`), write to `.apollo.yaml`

2. **Analyze commits since last tag:**
   - Run `git log <last_tag>..HEAD --oneline`
   - If conventional commits: categorize into feat/fix/chore/breaking
   - Suggest bump type: breaking → major, feat → minor, fix → patch
   - If freeform commits: show the list and ask user to pick bump type

3. **Ask: patch, minor, or major?**
   - Show suggestion with rationale
   - User can override

4. **Update version:**
   - Write new version to manifest or `.apollo.yaml`
   - Update `.apollo.yaml` version if it exists (keep internal version in sync)

5. **Generate/update CHANGELOG.md:**
   - If `release.changelog: auto`:
     - Group commits by type (if conventional) or list chronologically
     - Prepend new version section to CHANGELOG.md
     - Format: `## [x.y.z] - YYYY-MM-DD` followed by grouped entries
   - If `release.changelog: manual`: open CHANGELOG.md and ask user to write entry
   - If `release.changelog: none`: skip

6. **Commit version bump + changelog:**
   ```bash
   git add <manifest> CHANGELOG.md .apollo.yaml
   git commit -m "chore: release vX.Y.Z"
   ```

7. **Create git tag** (if `release.tag_on_release: true`):
   ```bash
   git tag vX.Y.Z
   ```

8. **Ask about publish** (if `release.publish: true`):
   - Detect registry: npm (package.json), pypi (pyproject.toml), crates (Cargo.toml)
   - Ask: "Publish vX.Y.Z to <registry>?"
   - If yes, run the publish command
   - If no, skip

9. **Confirm:**
   ```
   Released vX.Y.Z
   - Version updated in <manifest>
   - CHANGELOG.md updated
   - Tagged: vX.Y.Z
   - Published: <yes/no>
   ```

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add /apollo release guided release flow"
```

---

### Task 15: Verify Phase 4

**Step 1: Test release on a project without a manifest**

Navigate to a project with only `.apollo.yaml`. Run `/apollo release`. Verify:
- Version read from `.apollo.yaml`
- Bump applied to `.apollo.yaml`
- CHANGELOG.md created/updated
- Git tag created

**Step 2: Test release on a project with package.json**

Navigate to a Node project. Run `/apollo release`. Verify:
- Version read from `package.json`
- Both `package.json` and `.apollo.yaml` updated
- Changelog and tag created

**Step 3: Commit fixes**

```bash
git add skills/apollo/SKILL.md
git commit -m "fix: phase 4 verification fixes"
```

---

## Phase 5: Enrichment & Polish

### Task 16: SKILL.md — Memories MCP integration

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Write the Memories enrichment section**

Optional layer that activates when Memories MCP tools are available (`mcp__memories__memory_search`, etc.):

**At `/apollo check` time:**
- Search Memories for the current project name: `memory_search(query: "<project_name> decisions patterns")`
- Surface relevant memories in the check output:
  ```
  [MEMORY] "Chose Redis over Postgres for caching — latency requirements" (2026-02-15)
  [MEMORY] "Tests need --forceExit flag due to open handles" (2026-02-20)
  ```

**At "add to Apollo" time:**
- After updating config, also store the decision in Memories:
  ```
  memory_add(text: "Apollo config: switched from vitest to pytest for <project>", source: "apollo/<project>")
  ```

**At `/apollo release` time:**
- Store release context:
  ```
  memory_add(text: "Released v1.2.0 of <project>: added auth system, fixed login bug", source: "apollo/<project>/releases")
  ```

**Graceful degradation:** If Memories tools aren't available, skip all memory operations silently. No error messages, no degraded UX — just fewer contextual insights.

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add optional Memories MCP enrichment"
```

---

### Task 17: SKILL.md — First-run detection & edge cases

**Files:**
- Modify: `skills/apollo/SKILL.md`

**Step 1: Add first-run detection**

At the top of the skill's routing logic, before any sub-command handling:
- Check if `~/.apollo/defaults.yaml` exists
- If not: "Welcome to Apollo! Let's set up your preferences first." → route to `/apollo config`
- This applies to ALL sub-commands — even `/apollo init` triggers config first if no defaults exist

**Step 2: Add edge case handling**

- Corrupt/unparseable YAML: "Apollo config at <path> has a syntax error. Would you like to fix it or reset to defaults?"
- Missing template reference: "Template '<name>' not found in ~/.apollo/templates/. Available: oss, personal, work. Pick one or create a new template?"
- Conflicting overrides: Last value wins (per resolution order). No error — just document this in the skill.
- No git repo for `/apollo check` or `/apollo release`: "This directory isn't a git repo. Run /apollo init to set one up."

**Step 3: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add first-run detection and edge case handling"
```

---

### Task 18: README.md

**Files:**
- Create: `~/Projects/apollo/README.md`

**Step 1: Write README**

Sections:
- **What is Apollo** — one paragraph
- **Install** — symlink command + run `/apollo config`
- **Commands** — table of sub-commands with one-line descriptions
- **Config** — link to `config/defaults.example.yaml`, explain three-tier resolution
- **Templates** — list built-in templates, explain how to create custom ones
- **Agent support** — currently Claude Code, designed for others
- **License** — MIT

Keep it concise. The quick start is: install, run `/apollo config`, then `/apollo init`.

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with install, commands, and config reference"
```

---

### Task 19: Apollo manages itself

**Files:**
- Create: `~/Projects/apollo/.apollo.yaml`

**Step 1: Write Apollo's own .apollo.yaml**

Apollo eats its own dog food:

```yaml
extends: oss
version: 0.1.0

stack:
  language: yaml
  package_manager: none
  test_framework: manual

testing:
  code:
    approach: none
    run_before_commit: false
  product:
    tool: manual
    trigger: release

release:
  versioning: semver
  changelog: auto
  tag_on_release: true
  publish: false
```

**Step 2: Commit**

```bash
git add .apollo.yaml
git commit -m "feat: Apollo manages itself — add .apollo.yaml"
```

---

### Task 20: Final verification & v0.1.0 release

**Step 1: Full end-to-end test**

1. Fresh start: delete `~/.apollo/` if it exists
2. Run `/apollo config` → complete onboarding
3. Run `/apollo init` → create test project with OSS template
4. Navigate to test project
5. Run `/apollo check` → verify health check output
6. Run `/apollo` → verify context-aware guidance
7. Say "add to Apollo: always use bun" → verify config update + CLAUDE.md re-injection
8. Run `/apollo release` → verify release flow
9. Clean up test project

**Step 2: Fix any issues found**

```bash
git add -A
git commit -m "fix: final verification fixes"
```

**Step 3: Tag v0.1.0 release**

```bash
git tag v0.1.0
```

**Step 4: Commit CHANGELOG**

Write CHANGELOG.md with v0.1.0 entries, commit:

```bash
git add CHANGELOG.md
git commit -m "docs: add CHANGELOG for v0.1.0"
```
