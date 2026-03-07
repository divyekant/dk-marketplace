# Argos Design Document

> **Date:** 2026-03-06
> **Status:** Approved
> **Project:** Argos — The All-Seeing Issue Guardian
> **Type:** Claude Code Plugin

---

## 1. Problem Statement

Development teams need proactive, autonomous issue monitoring with configurable boundaries. Existing solutions (GitHub Agentic Workflows, claude-code-action, Copilot Coding Agent) are server-side, reactive, and lack user-defined tiered autonomy.

Argos fills the gap: a local-first CC plugin that watches GitHub repos for new issues and acts on them within explicitly configured boundaries — leveraging the full CC ecosystem (skills, hooks, memories, MCP servers, local codebase).

## 2. Value Proposition

- **Local-first** — code never leaves your machine, full visibility into every action
- **Rich context** — access to local codebase, MCP servers, skills, and memories
- **Personal workflow** — integrates with existing CC setup (Apollo, Hermes, Delphi, etc.)
- **Tiered autonomy** — auto/approve/deny per action type, configurable approval modes
- **Learns over time** — Memories MCP persists patterns, decisions, and outcomes across sessions

## 3. Architecture

### 3.1 Overview

Argos is a pure CC plugin. It uses `/loop` as the scheduler, `gh` CLI for GitHub API, CC's agent capabilities for investigation and code changes, and pluggable adapters for notifications.

```
/watch owner/repo
    |
    v
/loop 5m "invoke argos skill for owner/repo"
    |
    v  (every 5 minutes)
poll.sh → "any new issues?" (bash, no LLM cost)
    |
    +→ NO  → sleep (zero tokens)
    +→ YES → invoke SKILL.md with issue data
                |
                v
           Read policy YAML
                |
                v
           For each new issue:
             - Classify (bug/enhancement/duplicate)
             - Check policy tier (auto/approve/deny)
             - auto   → execute immediately, notify
             - approve → log pending, notify, wait
             - deny   → skip
                |
                v
           Update state + memories
```

### 3.2 Plugin Structure

```
argos/
  .claude-plugin/
    plugin.json              # Plugin manifest
  commands/
    watch.md                 # /watch owner/repo — start watching
    unwatch.md               # /unwatch owner/repo — stop watching
    argos-status.md          # /argos-status — show watches & pending approvals
    argos-approve.md         # /argos-approve #42 — approve/reject pending action
  hooks/
    hooks.json               # Hook definitions
    session-start.sh         # Inject pending approvals on session start
  skills/
    argos/
      SKILL.md               # Core skill — triage, investigate, act
  lib/
    poll.sh                  # Fetch new issues via gh CLI
    state.sh                 # State management (seen issues, pending approvals)
    notify.sh                # Notification dispatcher
    adapters/
      github-comment.sh      # Post comment on issue
      system.sh              # macOS native notification
      session.sh             # Inject into CC session context
  config/
    default-policy.yaml      # Default boundary policy template
  README.md
```

## 4. Policy & Boundaries

The policy file is the core of Argos. One file per watched repo, stored at `~/.claude/argos/policies/<owner>-<repo>.yaml`.

### 4.1 Action Tiers

```yaml
repo: owner/repo
poll_interval: 5m

actions:
  # Execute immediately, no approval needed
  auto:
    - label
    - comment_triage
    - assign
    - close_duplicate

  # Notify and wait for approval before executing
  approve:
    - comment_diagnosis
    - create_branch
    - push_commits
    - open_pr

  # Never performed, regardless of context
  deny:
    - close_issue
    - merge_pr
    - force_push
    - delete_branch
```

Actions not listed in any tier are implicitly denied.

### 4.2 Approval Modes

Per-action approval behavior:

```yaml
approval_modes:
  comment_diagnosis:
    mode: timeout        # auto-skip after timeout (no action taken)
    timeout: 2h
  create_branch:
    mode: default        # auto-proceed after timeout (opt-out)
    timeout: 4h
  push_commits:
    mode: wait           # block until explicit approval
  open_pr:
    mode: wait
```

Three modes:
- **wait** — pauses until explicit approval via `/argos-approve`
- **timeout** — skips the action if no response within the window
- **default** — proceeds with the action if no rejection within the window

### 4.3 Issue Filters

```yaml
filters:
  labels: ["bug", "enhancement", "help-wanted"]
  ignore_labels: ["wontfix", "on-hold", "discussion"]
  only_new: true
  max_age: 7d
```

### 4.4 Guardrails

Hard limits that apply regardless of tier or approval:

```yaml
guardrails:
  max_actions_per_hour: 10
  max_open_prs: 3
  require_tests: true
  max_files_changed: 10
  protected_paths:
    - ".env*"
    - "*.secret"
    - "config/production.*"
  dry_run: false
```

## 5. Notification System

### 5.1 Pluggable Adapters

Each adapter is a shell script in `lib/adapters/` that receives a JSON payload on stdin:

```json
{
  "event": "auto_action_taken",
  "repo": "owner/repo",
  "issue": 42,
  "title": "Login button broken on mobile",
  "action": "label",
  "details": "Applied label: bug, mobile",
  "timestamp": "2026-03-06T14:30:00Z"
}
```

### 5.2 Built-in Adapters

| Adapter | Mechanism | Use Case |
|---------|-----------|----------|
| `github_comment` | `gh issue comment` | Actions taken (visible to collaborators) |
| `system` | macOS `osascript` | Approval requests (local attention) |
| `session` | SessionStart hook context injection | Summaries & pending items |

### 5.3 Extensible Adapters (v1 stubs)

| Adapter | Mechanism | Notes |
|---------|-----------|-------|
| `email` | SMTP / MCP | Could use Iris infrastructure |
| `telegram` | Bot API via curl | Simple webhook |
| `slack` | Webhook or Slack MCP | Team notifications |

Custom adapters: drop a script in `lib/adapters/`, reference in policy YAML.

### 5.4 Notification Routing

```yaml
notifications:
  auto_actions:
    - github_comment
  approval_needed:
    - system
    - github_comment
  approval_expired:
    - system
```

## 6. State & Memory

### 6.1 Local State (ephemeral, per-session)

File: `~/.claude/argos/state/<owner>-<repo>.json`

```json
{
  "last_poll": "2026-03-06T14:30:00Z",
  "last_issue_seen": 142,
  "pending_approvals": [
    {
      "issue": 42,
      "action": "open_pr",
      "proposed_at": "2026-03-06T14:25:00Z",
      "mode": "wait",
      "summary": "Fix null check in auth middleware"
    }
  ],
  "actions_this_hour": 3
}
```

### 6.2 Memories MCP (persistent, cross-session)

Stored with prefix `argos/<owner>/<repo>/`:
- Past actions and their outcomes
- Patterns learned (e.g., "auth issues usually touch src/middleware/")
- Issue resolution history for duplicate detection
- Team member assignment patterns

This enables Argos to improve over time — detecting systemic issues, recognizing duplicate patterns, and learning codebase hotspots.

## 7. Onboarding Flow

When `/watch` is run for a new repo:

1. **Prerequisites check** — verify `gh` CLI, authentication, Memories MCP availability
2. **Guided policy creation** — conversational, one question at a time:
   - Which issue labels to watch
   - Which actions are auto vs. approve
   - Approval modes per action
   - Poll interval
   - Notification preferences
3. **Generate policy YAML** — show it, get confirmation
4. **Dry run** — run one cycle, show what would happen, don't act
5. **Start watching** — begin the `/loop`

## 8. Scope

### v1 (this design)
- Single repo per `/watch` command (schema supports multi-repo later)
- Built-in notification adapters: github_comment, system, session
- Core actions: label, comment, assign, close_duplicate, diagnose, branch, push, open_pr
- Policy-driven tiered autonomy with guardrails
- Memories integration for cross-session learning
- Onboarding flow with dry run

### Future
- Multi-repo in single config
- Email, Telegram, Slack notification adapters
- PR review monitoring (not just issues)
- Auto-learning policies (suggest tier promotions based on approval history)
- Integration with Delphi for test generation on fixes
- Integration with Hermes for release note drafts from fixed issues

## 9. Dependencies

- Claude Code with `/loop` support
- `gh` CLI (authenticated)
- Memories MCP (for persistent state)
- `jq` (JSON processing in shell scripts)

## 10. Security Considerations

- **Prompt injection via issue content** — issues are untrusted input. The skill must sanitize issue titles/bodies before acting. Never execute code from issue content.
- **Token scope** — `gh` should use a token with minimal required permissions (issues read/write, PR create)
- **Protected paths** — guardrails enforce path restrictions regardless of policy tier
- **Rate limiting** — guardrails cap actions per hour to prevent runaway behavior
- **Dry run** — always available as a safety valve for testing policies
