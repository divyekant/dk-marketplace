# Dev Section Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an optional `dev:` section to Apollo's config schema that captures local development environment details (runtime, services/ports, commands) and surfaces them to agents.

**Architecture:** Extend the existing config schema with a new top-level `dev:` key. Update the skill spec (SKILL.md) to include `dev:` in onboarding questions, instruction injection, and health checks. Update example configs and templates.

**Tech Stack:** YAML config files, Markdown skill spec

---

### Task 1: Add `dev:` section to defaults.example.yaml

**Files:**
- Modify: `config/defaults.example.yaml:78` (append after secrets section)

**Step 1: Add the dev section to the example config**

Add after the `secrets:` section (line 78):

```yaml

# Local development environment (optional)
# Tells agents how to build, run, and test the project locally
dev:
  runtime: local                # local | docker-compose | docker | podman
  # services:                   # Map of service name to port/description
  #   api:
  #     port: 3001
  #     description: Backend API
  #   frontend:
  #     port: 5173
  #     description: Vite dev server
  #   redis:
  #     port: 6379
  commands:
    start: "npm start"          # How to start the project
    # stop: ""                  # How to stop (relevant for containers)
    build: "npm run build"      # How to build
    test: "npm test"            # How to run tests
    # logs: ""                  # How to view logs
```

**Step 2: Validate YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('config/defaults.example.yaml'))"`
Expected: No output (success)

**Step 3: Commit**

```bash
git add config/defaults.example.yaml
git commit -m "feat: add dev section to defaults example config"
```

---

### Task 2: Add `dev:` to work template

**Files:**
- Modify: `config/templates/work.yaml:31` (append at end)

**Step 1: Add dev section to work template**

Work projects are most likely to use Docker. Add after the `release:` section:

```yaml

dev:
  runtime: docker-compose
```

**Step 2: Validate YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('config/templates/work.yaml'))"`
Expected: No output (success)

**Step 3: Commit**

```bash
git add config/templates/work.yaml
git commit -m "feat: add dev runtime default to work template"
```

---

### Task 3: Add onboarding questions for `dev:` to SKILL.md

**Files:**
- Modify: `skills/apollo/SKILL.md:126-132` (insert new questions after question 11, before the "After all questions" section)

**Step 1: Add questions 12-15 after question 11 (line 128)**

Insert after the release versioning question (line 128) and before the "### After all questions:" section (line 130):

```markdown

12. **Dev runtime**
    - "Does this project run locally or in containers?"
    - Options: Local (bare process), Docker Compose, Docker, Podman, Skip for now
    - If "Skip": omit `dev:` section entirely

13. **Services** (only if runtime is not "local" and not "skip")
    - "What services does it run? (name:port, comma-separated, or 'skip')"
    - Parse into `dev.services` map with port as number
    - Optionally ask for descriptions: "Brief description for each? (or 'skip')"

14. **Dev commands**
    - "Start command?" — e.g., `docker compose up -d` or `npm start`
    - "Stop command? (or 'skip')" — e.g., `docker compose down`
    - "Test command? (or 'skip')" — e.g., `docker compose exec api npm test`
    - "Build command? (or 'skip')" — e.g., `docker compose build`
    - "Any other commands? (name: command, or 'done')" — e.g., `logs: docker compose logs -f`
```

**Step 2: Verify the question numbering and flow reads correctly**

Read `skills/apollo/SKILL.md` lines 72-140 to verify continuity.

**Step 3: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add dev environment questions to onboarding flow"
```

---

### Task 4: Add `dev:` to instruction injection table in SKILL.md

**Files:**
- Modify: `skills/apollo/SKILL.md:400-424` (add rows to the instruction generation table)

**Step 1: Add dev instruction mappings**

Add these rows to the instruction table after the `secrets.warn_on_commit` row (line 423):

```markdown
   | `dev.runtime` | "Dev runtime: {runtime}" |
   | `dev.services` | "Services: {name} (:{port}), ..." — list all services with ports |
   | `dev.commands.start` | "Start: `{command}`" |
   | `dev.commands.stop` | "Stop: `{command}`" |
   | `dev.commands.build` | "Build: `{command}`" |
   | `dev.commands.test` | "Test: `{command}`" |
   | `dev.commands.*` (other) | "{name}: `{command}`" — any custom command keys |
```

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add dev section to instruction injection mappings"
```

---

### Task 5: Add `dev:` validation to /apollo check in SKILL.md

**Files:**
- Modify: `skills/apollo/SKILL.md:239-241` (insert new check after secrets scan, before memories)

**Step 1: Add dev environment check**

Insert a new check 7 (renumber existing 7 to 8) after the secrets scan section:

```markdown

7. **Dev environment** (if `dev:` is present in resolved config)
   - Check for duplicate ports across services: `[WARN] Duplicate port {port} in services: {name1}, {name2}`
   - If `dev.runtime` is `docker-compose`: check if `docker-compose.yaml` or `compose.yaml` exists in project root. If not: `[WARN] Runtime is docker-compose but no compose file found`
   - If all checks pass: `[OK] Dev environment configured ({runtime}, {N} services)`
```

**Step 2: Update the output example to include dev check**

In the output format example (around line 260), add:

```
[OK] Dev: docker-compose, 3 services (api:3001, frontend:5173, redis:6379)
```

**Step 3: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add dev environment validation to apollo check"
```

---

### Task 6: Add `dev:` to /apollo init flow in SKILL.md

**Files:**
- Modify: `skills/apollo/SKILL.md:156-160` (add dev questions to init override step)

**Step 1: Add dev questions to init flow**

In the init flow at step 3 "Ask for overrides" (line 157), add a note that the dev section questions should also be asked during init if not already set in defaults/template:

After line 160, insert:

```markdown

   After override questions, if the resolved config does not yet have a `dev:` section:
   - Ask the dev environment questions (same as onboarding questions 12-14 above)
   - If user answers, merge into `.apollo.yaml` for this project
   - If user skips, omit `dev:` from the project config
```

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add dev questions to apollo init flow"
```

---

### Task 7: Add `dev:` to "add to Apollo" natural language mappings

**Files:**
- Modify: `skills/apollo/SKILL.md:362-366` (add dev-related natural language examples)

**Step 1: Add dev mapping examples**

Add these examples after line 366:

```markdown
   - "api runs on port 3001" → `dev.services.api.port: 3001`
   - "we use docker compose" → `dev.runtime: docker-compose`
   - "start with docker compose up -d" → `dev.commands.start: "docker compose up -d"`
   - "frontend on 5173" → `dev.services.frontend.port: 5173`
```

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "feat: add dev section to natural language config mappings"
```

---

### Task 8: Update config resolution docs for dev section merge behavior

**Files:**
- Modify: `skills/apollo/SKILL.md:50` (add dev-specific merge note)

**Step 1: Add merge note for dev section**

After the existing merge strategy line (line 50), add:

```markdown

**Dev section merge:** `dev.runtime` overrides as a scalar. `dev.services` and `dev.commands` merge by key — project-level entries add to or override template/default entries (same deep-merge behavior as other sections).
```

**Step 2: Commit**

```bash
git add skills/apollo/SKILL.md
git commit -m "docs: document dev section merge behavior in config resolution"
```

---

### Task 9: Update design doc and CHANGELOG

**Files:**
- Modify: `docs/plans/2026-02-27-apollo-design.md:97-99` (add dev section to config schema)
- Modify: `CHANGELOG.md` (add unreleased entry)

**Step 1: Add dev section to design doc config schema**

In the config schema example (around line 97), after the `release:` section and before `secrets:`, add:

```yaml

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
```

**Step 2: Add to design doc decisions table**

Add a row to the Design Decisions table (around line 333):

```markdown
| Dev section | Optional, flat structure | Not all projects have runtimes. Flat matches existing config pattern. |
```

**Step 3: Add CHANGELOG entry**

Add under Unreleased or create a new unreleased section at the top:

```markdown
## Unreleased

### Added
- `dev:` section in config for local development environment (runtime, services/ports, commands)
- Onboarding questions for dev environment setup
- `/apollo check` validates dev environment (duplicate ports, compose file existence)
- Natural language support for adding dev config ("we use docker compose", "api on 3001")
```

**Step 4: Commit**

```bash
git add docs/plans/2026-02-27-apollo-design.md CHANGELOG.md
git commit -m "docs: update design doc and changelog for dev section"
```
