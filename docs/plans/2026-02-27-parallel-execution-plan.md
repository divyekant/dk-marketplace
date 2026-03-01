# Parallel Execution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add parallel subagent dispatch to Delphi's execute mode so non-UI flows run concurrently.

**Architecture:** Mirror the generate mode's parallel dispatch pattern. Classify flows into parallel (no UI cases) and sequential (has UI cases) buckets. Dispatch one subagent per parallel flow. Run UI flows sequentially on the shared browser. Each subagent writes a `.report-fragment.md`; main agent merges fragments into the final report.

**Tech Stack:** Markdown skill file (no runtime code). All changes go to `skills/delphi/skill.md`.

**Design doc:** `docs/plans/2026-02-27-parallel-execution-design.md`

---

### Task 1: Add flow classification to Execute Mode Step 2

**Files:**
- Modify: `skills/delphi/skill.md:442-458` (Execute Mode Step 2)

**Step 1: Add flow classification section after the capability check**

After the existing "Tell the user how many cases will be executed" line (line 458), insert a new section. The full replacement for Step 2 (lines 442-458) should read:

```markdown
### Step 2: Choose Execution Strategy

Route each case to the right execution method based on its Surface metadata:

| Surface | Execution Method | Tools |
|---------|-----------------|-------|
| `ui` | Browser automation | Chrome MCP: `navigate`, `find`, `computer` (click, type, screenshot), `read_page`, `get_page_text` |
| `api` | HTTP requests | Bash: `curl -s -X METHOD URL -H "header" -d 'body'` |
| `cli` | Shell commands | Bash: direct command execution, capture stdout + stderr + exit code |
| `background` | Inspection | Bash: log tailing (`tail`), database queries, process checks (`ps`, `curl` health endpoints) |

**Capability check before starting:**
- If Surface is `ui` and Chrome MCP tools are NOT available: mark case as **skipped** with reason "No browser access"
- If Surface is `api` and the app is not running: mark case as **skipped** with reason "App not running"
- If Surface is `cli` and the command is not installed: mark case as **skipped** with reason "Command not found"

**Classify flows for parallel vs. sequential execution:**

Scan all non-skipped cases and bucket their flows:

| Bucket | Criteria | Execution |
|--------|----------|-----------|
| **Parallel** | Flow has ZERO `ui` surface cases in the execution list | One subagent per flow, all dispatched concurrently |
| **Sequential** | Flow has ANY `ui` surface case in the execution list | Run one flow at a time on the shared browser |

Mixed flows (both UI and non-UI cases) go to the **sequential** bucket — do not split a flow across strategies.

Tell the user:
- How many cases will be executed and how many skipped
- How many flows will run in parallel vs. sequentially
- Which flows are in each bucket
```

**Step 2: Verify the edit is clean**

Read `skills/delphi/skill.md` lines 442-475 and confirm Step 2 ends before Step 3 begins, with the new classification section included.

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat(execute): add flow classification for parallel vs sequential dispatch

Adds a flow classification step to Execute Mode Step 2 that buckets flows
into parallel (no UI cases) and sequential (has UI cases) for dispatch.
Mirrors the generate mode pattern."
```

---

### Task 2: Rewrite Execute Mode Step 3 with parallel dispatch

**Files:**
- Modify: `skills/delphi/skill.md:460-518` (Execute Mode Step 3)

**Step 1: Replace Step 3 with parallel dispatch architecture**

Replace everything from line 460 (`### Step 3: Execute Cases`) through line 518 (`- Final determination: PASS or FAIL`) with:

```markdown
### Step 3: Execute Cases

**Parallel dispatch for non-UI flows, sequential for UI flows.**

Collect all flows from the classification in Step 2.

**Parallel dispatch (preferred — use when the Agent tool is available):**

Before dispatching, update `.discovery.md` execute progress to mark parallel flows as `in_progress`.

Dispatch one subagent per parallel flow using the Agent tool. Each subagent receives:
1. Flow name and all case files for that flow (full markdown content — subagents cannot read the skill file)
2. The execution instructions for steps 3a-3c below (copy them into the subagent prompt)
3. The surface-to-tool mapping table from Step 2
4. Evidence output path: `tests/guided-cases/evidence/`
5. Fragment output path: `tests/guided-cases/[flow-name]/.report-fragment.md`

Each subagent:
1. Executes all cases for its flow in priority order (P0 → P1 → P2) using steps 3a-3c
2. Writes evidence files to `tests/guided-cases/evidence/gc-XXX/`
3. Writes a `.report-fragment.md` in the flow directory with per-case results
4. **MUST NOT write to the main report file, `.discovery.md`, or `index.md`** — these are owned by the main agent

**Important for subagent prompts:** Include the COMPLETE execution instructions (steps 3a-3c), surface-to-tool mapping, and evidence capture rules in each subagent's prompt. Subagents do NOT have access to the skill file — they need everything inline.

**Sequential execution for UI flows (runs concurrently with parallel dispatch):**

While parallel subagents are running, the main agent executes UI flows one at a time on the shared browser:
1. Select next UI flow
2. Execute all cases in priority order (P0 → P1 → P2) using steps 3a-3c
3. Write `.report-fragment.md` in the flow directory
4. Write evidence to `tests/guided-cases/evidence/gc-XXX/`
5. Move to next UI flow

**Sequential fallback (when Agent tool is unavailable or only 1-2 total flows):**

Execute all flows sequentially, one flow at a time, all cases in priority order. Write results directly to the report file (no fragments needed). This is the pre-parallel behavior.

**If context is lost mid-execution:** Next invocation reads the report + any `.report-fragment.md` files, identifies which cases have results, and picks up from the next unrecorded case. Partial fragments from crashed subagents are preserved.

For each case (used by both subagents and main agent), in order:

**3a. Verify Preconditions**
- Check each precondition listed in the case
- If a precondition is not met and CAN be set up (e.g., "navigate to login page"), do it
- If a precondition is not met and CANNOT be set up (e.g., "user account exists"), mark case as **skipped** with reason

**3b. Execute Each Step**

For each numbered step in the case:

1. **Perform the action** described in the step:
   - UI: Use Chrome MCP tools — `navigate` for URLs, `find` to locate elements, `computer` for click/type, `form_input` for form fields
   - API: Use `curl` via Bash with exact endpoint, method, headers, body from the step
   - CLI: Run the command via Bash
   - Background: Check logs, query database, inspect process state

2. **Capture evidence immediately after the action:**
   - Create evidence directory: `tests/guided-cases/evidence/gc-XXX/`
   - UI: Take screenshot, save as `tests/guided-cases/evidence/gc-XXX/step-N.png`
   - API: Save full response to `tests/guided-cases/evidence/gc-XXX/step-N-response.json`
   - CLI: Save output to `tests/guided-cases/evidence/gc-XXX/step-N-output.txt`
   - Background: Save log lines to `tests/guided-cases/evidence/gc-XXX/step-N-logs.txt`
   - **Never embed evidence content in the report** — reference by path only

3. **Verify expected outcomes:**
   - Compare actual result against EACH "Expected" item in the step
   - For UI: Use `read_page`, `find`, `get_page_text`, or screenshot inspection to verify visible state
   - For API: Check status code, response body fields, headers
   - For CLI: Check output text, exit code
   - Record: PASS if all expected outcomes match, FAIL if any do not

4. **On step failure:**
   - Record which expected outcome failed
   - Record actual vs. expected
   - Capture evidence of the failure
   - **Stop executing this case** — mark it as FAILED at this step
   - **Continue to the next case** (do NOT abort the entire run)

**3c. On Case Completion**
- If all steps passed: mark case as **passed**
- Check success criteria — all must be true
- Check failure criteria — none must be true
- Final determination: PASS or FAIL
```

**Step 2: Verify the edit is clean**

Read `skills/delphi/skill.md` lines 460-530 and confirm Step 3 flows correctly from the classification in Step 2 and ends before Step 4 (Report).

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat(execute): add parallel subagent dispatch to execute mode

Rewrites Execute Mode Step 3 to dispatch one subagent per non-UI flow
concurrently while running UI flows sequentially on the shared browser.
Each subagent writes a .report-fragment.md; main agent merges after.
Includes sequential fallback for when Agent tool is unavailable."
```

---

### Task 3: Update Execute Mode Step 4 (Report) for fragment merge

**Files:**
- Modify: `skills/delphi/skill.md` — the Step 4 Report section (starts at line 520 in original, will shift after Task 2)

**Step 1: Replace Step 4 with fragment-aware reporting**

Replace the current Step 4 section with:

```markdown
### Step 4: Report (Merge + Finalize)

**If parallel dispatch was used:** Merge fragments before writing the final report.

1. Wait for all subagents to complete
2. Read all `.report-fragment.md` files from `tests/guided-cases/[flow-name]/`
3. Combine with results from sequentially-executed UI flows
4. Write the merged report to `tests/guided-cases/reports/YYYY-MM-DD-HH-MM-report.md`
5. Compute aggregate stats (passed/failed/skipped counts + percentages)
6. Clean up `.report-fragment.md` files

**If sequential fallback was used:** The report was written incrementally during Step 3. Just add the summary section.

**Report fragment format** (written by each subagent):

~~~markdown
## [Flow Name] Results

| ID | Title | Result | Failed Step | Evidence |
|----|-------|--------|-------------|----------|
| GC-XXX | Title | passed/failed/skipped | N/A or step N | `evidence/gc-XXX/` |
~~~

**Final report file:** `tests/guided-cases/reports/YYYY-MM-DD-HH-MM-report.md`

Report format:

~~~markdown
# Delphi Execution Report

**Run**: YYYY-MM-DD HH:MM
**Cases Executed**: X of Y total
**Filters**: [filters applied, or "none"]
**Execution**: [parallel (N flows) + sequential (M UI flows) | sequential only]

## Results
- **Passed**: X (XX%)
- **Failed**: X (XX%)
- **Skipped**: X (XX%)

## Failures

### GC-XXX: [Case Title]
- **Failed at Step**: N
- **Expected**: [what should have happened]
- **Actual**: [what actually happened]
- **Evidence**: [path to evidence file, e.g., `evidence/gc-XXX/step-N.png`]
- **Severity**: [P0/P1/P2 from case metadata]

[repeat for each failed case]

## Skipped

| ID | Title | Reason |
|----|-------|--------|
| GC-XXX | Title | No browser access |

## Passed

<details>
<summary>X cases passed (click to expand)</summary>

| ID | Title |
|----|-------|
| GC-001 | Login happy path |
| GC-004 | Dashboard loads |

</details>
~~~

**After writing the report:**

1. Update `tests/guided-cases/index.md` — set each executed case's Status column to `passed`, `failed`, or `skipped`, and update the Last Executed date in each case's metadata
2. Update `.discovery.md` execute progress counts
3. Report summary to user:

> **Delphi Execution Report**
> - Passed: X | Failed: X | Skipped: X
> - Execution: [N flows parallel + M UI flows sequential | sequential only]
> - Report saved to `tests/guided-cases/reports/YYYY-MM-DD-HH-MM-report.md`
> - [If failures] X failures need attention — check the report for details.
```

**Step 2: Verify the edit is clean**

Read the full Step 4 section and confirm it references fragment files correctly and the report format includes the new `Execution` metadata line.

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat(execute): update report step for fragment merge

Updates Execute Mode Step 4 to merge .report-fragment.md files from
parallel subagents into the final report. Adds execution metadata line
showing parallel vs sequential breakdown. Includes report fragment
format specification for subagents."
```

---

### Task 4: Update Resume Protocol for parallel execution

**Files:**
- Modify: `skills/delphi/skill.md:52-88` (Resume Protocol section)

**Step 1: Update the execute resume path to handle fragments**

In the Resume Protocol section, the current "On resume (execute)" text at lines 85-86 reads:

```
**On resume (execute):** Read `.discovery.md` and existing report file, identify cases not yet recorded in the report, skip to Execute Mode Step 3 for the next unrecorded case.
```

Replace with:

```
**On resume (execute):** Read `.discovery.md` and existing report file. Also scan for any `.report-fragment.md` files in flow directories — these indicate partial parallel execution. Merge fragment results with the main report to build the complete list of already-completed cases. Skip to Execute Mode Step 2 (to re-classify remaining flows) then Step 3 for unrecorded cases only.
```

**Step 2: Verify the edit is clean**

Read lines 52-88 and confirm the resume protocol correctly references fragment files.

**Step 3: Commit**

```bash
git add skills/delphi/skill.md
git commit -m "feat(execute): update resume protocol for parallel fragment handling

Resume now scans for .report-fragment.md files from partial parallel
runs, merges them with the main report to avoid re-executing completed
cases."
```

---

### Task 5: Copy updated skill to installed location + final verification

**Files:**
- Source: `skills/delphi/skill.md`
- Destination: `~/.claude/skills/delphi/skill.md`

**Step 1: Copy the updated skill file**

```bash
cp skills/delphi/skill.md ~/.claude/skills/delphi/skill.md
```

**Step 2: Verify the full skill reads correctly end-to-end**

Read the complete `skills/delphi/skill.md` and verify:
- Step 2 has flow classification section
- Step 3 has parallel dispatch + sequential UI + sequential fallback
- Step 4 has fragment merge + updated report format
- Resume Protocol references fragments
- No broken markdown, no orphaned sections

**Step 3: Final commit with all changes**

```bash
git add skills/delphi/skill.md
git commit -m "chore: copy updated skill to installed location"
```
