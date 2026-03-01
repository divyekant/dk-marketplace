---
name: apollo
description: "Use when starting a new project, beginning a development session, managing releases, or when the user says 'apollo', '/apollo', or 'add to Apollo'. Also triggers on 'set up project', 'new project', 'project preferences', or 'release'."
---

# Apollo — Project Lifecycle Manager

## Overview

Apollo is an agent-agnostic project lifecycle manager. It encodes user preferences into a YAML config and enforces them by injecting rules into agent instruction files (CLAUDE.md, .cursorrules, etc.).

**Core principle:** The config format is the product. This skill is just the first adapter.

## First-Run Detection

Before handling any sub-command, check if `~/.apollo/defaults.yaml` exists.

If it does NOT exist:
- Say: "Welcome to Apollo! Let's set up your preferences first."
- Route to `/apollo config` (below), regardless of what sub-command was invoked.
- After config completes, continue with the originally requested sub-command.

## Sub-Command Routing

Detect the user's intent from their message or argument:

| User says | Route to |
|-----------|----------|
| `/apollo config` or "set up apollo" or "edit preferences" | **Config** section |
| `/apollo init` or "new project" or "set up project" or "create project" | **Init** section |
| `/apollo check` or "check project" or "project health" | **Check** section |
| `/apollo release` or "release" or "bump version" or "tag release" | **Release** section |
| "add to Apollo: ..." or "apollo: remember ..." or "update Apollo config" | **Add to Apollo** section |
| `/apollo` (bare, no args) or "what should I do next" | **What Next** section |

## Config Resolution

Apollo uses three-tier config resolution. Later tiers override earlier ones.

**Resolution order:**
1. `~/.apollo/defaults.yaml` — global user preferences
2. `~/.apollo/templates/<name>.yaml` — template overrides (referenced via `extends` key)
3. `.apollo.yaml` (in current project root) — per-project overrides

**How to resolve:**
1. Read `~/.apollo/defaults.yaml`. This is the base config.
2. If the context has an `extends` key (from `.apollo.yaml` or if initializing with a template), read `~/.apollo/templates/<extends>.yaml` and merge on top of defaults. Keys in the template override defaults.
3. If `.apollo.yaml` exists in the current working directory (or project root), read it and merge on top. Keys in `.apollo.yaml` override everything. Ignore the `extends` and `version` keys during merge — `extends` is metadata, `version` is tracked separately.

**Merge strategy:** Deep merge. Nested keys override individually, not entire objects. For example, if defaults has `stack.language: typescript` and `.apollo.yaml` has `stack.package_manager: pip`, the result is `stack.language: typescript` + `stack.package_manager: pip`.

**Dev section merge:** `dev.runtime` overrides as a scalar. `dev.services` and `dev.commands` merge by key — project-level entries add to or override template/default entries (same deep-merge behavior as other sections).

---

## /apollo config — Conversational Onboarding

Set up or edit `~/.apollo/defaults.yaml` through guided Q&A.

### If `~/.apollo/` does not exist:

Create the directory structure:
```
~/.apollo/
  defaults.yaml
  templates/
    oss.yaml
    personal.yaml
    work.yaml
```

Copy the template files from the Apollo skill's source repo. The templates are at the path where this skill is installed, under `../../config/templates/`. If the source templates can't be found, create minimal versions inline.

### Onboarding flow:

Ask questions ONE AT A TIME using AskUserQuestion. Use multiple choice where possible.

**Question order:**

1. **Projects directory**
   - "Where do you keep your projects?"
   - Default: `~/Projects`

2. **Primary language**
   - "What's your go-to programming language?"
   - Options: TypeScript, Python, Rust, Go, Java, Other

3. **Package manager**
   - Show options relevant to the language chosen:
     - TypeScript/JavaScript: npm, yarn, pnpm, bun
     - Python: pip, poetry, uv
     - Rust: cargo
     - Go: go modules
     - Java: maven, gradle

4. **Test framework**
   - Show options relevant to the language:
     - TypeScript: vitest, jest
     - Python: pytest, unittest
     - Rust: cargo-test
     - Go: go-test
     - Java: junit

5. **Commit style**
   - "How do you like your commit messages?"
   - Options: Conventional (feat:, fix:, etc.), Freeform

6. **Branch strategy**
   - "Branch strategy?"
   - Options: Feature branches, Trunk-based

7. **Code style**
   - "Coding style preference?"
   - Options: Concise (minimal comments, lean code), Thorough (detailed comments, defensive)

8. **Testing approach**
   - "How do you approach testing?"
   - Options: TDD (test first), Test after, No preference

9. **Design before code?**
   - "Always design/brainstorm before writing code?"
   - Options: Yes (recommended), No

10. **Docs preferences**
    - "Which docs should be auto-maintained?"
    - Multi-select: README, CHANGELOG, Neither

11. **Release versioning**
    - "How do you version releases?"
    - Options: Semver (1.2.3), Calendar (2026.02), Manual

12. **Dev runtime** (optional)
    - "Does this project run locally or in containers?"
    - Options: Local (bare process), Docker Compose, Docker, Podman, Skip for now
    - If "Skip": omit `dev:` section entirely

13. **Services** (only if runtime is not "local" and not "skip")
    - "What services does it run? (name:port, comma-separated, or 'skip')"
    - Parse into `dev.services` map with port as number
    - Optionally ask for descriptions: "Brief description for each? (or 'skip')"

14. **Dev commands** (only if runtime is not "skip")
    - "Start command?" — e.g., `docker compose up -d` or `npm start`
    - "Stop command? (or 'skip')" — e.g., `docker compose down`
    - "Test command? (or 'skip')" — e.g., `docker compose exec api npm test`
    - "Build command? (or 'skip')" — e.g., `docker compose build`
    - "Any other commands? (name: command, or 'done')" — e.g., `logs: docker compose logs -f`

### After all questions:

Assemble the answers into a valid `defaults.yaml` and write it to `~/.apollo/defaults.yaml`.

Confirm: "Saved your preferences to `~/.apollo/defaults.yaml`. You can edit it directly or run `/apollo config` anytime to update."

### If config already exists:

Show current values as a summary table, then ask: "What would you like to change?" Let the user pick a category to update, or say "looks good" to exit.

---

## /apollo init — Project Creation

Create a new project with scaffolding based on Apollo config.

### Flow:

1. **Ask project name**
   - "What's the project name?"
   - Validate: lowercase, hyphens allowed, no spaces

2. **Ask project type**
   - "What kind of project?"
   - Options: list template names from `~/.apollo/templates/` (typically: oss, personal, work)
   - This sets the `extends` value

3. **Ask for overrides**
   - Show the resolved config (defaults + template) as a summary
   - "Any changes for this project, or use these defaults?"
   - If changes: ask which category, then which value

   After override questions, if the resolved config does not yet have a `dev:` section:
   - Ask the dev environment questions (same as onboarding questions 12-14 above)
   - If user answers, merge into `.apollo.yaml` for this project
   - If user skips, omit `dev:` from the project config

4. **Ask about .apollo.yaml tracking**
   - "Should .apollo.yaml be committed to git (for team sharing) or gitignored (personal only)?"
   - Options: Gitignore (recommended for solo), Commit (for teams)

5. **Scaffold the project**

   Read `projects_dir` from config. Create the project at `<projects_dir>/<project_name>/`.

   **Always create:**
   - `<project_name>/` directory
   - `.gitignore` — include:
     - `secrets.env_pattern` value (e.g., `.env*`)
     - Each entry in `secrets.extra_ignores`
     - `.DS_Store`, `Thumbs.db`
     - `.idea/`, `.vscode/`, `*.swp`
     - If .apollo.yaml should be gitignored: `.apollo.yaml`
   - `.apollo.yaml` with `extends: <template>`, `version: 0.1.0`, and any user overrides
   - `README.md` with `# <project_name>` and a one-line description placeholder
   - Run `git init`

   **If OSS template (oss fields are truthy):**
   - `LICENSE` — generate based on `oss.license` value (MIT, Apache-2.0, GPL-3.0)
   - `CONTRIBUTING.md` — if `oss.contributing: true`, generate a standard contributing guide
   - `CODE_OF_CONDUCT.md` — if `oss.code_of_conduct: true`, generate Contributor Covenant
   - `.github/ISSUE_TEMPLATE/bug_report.md` and `feature_request.md` — if `oss.issue_templates: true`

6. **Inject agent instructions**

   Follow the **Instruction Injection** procedure (below) to write the managed section into the project's agent instruction file.

7. **Initial commit**

   ```bash
   git add -A
   git commit -m "chore: initialize <project_name> with Apollo"
   ```

8. **Confirm**

   "Project created at `<path>`. Run `/apollo check` to verify state."

---

## /apollo check — Health Check

Read config and repo state, output a status report. Non-conversational — just report findings.

### Checks:

1. **Config status**
   - Is `.apollo.yaml` present? Which template does it extend?
   - Is `~/.apollo/defaults.yaml` present?
   - Show: "Template: <name> | Config: <sources loaded>"

2. **Instruction sync** (check ALL configured agents)
   - For each agent in the `agents` config list:
     - Read that agent's instruction file (see Agent File Formats in Injection Procedure)
     - Look for `<!-- APOLLO:START -->` markers (or check MDC content for Cursor)
     - Compare managed section against current resolved config
     - If in sync: `[OK] <agent> instructions in sync`
     - If out of sync: `[DRIFT] <agent> instructions out of sync — run /apollo to re-inject`
     - If file/section missing: `[MISSING] <agent> instruction file not found`

3. **Git state**
   - Uncommitted changes: `[WARN] N uncommitted changes`
   - Unpushed commits: `[INFO] N commits ahead of remote`
   - Branch name vs `git.branch_strategy`: info only

4. **Docs freshness**
   - If `docs.readme: true` and no README: `[MISSING] README.md not found`
   - If `docs.changelog: true` and no CHANGELOG: `[MISSING] CHANGELOG.md not found`

5. **Version state**
   - Current version (from manifest or `.apollo.yaml`)
   - Last git tag
   - Commits since last tag: `[INFO] N commits since <tag>`

6. **Secrets scan**
   - If `secrets.warn_on_commit: true`: check `git diff --cached --name-only` for files matching `secrets.env_pattern` or `secrets.extra_ignores`
   - If found: `[WARN] Staged file matches secrets pattern: <filename>`

7. **Dev environment** (if `dev:` is present in resolved config)
   - Check for duplicate ports across services: `[WARN] Duplicate port {port} in services: {name1}, {name2}`
   - If `dev.runtime` is `docker-compose`: check if `docker-compose.yaml` or `compose.yaml` exists in project root. If not: `[WARN] Runtime is docker-compose but no compose file found`
   - If all checks pass: `[OK] Dev: {runtime}, {N} services`

8. **Memories context** (optional)
   - If Memories MCP tools are available, search for project-specific memories
   - Surface up to 3 relevant memories as `[MEMORY]` entries

### Output format:

```
Apollo Check — <project_name>
Template: <name> | Config: <sources>

[OK] Agent instructions in sync
[WARN] 3 uncommitted changes
[OK] README.md exists
[MISSING] CHANGELOG.md not found (docs.changelog: true)
[OK] Version: 0.2.0 (from .apollo.yaml)
[INFO] 5 commits since v0.1.0
[OK] No secrets in staged files
[OK] Dev: docker-compose, 3 services (api:3001, frontend:5173, redis:6379)
[MEMORY] "Tests need --forceExit flag" (2026-02-20)
```

---

## /apollo (bare) — What Next?

Context-aware guidance. Detect project state and suggest the most useful next action.

### Detection logic (check in this order):

1. **No config at all** → "Run `/apollo config` to set up your preferences."
2. **Not in a git repo** → "Run `/apollo init` to create a new project."
3. **In a repo but no `.apollo.yaml`** → "This project doesn't have Apollo config yet. Want me to create `.apollo.yaml` from your defaults?"
4. **Agent instructions missing or drifted** → Re-inject the managed section automatically, then confirm: "Re-synced agent instructions with Apollo config."
5. **Uncommitted changes** + `testing.code.run_before_commit: true` → "You have uncommitted changes. Run tests first, then commit."
6. **Many commits since last tag** (5+) → "You have N commits since the last release. Consider `/apollo release`."
7. **Missing docs** (`docs.readme` or `docs.changelog` is true but file missing) → "Your config expects a README/CHANGELOG but it's missing. Want me to create it?"
8. **Everything clean** → "Project is in good shape. What are you working on?"

Only show the FIRST applicable suggestion. Don't overwhelm with a list.

---

## /apollo release — Guided Release

Walk the user through versioning, changelog, tagging, and publishing.

### Flow:

1. **Detect current version**
   - Check in order: `package.json` → `pyproject.toml` → `Cargo.toml` → `.apollo.yaml`
   - If no version found anywhere: ask user for initial version (suggest `0.1.0`), write to `.apollo.yaml`
   - Show: "Current version: <version> (from <source>)"

2. **Analyze commits since last tag**
   - Find last tag: `git describe --tags --abbrev=0 2>/dev/null`
   - If no tags: use all commits
   - List commits: `git log <tag>..HEAD --oneline`
   - If `git.commit_style: conventional`: categorize into feat/fix/chore/docs/breaking
   - Suggest bump: breaking change → major, feat → minor, fix/chore → patch
   - If `git.commit_style: freeform`: show commit list, ask user to pick bump type

3. **Ask bump type**
   - "Suggested: <type> bump (<current> → <new>). Agree, or pick differently?"
   - Options: Patch, Minor, Major, Custom version

4. **Update version**
   - Write new version to the source where it was found (manifest or `.apollo.yaml`)
   - If `.apollo.yaml` exists and version was in a manifest, also update `.apollo.yaml` version

5. **Generate changelog** (based on `release.changelog` config)
   - If `auto`: generate from commits grouped by type. Prepend to CHANGELOG.md:
     ```markdown
     ## [X.Y.Z] - YYYY-MM-DD

     ### Added
     - feat commits listed here

     ### Fixed
     - fix commits listed here

     ### Changed
     - other commits listed here
     ```
   - If `manual`: tell user to write the changelog entry, wait for confirmation
   - If `none`: skip

6. **Commit release changes**
   ```bash
   git add <changed files>
   git commit -m "chore: release vX.Y.Z"
   ```

7. **Create git tag** (if `release.tag_on_release: true`)
   ```bash
   git tag vX.Y.Z
   ```

8. **Ask about publish** (if `release.publish: true`)
   - Detect registry from manifest type
   - "Publish vX.Y.Z to <registry>?"
   - If yes: run publish command (`npm publish`, `poetry publish`, `cargo publish`)
   - If no: skip

9. **Confirm**
   ```
   Released vX.Y.Z
   - Version updated in <source>
   - CHANGELOG.md updated
   - Tagged: vX.Y.Z
   - Published: yes/no
   ```

---

## Add to Apollo — Mid-Session Config Updates

When the user says something like "add to Apollo: always use bun" or "Apollo: never auto-commit":

### Flow:

1. **Parse the instruction** into a config key and value. Map natural language to config keys:
   - "always use bun" → `stack.package_manager: bun`
   - "never auto-commit" → `git.auto_commit: false`
   - "use pytest" → `stack.test_framework: pytest` + `testing.code.framework: pytest`
   - "conventional commits" → `git.commit_style: conventional`
   - "api runs on port 3001" → `dev.services.api.port: 3001`
   - "we use docker compose" → `dev.runtime: docker-compose`
   - "start with docker compose up -d" → `dev.commands.start: "docker compose up -d"`
   - "frontend on 5173" → `dev.services.frontend.port: 5173`
   - If the mapping isn't obvious, ask: "Which config key should I update?"

2. **Ask scope**
   - "Should this apply globally (all projects) or just this project?"
   - Global → update `~/.apollo/defaults.yaml`
   - This project → update `.apollo.yaml`

3. **Read, update, and write** the target YAML file

4. **Re-inject agent instructions** using the Instruction Injection procedure

5. **Store in Memories** (if available)
   - `memory_add(text: "Apollo config: <change description> for <project/global>", source: "apollo/<project_name>")`

6. **Confirm**
   - "Updated `<key>` to `<value>` in `<file>`. Agent instructions re-synced."

---

## Instruction Injection Procedure

This procedure is called by `/apollo init`, `/apollo check` (when drift detected), `/apollo` (bare, when drift detected), and "add to Apollo".

### Steps:

1. **Determine target agents**

   Read the `agents` list from resolved config. If not set, default to `[claude-code]`.

   For EACH agent in the list, write to its instruction file using the agent-specific format below.

2. **Resolve config** using three-tier resolution

3. **Generate instructions** from resolved config. Translate each config value into a human-readable instruction:

   | Config | Instruction |
   |--------|------------|
   | `stack.language` + `stack.package_manager` | "Language: {lang}, package manager: {pm}" |
   | `git.commit_style: conventional` | "Commits: conventional style (feat:, fix:, chore:, etc.)" |
   | `git.auto_commit: false` | "Never auto-commit — always ask before committing" |
   | `git.branch_strategy` | "Branch strategy: {strategy}" |
   | `code.style` + `code.comments` | "Code style: {style}, comments: {comments}" |
   | `testing.code.approach: tdd` | "Testing: TDD — write tests before implementation" |
   | `testing.code.framework` | "Test framework: {framework}" |
   | `testing.code.run_before_commit: true` | "Run tests before every commit" |
   | `testing.product.tool: delphi` | "Product testing: use Delphi for {surfaces} surfaces" |
   | `workflow.design_before_code: true` | "Design before code: always run brainstorming/design phase first" |
   | `workflow.design_entry_skill` | "Design entry: invoke {skill} skill for all design/brainstorm work" |
   | `docs.quickstart: true` | "Maintain a Quick Start guide" |
   | `docs.architecture: true` | "Maintain architecture documentation" |
   | `docs.decisions: true` | "Track decisions in docs/decisions/" |
   | `workflow.review_before_merge: true` | "Code review required before merging" |
   | `docs.readme: true` | "Maintain README.md" |
   | `docs.changelog: true` | "Maintain CHANGELOG.md" |
   | `docs.update_trigger` | "Update docs on: {trigger}" |
   | `release.versioning` | "Versioning: {scheme}" |
   | `secrets.warn_on_commit: true` | "Check for secrets before committing" |
   | `dev.runtime` | "Dev runtime: {runtime}" |
   | `dev.services` | "Services: {name} (:{port}), ..." — list all services with ports |
   | `dev.commands.start` | "Start: `{command}`" |
   | `dev.commands.stop` | "Stop: `{command}`" |
   | `dev.commands.build` | "Build: `{command}`" |
   | `dev.commands.test` | "Test: `{command}`" |
   | `dev.commands.*` (other) | "{name}: `{command}`" — any custom command keys |

   Only include instructions for config values that are set and meaningful (skip nulls, empty arrays, false booleans that represent absence).

4. **Write to each agent's instruction file** using the format for that agent

### Agent File Formats

#### claude-code → `CLAUDE.md`

Markdown with HTML comment markers:

```markdown
<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
- <instruction 1>
- <instruction 2>
<!-- APOLLO:END -->
```

Write strategy:
- If file exists and has markers: replace content between markers
- If file exists but no markers: append managed section at end
- If file doesn't exist: create with managed section only

#### cursor → `.cursor/rules/apollo.mdc`

Cursor uses MDC (Markdown Component) format in `.cursor/rules/`. Create the directory if needed.

```markdown
---
description: Project conventions managed by Apollo
globs:
alwaysApply: true
---

# Project Conventions (managed by Apollo)

- <instruction 1>
- <instruction 2>
```

Write strategy:
- Create `.cursor/rules/` directory if it doesn't exist
- Always overwrite `.cursor/rules/apollo.mdc` entirely (Apollo owns this file)
- Never touch other `.mdc` files in the directory

#### codex → `AGENTS.md`

OpenAI Codex reads `AGENTS.md` at project root. Same marker-based approach as CLAUDE.md:

```markdown
<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
- <instruction 1>
- <instruction 2>
<!-- APOLLO:END -->
```

Write strategy: same as claude-code (marker-based insert/replace/create).

#### windsurf → `.windsurfrules`

Plain markdown, marker-based:

```markdown
<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
- <instruction 1>
- <instruction 2>
<!-- APOLLO:END -->
```

Write strategy: same as claude-code (marker-based insert/replace/create).

#### copilot → `.github/copilot-instructions.md`

GitHub Copilot reads from `.github/copilot-instructions.md`. Create `.github/` if needed.

```markdown
<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
- <instruction 1>
- <instruction 2>
<!-- APOLLO:END -->
```

Write strategy:
- Create `.github/` directory if it doesn't exist
- Marker-based insert/replace/create (same as claude-code)

#### aider → `CONVENTIONS.md`

Aider reads `CONVENTIONS.md` at project root. Marker-based:

```markdown
<!-- APOLLO:START - Do not edit this section manually -->
## Project Conventions (managed by Apollo)
- <instruction 1>
- <instruction 2>
<!-- APOLLO:END -->
```

Write strategy: same as claude-code (marker-based insert/replace/create).

### Multi-Agent Summary

| Agent | File | Format | Owned by Apollo? |
|-------|------|--------|-----------------|
| `claude-code` | `CLAUDE.md` | Markdown, markers | Managed section only |
| `cursor` | `.cursor/rules/apollo.mdc` | MDC frontmatter | Entire file |
| `codex` | `AGENTS.md` | Markdown, markers | Managed section only |
| `windsurf` | `.windsurfrules` | Markdown, markers | Managed section only |
| `copilot` | `.github/copilot-instructions.md` | Markdown, markers | Managed section only |
| `aider` | `CONVENTIONS.md` | Markdown, markers | Managed section only |

Apollo writes to ALL configured agents on every injection. If an agent is removed from the config, its file is left as-is (no cleanup — user can delete manually).

---

## Edge Cases

- **Corrupt YAML:** If any config file fails to parse, tell the user: "Apollo config at `<path>` has a syntax error on line N. Fix it manually or run `/apollo config` to regenerate."
- **Missing template:** If `extends` references a template that doesn't exist in `~/.apollo/templates/`, list available templates and ask the user to pick one.
- **No git repo** (for check/release): "This directory isn't a git repo. Run `/apollo init` to create a project, or `git init` to initialize one."
- **No changes since last tag** (for release): "No commits since the last release (vX.Y.Z). Nothing to release."
- **Merge conflicts in managed section:** If the markers are present but content between them is malformed, regenerate the entire managed section.
