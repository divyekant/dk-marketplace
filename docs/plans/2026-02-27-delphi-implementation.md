# Delphi Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Delphi skill — a coding agent skill that generates and executes comprehensive test scenarios (guided cases) for any software.

**Architecture:** Single skill file (`skill.md`) with two modes (generate + execute). No external dependencies. The agent uses its native tools (Read, Glob, Grep, Write, Bash, Chrome MCP) to analyze code and produce structured Markdown guided cases. Phased delivery: generate first, execute second.

**Tech Stack:** Markdown skill file, structured Markdown output format, Git for version control.

**Ref:** [Vision](../VISION.md) | [Design](./2026-02-27-delphi-design.md)

---

## Phase 1: Scaffolding & Reference Example

### Task 1: Create project structure and .gitignore

**Files:**
- Create: `delphi/.gitignore`
- Create: `delphi/skills/delphi/` (directory)
- Create: `delphi/examples/` (directory)

**Step 1: Create directories and .gitignore**

```bash
mkdir -p /Users/divyekant/Projects/delphi/skills/delphi
mkdir -p /Users/divyekant/Projects/delphi/examples
```

Write `.gitignore`:

```
.DS_Store
*.swp
*.swo
*~
```

**Step 2: Commit**

```bash
git add .gitignore skills/ examples/
git commit -m "chore: scaffold project structure"
```

---

### Task 2: Write the reference example guided case

This example serves as the gold standard for what Delphi should produce. It demonstrates every section of the format with a realistic scenario (a todo app login flow).

**Files:**
- Create: `examples/sample-guided-case.md`

**Step 1: Write the sample**

Write `examples/sample-guided-case.md` with a complete, realistic guided case for a todo app login flow. Must include ALL sections from the format spec in VISION.md:
- Full metadata block (Type, Priority, Surface, Flow, Tags, Generated, Last Executed)
- Preconditions with verifiable conditions
- Steps with numbered actions, each having Target, Input (where applicable), and Expected outcomes
- Multiple expected outcomes per step where appropriate
- Success Criteria as a checklist
- Failure Criteria as conditions
- Notes section

Use this scenario: **"Login with valid credentials — happy path"** for a todo app at `http://localhost:3000`. Include realistic steps: navigate to login page, verify page elements, enter email, enter password, click sign in, verify redirect to dashboard, verify user greeting.

**Step 2: Write a negative example too**

Write `examples/sample-negative-case.md` — same app, but scenario: **"Login with invalid password"**. Shows how negative cases differ: same setup steps, but expects error message, expects form NOT to submit, expects password field to clear.

**Step 3: Commit**

```bash
git add examples/
git commit -m "docs: add reference guided case examples (positive + negative)"
```

---

## Phase 2: Write the Skill — Generate Mode

### Task 3: Write skill.md frontmatter and overview

**Files:**
- Create: `skills/delphi/skill.md`

**Step 1: Write frontmatter + overview**

The frontmatter must follow writing-skills conventions:
- `name`: `delphi`
- `description`: Triggering conditions only, NO workflow summary. Start with "Use when..."
- Description must be under 500 characters
- Third person

Good description: `Use when software has been built and needs comprehensive test scenarios covering positive, negative, edge, accessibility, and security paths — for human testers and AI agents to execute. Also use to execute previously generated guided cases via browser automation or programmatic verification.`

Overview section: 2-3 sentences explaining what Delphi is. Core principle in one line.

**Step 2: Write mode detection section**

Add a section explaining the two modes and how they're triggered:
- "generate" keywords → Generate mode
- "execute" / "run" keywords → Execute mode
- "generate and execute" → Both sequentially
- Pipeline trigger → Generate (+ execute if browser available)

Include a decision flowchart (small, dot format) for mode selection.

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat: add delphi skill frontmatter and mode detection"
```

---

### Task 4: Write Generate Mode — Context Gathering

**Files:**
- Modify: `skills/delphi/skill.md`

**Step 1: Write the Context Gathering section**

This is Step 1 of Generate mode. The skill must instruct the agent to:

1. **Code structure scan** — Provide exact glob patterns to search:
   - Routes/pages: `**/pages/**`, `**/routes/**`, `**/app/**/page.*`, `**/*router*`
   - Components: `**/components/**/*.{tsx,jsx,vue,svelte}`
   - API handlers: `**/api/**`, `**/routes/**/*.{ts,js}`, `**/controllers/**`, `**/handlers/**`
   - CLI entry points: `**/bin/**`, `**/cli/**`, `**/commands/**`, `**/*cli*`
   - Models/schemas: `**/models/**`, `**/schemas/**`, `**/types/**`
   - Config: `**/.env*`, `**/config/**`, `**/next.config*`, `**/vite.config*`

2. **Documentation scan** — Read these files if they exist:
   - `README.md`, `CLAUDE.md`, `docs/**/*.md`
   - `openapi.yaml`, `swagger.json`, API docs
   - Design docs in `docs/plans/`

3. **Recent changes** — `git log --oneline -20` to understand what was recently built

4. **Existing test coverage** — Glob for `**/*.test.*`, `**/*.spec.*`, `**/tests/**`, `**/__tests__/**`

5. **Running app detection** — Check if app is accessible:
   - Common ports: 3000, 3001, 5173, 8080, 8000, 4200
   - If Chrome MCP available, navigate and take screenshot

The output of this step is an internal context summary the agent keeps in working memory (not written to a file).

**Step 2: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat: add generate mode context gathering"
```

---

### Task 5: Write Generate Mode — Surface Discovery

**Files:**
- Modify: `skills/delphi/skill.md`

**Step 1: Write the Surface Discovery section**

Step 2 of Generate mode. From gathered context, the agent must:

1. **Enumerate surfaces** — Create a surface map:
   - UI surfaces: every route/page found, with expected functionality
   - API surfaces: every endpoint, with HTTP method and purpose
   - CLI surfaces: every command/subcommand
   - Background surfaces: cron jobs, webhooks, queue workers

2. **Group into flows** — Organize surfaces into logical user flows:
   - Each flow has a name (e.g., "authentication", "user-management", "checkout")
   - Each flow contains the surfaces that participate in it
   - A surface can belong to multiple flows

3. **Present the surface map** — The agent must show the user the discovered surfaces and flows before generating cases, asking: "I found these flows and surfaces. Should I generate guided cases for all of them, or focus on specific flows?"

This is a checkpoint — the user can scope down before generation begins.

**Step 2: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat: add generate mode surface discovery"
```

---

### Task 6: Write Generate Mode — Case Generation Matrix

**Files:**
- Modify: `skills/delphi/skill.md`

**Step 1: Write the Case Generation section**

Step 3 of Generate mode. This is the core. For each flow, the agent generates cases using this matrix:

**The Coverage Matrix** (include as a table in the skill):

| Dimension | What to Generate | Priority |
|-----------|-----------------|----------|
| Happy path | Standard successful flow end-to-end | P0 |
| Input validation | One case per validation rule per field | P1 |
| Boundary values | Empty, min, max, just-over-max for each input | P1 |
| Auth/permissions | Each role: authorized access + unauthorized denial | P0 |
| Error states | Network failure, server 500, timeout, 404 | P0 |
| State transitions | Back button, refresh, navigate away mid-flow, stale data | P1 |
| Empty states | No data, first-time user, cleared data | P1 |
| Accessibility | Keyboard-only navigation, focus order, aria labels | P2 |
| Concurrency | Double-click, duplicate submission, race conditions | P1 |
| Security | XSS in inputs, CSRF, session fixation, auth bypass | P0 |

**Case ID convention**: `GC-XXX` where XXX is a zero-padded sequential number. IDs are unique across the entire project.

**File naming convention**: `gc-XXX-short-description.md` in lowercase with hyphens.

**The agent MUST use the exact template from VISION.md** for every case. Include the complete template inline in the skill so the agent doesn't need to reference VISION.md.

**Step 2: Write the Priority Assignment rules**

Step 4 of Generate mode. Include the priority definitions:
- **P0**: Happy paths, auth/permission checks, security issues, critical error handling (crashes, data loss). These MUST work.
- **P1**: Input validation, boundary values, state transitions, concurrency, empty states. These SHOULD work.
- **P2**: Accessibility, cosmetic issues, rare edge cases. These are NICE to have.

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat: add case generation matrix and priority rules"
```

---

### Task 7: Write Generate Mode — Output & Index

**Files:**
- Modify: `skills/delphi/skill.md`

**Step 1: Write the Output section**

Step 5 of Generate mode. The agent must:

1. Create `tests/guided-cases/` directory
2. Create subdirectories per flow (lowercase, hyphenated)
3. Write each case as an individual `.md` file following naming convention
4. Generate `tests/guided-cases/index.md` with:
   - Title and generation date
   - Summary table linking every case (ID, Title, Type, Priority, Surface, Flow, Status)
   - Statistics summary (total, by priority, by type, by surface)

Include the exact index template in the skill.

**Step 2: Write the completion message**

After generation, the agent must report:
- Total cases generated, broken down by priority and type
- Directory location
- Suggest next steps: "Review the cases, then run `execute guided cases` to test them"

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat: add output structure and index generation"
```

---

## Phase 3: Write the Skill — Execute Mode

### Task 8: Write Execute Mode — Case Loading & Strategy

**Files:**
- Modify: `skills/delphi/skill.md`

**Step 1: Write Case Loading section**

Execute mode Step 1. The agent must:

1. Read `tests/guided-cases/index.md` to find all cases
2. Accept user filters:
   - By priority: "Execute P0 cases"
   - By type: "Execute negative cases"
   - By surface: "Execute UI cases"
   - By flow: "Execute auth cases"
   - By ID: "Execute GC-001 through GC-005"
   - All: "Execute all guided cases"
3. Parse each selected case file, extracting: metadata, preconditions, steps (with expected outcomes), success/failure criteria

**Step 2: Write Execution Strategy section**

Execute mode Step 2. Route each case to the right execution method:

| Surface | Method | Tools Used |
|---------|--------|------------|
| `ui` | Browser automation | Chrome MCP: `navigate`, `find`, `computer` (click/type/screenshot), `read_page`, `get_page_text` |
| `api` | HTTP requests | Bash: `curl -X METHOD url -H headers -d body` |
| `cli` | Shell commands | Bash: direct command execution, capture stdout/stderr/exit code |
| `background` | Inspection | Bash: log tailing, database queries, process checks |

If a case's surface is `ui` but no Chrome MCP is available, skip it and mark as "skipped: no browser access".

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat: add execute mode case loading and strategy"
```

---

### Task 9: Write Execute Mode — Execution & Reporting

**Files:**
- Modify: `skills/delphi/skill.md`

**Step 1: Write Step-by-Step Execution section**

Execute mode Step 3. For each case:

1. **Verify preconditions** — Check each precondition is met. If not, attempt setup or skip case.
2. **Execute each step**:
   - Perform the action described in the step
   - Capture evidence immediately after:
     - UI: screenshot via `computer screenshot`
     - API: full response body + status code
     - CLI: stdout + stderr + exit code
   - Compare actual outcome against each Expected item
   - Record: step number, action taken, expected, actual, pass/fail
3. **On step failure**: Record failure details, capture evidence, continue to next CASE (not next step in same case — a failed step means the case fails)
4. **On case completion**: Record overall pass/fail based on success criteria

**Step 2: Write Report Generation section**

Execute mode Step 4. Write report to `tests/guided-cases/reports/YYYY-MM-DD-HH-MM-report.md`.

Include the exact report template in the skill:
- Run metadata (date, time, filters, total cases)
- Results summary (passed count + %, failed count + %, skipped count + %)
- Failures section: each failed case with: failed step, expected, actual, evidence, severity
- Passed section: collapsed list of passed case IDs + titles
- Skipped section: each skipped case with reason

Also update `index.md`: set each executed case's Status to "passed"/"failed"/"skipped" and update Last Executed date.

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat: add execute mode step execution and reporting"
```

---

## Phase 4: Installation, README & Testing

### Task 10: Write README.md

**Files:**
- Create: `README.md`

**Step 1: Write README**

Include:
- Project name and one-line description
- Installation: `ln -s /path/to/delphi/skills/delphi ~/.claude/skills/delphi`
- Usage examples for both modes
- Pipeline integration snippet (pipelines.yaml config)
- Link to VISION.md for full scope
- Link to examples/ for format reference

Keep it concise — under 100 lines.

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with installation and usage"
```

---

### Task 11: Install and symlink the skill

**Files:**
- Symlink: `~/.claude/skills/delphi` → `/Users/divyekant/Projects/delphi/skills/delphi`

**Step 1: Create symlink**

```bash
ln -sf /Users/divyekant/Projects/delphi/skills/delphi /Users/divyekant/.claude/skills/delphi
```

**Step 2: Verify installation**

```bash
ls -la ~/.claude/skills/delphi/
cat ~/.claude/skills/delphi/skill.md | head -5
```

Expected: symlink pointing to project, skill.md readable with correct frontmatter.

**Step 3: Commit (no code change, just verification)**

No commit needed — this is an environment setup step.

---

### Task 12: Test Generate Mode against a real project

**Files:**
- No files created (this is a verification task)

**Step 1: Choose test target**

Use an existing project with UI + API surfaces. Good candidate: `/Users/divyekant/Projects/HiveBuild` (has Next.js pages, API routes, auth, dashboard — rich surfaces).

**Step 2: Invoke Delphi in a new Claude Code session**

In a NEW terminal/session (not this one), navigate to HiveBuild and invoke:
"Generate guided cases for this project"

**Step 3: Evaluate output**

Check that:
- [ ] Cases are written to `tests/guided-cases/`
- [ ] Index.md exists with summary table
- [ ] Cases follow the exact template (metadata, preconditions, steps, success/failure criteria)
- [ ] Both positive and negative cases exist
- [ ] Multiple surfaces covered (at least UI + API)
- [ ] Cases are specific enough for a human to follow without questions
- [ ] Cases are structured enough for an agent to parse
- [ ] P0/P1/P2 priorities are correctly assigned

**Step 4: Iterate on skill.md if output quality needs improvement**

If cases are:
- Too vague → strengthen the template instructions in the skill
- Missing surfaces → improve the glob patterns in context gathering
- Missing negative cases → strengthen the coverage matrix instructions
- Badly formatted → add stricter format enforcement

Each iteration: edit skill.md → re-test → verify improvement → commit.

---

### Task 13: Test Execute Mode against generated cases

**Files:**
- No files created (this is a verification task)

**Step 1: Ensure HiveBuild is running locally**

```bash
cd /Users/divyekant/Projects/HiveBuild && npm run dev
```

**Step 2: Invoke Delphi execute mode**

In a Claude Code session with Chrome MCP access:
"Execute P0 guided cases for this project"

**Step 3: Evaluate execution**

Check that:
- [ ] Cases are loaded from `tests/guided-cases/`
- [ ] UI cases use Chrome MCP for browser interaction
- [ ] Screenshots are captured as evidence
- [ ] API cases use curl/bash
- [ ] Report is generated in `tests/guided-cases/reports/`
- [ ] Report accurately reflects pass/fail status
- [ ] Failed cases have useful failure details
- [ ] Index.md is updated with execution status

**Step 4: Iterate on execute mode if needed**

Common issues:
- Agent doesn't capture screenshots → strengthen evidence capture instructions
- Agent stops on first failure → reinforce "continue to next case" instruction
- Report is incomplete → strengthen report template

---

## Phase 5: Pipeline Integration

### Task 14: Add Delphi to conductor pipelines.yaml

**Files:**
- Modify: `/Users/divyekant/Projects/skill-conductor/pipelines.yaml`

**Step 1: Add delphi skill to pipelines.yaml**

Add under `skills:`:
```yaml
delphi:
  source: external
  phase: verify
  type: phase
```

Add to `feature` and `complex` pipeline verify phases:
```yaml
verify:
  - verification-before-completion
  - delphi
```

**Step 2: Commit in skill-conductor repo**

```bash
cd /Users/divyekant/Projects/skill-conductor
git add pipelines.yaml
git commit -m "feat: add delphi to verify phase in feature and complex pipelines"
```

---

## Task Dependencies

```
Task 1 (scaffold) → Task 2 (examples)
Task 2 → Task 3 (frontmatter) → Task 4 (context) → Task 5 (surfaces) → Task 6 (matrix) → Task 7 (output)
Task 7 → Task 8 (execute loading) → Task 9 (execute reporting)
Task 9 → Task 10 (README) → Task 11 (install)
Task 11 → Task 12 (test generate) → Task 13 (test execute) → Task 14 (pipeline)
```

All tasks are sequential — each builds on the previous.

## Estimated Task Count

- **Phase 1 (Scaffold)**: Tasks 1-2
- **Phase 2 (Generate Mode)**: Tasks 3-7
- **Phase 3 (Execute Mode)**: Tasks 8-9
- **Phase 4 (Install & Test)**: Tasks 10-13
- **Phase 5 (Pipeline)**: Task 14
- **Total**: 14 tasks
