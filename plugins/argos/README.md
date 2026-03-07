# Argos

The All-Seeing Issue Guardian -- a Claude Code plugin that watches GitHub repos for new issues, investigates them against your local codebase, and acts within boundaries you define.

## Why Argos?

**Zero-cost when idle.** The entire polling pipeline is bash and `jq`. No LLM tokens are consumed until an issue actually needs attention. At 5-minute intervals across 10 repos, that is 2,880 daily polls that cost nothing -- the LLM only activates when there is real work to do.

**Local-first investigation.** Unlike server-side tools, Argos runs on your machine with full access to your codebase. It can trace through source files, check test coverage, and identify affected functions -- the same investigation you would do manually, done before you context-switch.

**Policy-governed autonomy.** Every action falls into one of three tiers: **auto** (execute immediately), **approve** (queue for your review), or **deny** (never execute). Hard guardrails enforce rate limits, protected file paths, and maximum concurrent PRs regardless of policy settings.

## Quick Start

```
/watch owner/repo
```

First time? Argos walks you through a guided 9-step onboarding flow -- one question at a time, sensible defaults, no YAML to write by hand. It creates your policy, runs a dry-run preview, and starts watching after you confirm.

## How It Works

```
/loop invokes Argos every N minutes
  → gh issue list          (GitHub CLI -- no LLM)
  → jq filter pipeline     (bash -- no LLM)
  → 0 new issues? Exit.    (zero tokens consumed)
  → New issues? Claude activates:
      → Classify (bug/enhancement/duplicate/question)
      → Check policy tiers
      → Execute allowed actions (label, comment, branch, fix, PR)
      → Notify via configured adapters
      → Store learnings in Memories MCP
```

## Commands

| Command | Description |
|---|---|
| `/watch owner/repo` | Start watching (with guided onboarding on first run) |
| `/unwatch owner/repo` | Stop watching |
| `/argos-status` | Watched repos, queue depth, recent actions, guardrail utilization |
| `/argos-approve` | Review and approve/reject pending actions |

## Actions

| Action | Description | Default Tier |
|--------|-------------|-------------|
| `label` | Apply classification label | auto |
| `comment` | Post diagnostic comment with affected files | auto |
| `create_branch` | Create a fix branch | approve |
| `commit_fix` | Commit a code fix | approve |
| `open_pr` | Open a pull request | approve |
| `close` | Close duplicate issues | deny |

Destructive actions (`close_issue`, `merge_pr`, `force_push`, `delete_branch`) are always denied.

## Security

- **Prompt injection detection** -- 12+ patterns covering instruction overrides, identity manipulation, LLM control tokens, and obfuscation (base64, zero-width Unicode)
- **Shell injection prevention** -- all untrusted input sanitized before shell interpolation
- **Path traversal protection** -- adapter names validated against `^[a-zA-Z0-9_-]+$`
- **Protected file paths** -- `.env*`, `secrets/`, `*.pem`, `*.key` blocked from commits
- **Label whitelist** -- classifications validated against allowed values
- **Rate limiting** -- max actions per hour (default: 10)

## Project Structure

```
argos/
  .claude-plugin/plugin.json        # Plugin manifest
  skills/argos/SKILL.md             # Core skill (triage + action pipeline)
  commands/                         # /watch, /unwatch, /argos-status, /argos-approve
  hooks/                            # Session-start hook for pending approvals
  lib/                              # Shell libraries
    poll.sh                         # Issue fetching and filtering
    state.sh                        # Watermark and state management
    notify.sh                       # Notification dispatcher
    policy.sh                       # YAML policy loader
    adapters/                       # github-comment, system (macOS), session
  config/default-policy.yaml        # Default policy template
  tests/                            # Bash test suite (TDD)
  docs/generated/                   # Hermes-generated docs (internal/external/marketing)
```

## Dependencies

- **gh** -- GitHub CLI, authenticated (`gh auth status`)
- **jq** -- JSON processor
- **python3** + **pyyaml** -- YAML policy parsing
- **Memories MCP** -- Cross-session learning
- **Claude Code** -- Runtime environment

## Documentation

Full documentation is generated via [Hermes](https://github.com/divyekant/hermes) in `docs/generated/`:

- **Internal** (9 docs) -- feature handoffs, release notes, FAQ, glossary
- **External** (10 docs) -- getting started, feature docs, config reference, tutorials
- **Marketing** (7 docs) -- feature briefs, blog post, landing page, social posts

See [docs/generated/index.md](docs/generated/index.md) for the full index.

## Design

See [docs/plans/2026-03-06-argos-design.md](docs/plans/2026-03-06-argos-design.md) for the full design document.

## License

MIT
