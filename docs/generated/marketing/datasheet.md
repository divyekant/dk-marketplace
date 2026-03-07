# Argos -- Product Datasheet

**The All-Seeing Issue Guardian**
A Claude Code plugin for proactive, local-first GitHub issue monitoring and autonomous action.

---

## Overview

Argos monitors GitHub repositories for new issues and takes action within configurable boundaries. It runs entirely inside Claude Code on your local machine, leveraging your codebase, development context, and the full CC ecosystem to triage, investigate, and respond to issues automatically.

---

## Capabilities

### Issue Monitoring
- Continuous polling via GitHub CLI (`gh`) at configurable intervals (default: 5 minutes)
- Filter by label, age, and status
- Zero-token idle cost -- polling is pure bash, no LLM invocation until an issue is found

### Triage & Classification
- Automatic issue classification: bug, enhancement, duplicate
- Label application based on issue content and codebase analysis
- Duplicate detection using Memories MCP resolution history
- Team member assignment based on learned patterns

### Investigation
- Full local codebase access for root-cause analysis
- File and function identification for reported issues
- Diagnostic comment generation with affected files, likely causes, and suggested approaches
- Cross-session pattern recognition (e.g., "auth issues usually touch src/middleware/")

### Autonomous Actions
| Action | Description |
|---|---|
| `label` | Apply classification labels |
| `comment_triage` | Post initial triage comment |
| `assign` | Assign to team member |
| `close_duplicate` | Close with reference to original |
| `comment_diagnosis` | Post detailed diagnostic analysis |
| `create_branch` | Create a fix branch |
| `push_commits` | Push code changes |
| `open_pr` | Open a pull request with the fix |

### Policy Engine
- **Three action tiers:** auto (no approval), approve (human gating), deny (forbidden)
- **Three approval modes:** wait (block), timeout (skip after window), default (proceed after window)
- Per-repo YAML policy files at `~/.claude/argos/policies/`
- Actions not listed in any tier are implicitly denied

### Guardrails
| Guardrail | Default | Purpose |
|---|---|---|
| `max_actions_per_hour` | 10 | Prevent runaway behavior |
| `max_open_prs` | 3 | Limit concurrent automated PRs |
| `require_tests` | true | Ensure test coverage on fixes |
| `max_files_changed` | 10 | Scope control on automated changes |
| `protected_paths` | `.env*`, `*.secret`, `config/production.*` | Prevent sensitive file modification |
| `dry_run` | false | Test policies without taking action |

### Notifications
| Adapter | Channel | Use Case |
|---|---|---|
| `github_comment` | GitHub issue thread | Visible to all collaborators |
| `system` | macOS native notification | Local attention for approvals |
| `session` | Claude Code session context | Summaries and pending items on session start |

Extensible via custom adapters (any shell script in `lib/adapters/`). Planned: email, Telegram, Slack.

### Learning & Memory
- Persists patterns, decisions, and outcomes via Memories MCP
- Improves duplicate detection accuracy over time
- Learns codebase hotspots and common failure patterns
- Tracks team member assignment history for intelligent routing

---

## Architecture

```
User runs /watch owner/repo
    |
    v
/loop 5m -- bash-only polling via gh CLI (zero LLM cost)
    |
    +-- No new issues --> sleep
    +-- New issue found --> invoke Argos skill
            |
            v
        Read policy YAML --> classify issue --> check tier
            |
            +-- auto --> execute, notify
            +-- approve --> queue, notify, wait for /argos-approve
            +-- deny --> skip
            |
            v
        Update state + persist to Memories MCP
```

**Key architectural decisions:**
- Pure Claude Code plugin -- no external services, daemons, or containers
- Bash-only polling keeps idle cost at zero tokens
- LLM invoked only when action is needed
- State stored locally; learning stored in Memories MCP for cross-session persistence

---

## Requirements

| Requirement | Details |
|---|---|
| **Claude Code** | With `/loop` command support |
| **GitHub CLI** | `gh` authenticated (`gh auth status`) |
| **jq** | JSON processing for API responses |
| **python3 + pyyaml** | YAML policy parsing |
| **Memories MCP** | Cross-session learning and pattern persistence |
| **Platform** | macOS (system notifications via `osascript`); core functionality is cross-platform |

---

## Security

- **Prompt injection protection:** Issue content is treated as untrusted input; sanitized before processing
- **Minimal token scope:** GitHub CLI should use a token with only issues read/write and PR create permissions
- **Protected paths:** Guardrails enforce file path restrictions regardless of policy tier
- **Rate limiting:** Configurable cap on actions per hour
- **Dry run mode:** Full policy simulation without executing any actions

---

## Commands

| Command | Description |
|---|---|
| `/watch owner/repo` | Start watching a repository |
| `/unwatch owner/repo` | Stop watching a repository |
| `/argos-status` | Show watched repos, queue depth, recent actions |
| `/argos-approve` | Review and approve/reject pending actions |

---

## Version

**Current:** v0.1.0 (initial release)
**License:** MIT
