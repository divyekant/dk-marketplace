# Internal Document Templates

Templates for CS, Support, Engineering, and Product audiences.

**Voice:** Practical, direct, thorough. Third person ("The system does X") or instructional ("Check the config for Y"). Reader is technical enough to understand system behavior but may not know THIS specific feature. Accuracy over elegance.

---

## Feature Handoff

**File:** `docs/generated/internal/feature-handoffs/fh-{NNN}-{slug}.md`

~~~markdown
---
id: fh-{NNN}
type: feature-handoff
audience: internal
topic: {feature-name}
status: draft
generated: {date}
source-tier: {carto|direct|context}
context-files: [{list}]
hermes-version: 1.0.1
---

# Feature Handoff: {Feature Name}

## What It Does
{1-2 paragraph summary — what this feature enables, who uses it, when they use it}

## How It Works
{Technical explanation of the mechanism — components involved, data flow, key logic. Enough detail for L2 support to understand root causes, not just symptoms.}

## User-Facing Behavior
{What the end user sees and experiences:
- UI changes (new screens, modified flows, new buttons/options)
- API changes (new endpoints, changed responses, new parameters)
- Behavior changes (different defaults, new notifications, changed workflows)}

## Configuration
{Every config option, feature flag, or environment variable that affects this feature:
| Option | Type | Default | Effect |
|--------|------|---------|--------|
| ... | ... | ... | ... |}

## Edge Cases & Limitations
{Known limitations, boundary conditions, what it explicitly doesn't handle. Be specific:
- "Does NOT support batch operations over 1000 items"
- "Requires user to have admin role — other roles see a 403"}

## Common Questions
{Anticipated questions from CS/Support — the ones they'll get from customers:
**Q: {question}**
A: {answer}

Repeat for 3-5 most likely questions.}

## Troubleshooting
{Known error scenarios and diagnostic steps:
| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| ... | ... | ... |}

## Related
{Links to related feature handoffs, design docs, external docs}
~~~

---

## Release Notes

**File:** `docs/generated/internal/release-notes/rn-v{version}.md`

~~~markdown
---
id: rn-{version}
type: release-notes
audience: internal
version: {version}
status: draft
generated: {date}
commit-range: {from-hash}..{to-hash}
source-tier: {tier}
hermes-version: 1.0.1
---

# Internal Release Notes — v{version}

**Date:** {date}
**Commits:** {count} since v{previous-version}
**Contributors:** {list of commit authors}

## Summary
{2-3 sentence summary of what this release contains — lead with the most important change}

## Breaking Changes
{List each breaking change with:
- What changed
- Why it changed
- Migration steps (exact commands or code changes needed)
- Who is affected (which teams, which customers, which integrations)}

## New Features
{For each new feature:
### {Feature Name}
- **What:** {1-sentence description}
- **How:** {brief technical explanation}
- **Config:** {new config options or feature flags}
- **Who it affects:** {which user segments, teams, or workflows}
- **CS Notes:** {what CS/Support needs to know that's different from the external changelog}}

## Improvements
{Enhancements to existing features — same structure as new features but briefer}

## Bug Fixes
{For each fix:
- **Symptom:** {what users were experiencing}
- **Root Cause:** {what was wrong}
- **Resolution:** {what was fixed}
- **Tickets:** {related ticket IDs if available}}

## Configuration Changes
{Table of new, changed, or removed config options:
| Option | Change | Old Value | New Value | Notes |
|--------|--------|-----------|-----------|-------|
| ... | added/changed/removed | ... | ... | ... |}

## Known Issues
{Issues shipping with this release — be honest:
- {issue description} — workaround: {workaround if any}}

## Internal Notes
{Anything not in the above that internal teams need to know — deployment notes, rollout plan, feature flag states}
~~~

---

## Use Case Docs

**File:** `docs/generated/internal/use-cases/uc-{NNN}-{slug}.md`

~~~markdown
---
id: uc-{NNN}
type: use-case
audience: internal
topic: {scenario-name}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# Use Case: {Scenario Title}

## Trigger
{What initiates this scenario — user action, system event, scheduled task, API call}

## Preconditions
{What must be true before this scenario can occur:
- User must be authenticated
- Feature flag X must be enabled
- Data must exist in Y}

## Flow
{Step-by-step description of what happens — from the user's perspective AND the system's:
1. **User does:** {action}
   **System does:** {response}
2. **User sees:** {result}
   **System does:** {background processing}}

## Variations
{Alternative paths through this scenario:
- **If {condition}:** {different behavior}
- **If {error condition}:** {error handling behavior}}

## Edge Cases
{Boundary conditions and unusual situations:
- {edge case}: {what happens}
- {edge case}: {what happens}}

## Data Impact
{What data is created, modified, or deleted during this flow:
| Data | Action | Location |
|------|--------|----------|
| ... | created/updated/deleted | ... |}

## CS Notes
{Specific guidance for customer-facing teams:
- Common customer confusion points
- How to explain this to non-technical users
- Workarounds for known limitations}
~~~

---

## FAQ

**File:** `docs/generated/internal/faq.md`

~~~markdown
---
type: faq
audience: internal
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# Internal FAQ

{Organized by topic area. Each entry follows this format:}

## {Topic Area}

### Q: {Question — phrased as a customer or internal team member would ask it}
**A:** {Answer — direct, specific, actionable. Include:
- The factual answer
- Any caveats or exceptions
- Where to find more detail (link to feature handoff or use case doc)
- Escalation path if the answer doesn't resolve the issue}

**Related:** [{link to feature handoff}] [{link to use case doc}]
~~~

**Generation rules for FAQ:**
1. Mine questions from: feature handoff "Common Questions" sections, use case "CS Notes", troubleshooting guides
2. Add questions derived from feature limitations and edge cases
3. Group by topic area (one per feature/domain)
4. Minimum 3 questions per topic area
5. Every answer must be actionable — never "it depends" without specifics
6. Cross-link to source docs

---

## Troubleshooting Guide

**File:** `docs/generated/internal/troubleshooting/ts-{NNN}-{slug}.md`

~~~markdown
---
id: ts-{NNN}
type: troubleshooting
audience: internal
topic: {symptom-area}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# Troubleshooting: {Symptom Area}

## Symptoms
{Observable symptoms that indicate this problem — what the user sees or reports:
- "{exact error message or behavior}"
- "{visible symptom in UI/API/CLI}"}

## Quick Check
{First thing to verify — the most common cause:
1. Check {X} — if {condition}, that's the issue. Fix: {resolution}.
2. If not, proceed to diagnostic steps.}

## Diagnostic Steps
{Decision tree for isolating the root cause:

### Step 1: {Check}
- **Run:** {command or action}
- **If {result A}:** → {conclusion or next step}
- **If {result B}:** → {conclusion or next step}

### Step 2: {Next check}
- **Run:** {command or action}
- **If {result A}:** → Root cause is {X}. See Resolution below.
- **If {result B}:** → Escalate to {team} with {required info}.}

## Resolutions
{For each identified root cause:
### {Root Cause}
- **Fix:** {exact steps to resolve}
- **Verify:** {how to confirm the fix worked}
- **Prevent:** {how to prevent recurrence, if applicable}}

## Escalation
{When to escalate and what info to provide:
- **Escalate to:** {team or person}
- **Include:** {required diagnostic data}
- **SLA:** {expected response time}}

## Related
{Links to relevant feature handoffs, use cases, and error references}
~~~

**Generation rules for troubleshooting:**
1. Derive symptoms from error handling code, known error messages, and exception types
2. Structure as decision trees — symptom → diagnosis → resolution
3. Always start with the most common cause (quick check)
4. Include exact commands and expected output at each diagnostic step
5. Every path must terminate in either a resolution or an escalation

---

## Glossary

**File:** `docs/generated/internal/glossary.md`

~~~markdown
---
type: glossary
audience: internal
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# Glossary

{Alphabetically ordered. Each term follows this format:}

### {Term}
**Definition:** {Clear, concise definition — 1-2 sentences}
**Context:** {Where this term is used — which features, APIs, or UI elements}
**Also known as:** {Aliases, abbreviations, or alternative names — if any}
**Not to be confused with:** {Similar terms that mean different things — if any}
~~~

**Generation rules for glossary:**
1. Extract terms from: code identifiers (models, types, enums), API parameter names, config keys, UI labels
2. Include domain-specific terms that non-engineers might not know
3. Include terms that are used differently in this project than their common meaning
4. Alphabetical order, no exceptions
5. Keep definitions under 2 sentences — link to feature docs for detail
