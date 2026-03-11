# Argos Confidence-Driven Triage Model

**Date:** 2026-03-07
**Status:** Approved
**Supersedes:** Action-based tier system (auto/approve/deny)

## Problem

Three issues with the current Argos autonomy model:

1. **Code guardrails are mechanical, not intelligent.** The action-based tiers (auto/approve/deny) gate actions by type (e.g., "commits always need approval"), not by risk. A typo fix in a README gets the same oversight as a change to auth logic. Meanwhile, anyone can raise an issue and steer Claude Code to investigate or fix arbitrary parts of the codebase.

2. **Notification content is audience-unaware.** All adapters receive the same payload. A GitHub comment on a public issue exposes the same internal details (file paths, code snippets, architecture reasoning) as a private system notification.

3. **`/watch` doesn't start the loop.** After onboarding, the user must manually copy-paste a `/loop` command that the watch flow already has all the information to execute.

## Solution Overview

Replace the action-based tier system with a **5-level confidence model** where the AI evaluates each issue holistically and assigns an oversight level based on its understanding of the code, the change, and the risk. Policy shifts from routing actions to setting **floors and constraints** the AI must respect.

---

## 1. The 5-Level Confidence Model

Every issue that passes filtering gets evaluated by the AI against available context (project files, Carto if present, Memories). The AI assigns one of five levels:

### Level Definitions

**Level 1 -- Should Fix**

Argos is highly confident. The issue is clear, the fix is isolated, low-risk, and consistent with existing patterns. Argos fixes it end-to-end autonomously.

Examples: typo in docs, missing null check obvious from stack trace, broken link, trivial test fix.

**Level 2 -- Fix + Summary Review**

Argos is confident but the change is non-trivial enough that a human should glance at it. Argos fixes it, opens a PR, and sends a concise summary. The human reviews the summary, not the full diff.

Examples: bug fix touching 2-3 files in a well-understood module, adding missing validation that follows established patterns.

**Level 3 -- Fix + Thorough Review**

Argos can fix it but the change has meaningful risk -- touches sensitive areas, crosses module boundaries, or the AI's confidence isn't 100%. Argos prepares the fix but the PR is explicitly marked "needs thorough review" with full diff context.

Examples: fixing a race condition, changes to API contracts, fixes touching auth or payment logic, multi-file refactors.

**Level 4 -- Needs Human Approval**

Argos understands the issue but shouldn't act without explicit go-ahead. It investigates, writes up a summary with its analysis and recommendation, and waits. The human decides whether to proceed, adjust the approach, or dismiss.

Examples: enhancement requests that expand product surface area, issues from untrusted authors proposing code changes, architectural changes, anything where the AI isn't sure of the right fix.

**Level 5 -- Can't Touch**

Beyond Argos's scope. It labels the issue, posts a minimal acknowledgment, and flags it for human attention. No investigation, no fix attempt.

Examples: requests to redesign core architecture, issues requiring external service changes, policy/legal questions, issues the AI fundamentally doesn't understand.

### Signals That Determine the Level

The AI considers these signals as a judgment call informed by context, not a formula:

| Signal | Pushes Toward Level 1 | Pushes Toward Level 5 |
|--------|----------------------|----------------------|
| Blast radius | 1-2 files, isolated | Cross-cutting, many modules |
| Sensitivity | Docs, tests, UI text | Auth, payments, infra, config |
| AI confidence | Clear root cause, obvious fix | Uncertain, multiple possible causes |
| Complexity | One-liner, pattern-matched | Multi-step, novel logic |
| Author trust | Known contributor, clear report | First-time poster, vague description |
| Precedent | Similar fix succeeded before (Memories) | No precedent, or past similar fix was rejected |
| Product fit | Clearly within scope (from docs/Carto) | Outside product boundaries or current roadmap |
| Issue type | Bug with repro steps | Enhancement expanding surface area |

---

## 2. Context Stack

For the AI to make good level assignments, it needs project understanding. Context comes from three layers:

### Layer 1 -- Project Files (always available)

Read on every invocation. Zero setup cost.

- `CLAUDE.md` -- project conventions, priorities, constraints
- `README.md` -- what the product does, its scope
- `docs/` -- architecture docs, decision records, plans
- `.apollo.yaml` -- project preferences if Apollo-managed

The SKILL.md instructs Argos to read these before classifying any issue. This is the baseline.

### Layer 2 -- Carto (when available)

If the codebase has been indexed by Carto, Argos gets structured understanding:

- Module boundaries -- which directories/files form coherent units
- Dependency graph -- what depends on what, blast radius estimation
- Conventions -- naming patterns, error handling approaches
- Sensitive areas -- auto-detected based on module names, imports (auth, crypto, payment, etc.)

Argos checks for Carto data by looking for Carto's output files or querying the Carto MCP if available. If not present, falls back to Layer 1. No hard dependency.

### Layer 3 -- Memories (builds over time)

Argos searches Memories before every triage decision:

- Past triage outcomes -- "last time a similar issue came in, I assigned level 3 and the human approved"
- Rejection patterns -- "human rejected my fix for auth-related issues twice, escalate auth issues to level 4+"
- Recurring issues -- "3rd pagination bug this month, note the pattern"
- Product boundary learnings -- "human said 'dark mode is out of scope', remember for future enhancement requests"

Cold start: Argos starts conservative (defaults toward higher levels). As it accumulates decisions and feedback, it calibrates.

### How They Combine

```
Issue arrives
  -> Read project files (Layer 1)            -- always
  -> Check Carto for module context (Layer 2) -- if available
  -> Search Memories for precedent (Layer 3)  -- if any exist
  -> AI synthesizes all signals -> assigns level
```

No single layer overrides the others -- the AI weighs them together. Policy floors (next section) can force minimum levels regardless of AI judgment.

---

## 3. Policy Redesign

The policy YAML shifts from routing actions to tiers to setting constraints and overrides. The AI makes the judgment call, the policy sets the guardrails.

### New Policy Structure

```yaml
repo: "owner/repo"
poll_interval: 5m

# -- Floors: minimum level for matching conditions --
floors:
  # By path -- any fix touching these paths can't go below this level
  paths:
    "src/auth/**": 3
    "src/payments/**": 4
    "config/production.*": 5
    ".env*": 5
    "*.pem": 5
    "*.key": 5

  # By issue type
  types:
    enhancement: 4
    question: 5

  # By author trust
  authors:
    trusted: []              # GitHub usernames -- no floor override (AI decides)
    unknown: 4               # First-time / unknown authors floor at level 4

  # Blanket floor -- nothing ever goes below this
  minimum: 2

# -- Hard denials: things Argos can never do regardless of level --
deny:
  actions:
    - close_issue
    - merge_pr
    - force_push
    - delete_branch
  paths:
    - ".env*"
    - "*.secret"
    - "*.pem"
    - "*.key"
    - "config/production.*"

# -- Guardrails: hard limits --
guardrails:
  max_actions_per_hour: 10
  max_open_prs: 3
  require_tests: true
  max_files_changed: 10
  dry_run: false

# -- Filters: what issues to process --
filters:
  labels: ["bug", "enhancement", "help-wanted"]
  ignore_labels: ["wontfix", "on-hold", "discussion"]
  only_new: true
  max_age: 7d

# -- Notifications --
notifications:
  channels:
    - name: github_comment
      type: external
    - name: system
      type: internal
    - name: session
      type: internal
```

### Key Changes from Current Policy

| Before | After |
|--------|-------|
| `actions.auto: [label, comment]` | Removed -- AI decides based on assigned level |
| `actions.approve: [commit, pr]` | Replaced by `floors` -- constraints on minimum level |
| `actions.deny: [close, merge]` | Kept as `deny.actions` -- hard blocks |
| `approval_modes: {wait, timeout}` | Removed -- levels 2-4 define review mode implicitly |
| `protected_paths` under guardrails | Split into `deny.paths` (never touch) and `floors.paths` (elevated oversight) |

### How Floors Work

The AI assigns a level based on its judgment. Then policy floors are checked. Floors can only escalate, never lower.

```
AI assigns level 1 ("should fix")
  -> Fix touches src/auth/login.js
  -> floors.paths says "src/auth/**": 3
  -> Level escalated to 3 ("fix + thorough review")
```

```
AI assigns level 2 ("fix + summary review")
  -> Issue is an enhancement
  -> floors.types says enhancement: 4
  -> Level escalated to 4 ("needs human approval")
```

```
AI assigns level 3
  -> Author is first-time contributor
  -> floors.authors.unknown: 4
  -> Level escalated to 4
```

The `minimum: 2` means Argos never fully auto-ships anything without at least a summary review. Users can lower to 1 if they trust Argos enough.

### The Deny Section

Hard blocks that no level can override:

- `deny.actions` -- these actions are never taken, period
- `deny.paths` -- these files are never modified, period

If a fix would require touching a denied path, the issue is automatically escalated to level 5 ("can't touch").

---

## 4. Notification Content by Audience

Each notification channel is tagged as `internal` or `external`. The AI generates two different content blocks for every notification.

### External Notifications (e.g., GitHub comments)

Visible to anyone who can see the issue. Content is sanitized and minimal:

- Classification and current status
- What's happening next (high level)
- No internal file paths, no code snippets, no architecture details
- No mention of confidence levels or internal reasoning

Level-specific external content:

| Level | GitHub Comment |
|-------|--------------|
| 1 | "Triaged as `bug`. Fix incoming -- see PR #X." |
| 2 | "Triaged as `bug`. Fix proposed, under review." |
| 3 | "Triaged as `bug`. Investigating, fix under review." |
| 4 | "Triaged as `enhancement`. Under evaluation." |
| 5 | "Noted. This needs human attention -- someone from the team will follow up." |

### Internal Notifications (system, session, Memories)

Only visible to the developer. Full and detailed:

- Assigned level and reasoning ("Level 3: fix touches auth module, crosses 2 module boundaries")
- Root cause analysis with file paths and line numbers
- Affected files and blast radius
- Confidence assessment ("high confidence -- exact same pattern fixed in #38")
- Precedent from Memories if any
- For levels 2-4: the summary or diff the human needs to review
- Recommended action

### Adapter Interface Change

The adapter receives structured content with an audience tag instead of a single `details` string:

```
notify(event, repo, issue, title, action, content, channels)
                                          |
                              +-----------+-----------+
                              |                       |
                        content.external        content.internal
                        (sanitized)             (full details)
```

Each adapter reads the content field matching its `type` from the policy. The `build_payload` function in `notify.sh` generates both versions. Adapters pick the right one.

### What the AI Generates

In the SKILL.md workflow, after assigning a level the AI produces two content blocks:

1. **External summary** -- 1-2 sentences, no internal details, safe for public
2. **Internal summary** -- full analysis, file paths, reasoning, recommendation

Both attach to the notification payload. The adapter selects based on its type.

---

## 5. Auto-Start Loop from `/watch`

### Current Behavior

After onboarding, the watch command prints instructions for the user to manually run `/loop`.

### New Behavior

After the user confirms, the watch command directly invokes the Skill tool to start the loop:

```
Invoke Skill: loop
Args: "<poll_interval> invoke the argos skill for <owner/repo>"
```

The watch command already has both values. No reason to make the user do it.

### Re-watch Handling

If the user runs `/watch owner/repo` on a repo that already has a policy file, Argos asks:

> "You're already watching `owner/repo` (every 5m). What would you like to do?"
>
> 1. Update policy -- re-run onboarding to change settings
> 2. Change interval -- keep policy, adjust poll frequency
> 3. Restart loop -- same settings, fresh start

Then acts accordingly. If policy changes affect the interval, restart the loop with the new value.

### `/unwatch` Symmetry

`/unwatch` still notes that the polling loop must be stopped manually (CC doesn't have a `/loop stop` API yet). It clearly states: "The polling loop is still running -- stop it manually. Your policy and state have been cleaned up."

---

## Migration Path

The current action-based policy files need to be migrated. The onboarding flow in `/watch` will be updated to generate the new format. Existing policy files can be migrated by:

1. Mapping `actions.auto` actions to a low `minimum` floor (1-2)
2. Mapping `actions.approve` to `floors` entries based on action type
3. Carrying `actions.deny` directly to `deny.actions`
4. Carrying `guardrails.protected_paths` to `deny.paths` and `floors.paths`
5. Converting notification channels to include `type: internal/external`

The old `approval_modes` section is dropped entirely -- the level system replaces it.
