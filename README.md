# Argos

The All-Seeing Issue Guardian -- a Claude Code plugin that watches GitHub repos for new issues, investigates them against your local codebase, and acts within boundaries you define.

## Why Argos?

**Zero-cost when idle.** The entire polling pipeline is bash and `jq`. No LLM tokens are consumed until an issue actually needs attention. At 5-minute intervals across 10 repos, that is 2,880 daily polls that cost nothing -- the LLM only activates when there is real work to do.

**Local-first investigation.** Unlike server-side tools, Argos runs on your machine with full access to your codebase. It can trace through source files, check test coverage, and identify affected functions -- the same investigation you would do manually, done before you context-switch.

**Policy-governed autonomy.** Every issue is assigned a confidence level (1-5) that determines Argos's autonomy. Policy floors escalate oversight for sensitive paths, issue types, and unknown authors. Hard guardrails enforce rate limits, denied file paths, and maximum concurrent PRs regardless of confidence level.

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
      → Read project context (CLAUDE.md, README, docs)
      → Classify (bug/enhancement/duplicate/question)
      → Assess confidence level (1-5)
      → Apply policy floors (can only escalate)
      → Execute based on final level
      → Notify via channels (internal/external content)
      → Store learnings in Memories MCP
```

## Commands

| Command | Description |
|---|---|
| `/watch owner/repo` | Start watching (with guided onboarding on first run) |
| `/unwatch owner/repo` | Stop watching |
| `/argos-status` | Watched repos, queue depth, recent actions, guardrail utilization |
| `/argos-approve` | Review and approve/reject pending actions |

## Confidence Levels

| Level | Name | What Argos Does |
|-------|------|-----------------|
| 1 | Should Fix | Full autonomy -- fix, test, commit, open PR |
| 2 | Fix + Summary Review | Fix and PR, human gets summary to glance at |
| 3 | Fix + Thorough Review | Prepare fix on branch, PR opens after human reviews |
| 4 | Needs Approval | Investigate only, human decides whether to proceed |
| 5 | Can't Touch | Label and flag for human attention, no investigation |

Policy floors can escalate any issue's level based on file paths, issue type, and author trust. For example, `src/auth/**` can be set to always require level 3+ review.

## Security

- **Prompt injection detection** -- 12+ patterns covering instruction overrides, identity manipulation, LLM control tokens, and obfuscation (base64, zero-width Unicode)
- **Shell injection prevention** -- all untrusted input sanitized before shell interpolation
- **Path traversal protection** -- adapter names validated against `^[a-zA-Z0-9_-]+$`
- **Protected file paths** -- `.env*`, `secrets/`, `*.pem`, `*.key` blocked from commits
- **Label whitelist** -- classifications validated against allowed values
- **Rate limiting** -- max actions per hour (default: 10)
- **Automatic level 5 on injection** -- prompt injection detection triggers level 5 (can't touch), blocking all autonomous action

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
    adapters/                       # github-comment, system (macOS), session, pheme (MCP)
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
- **Pheme MCP** *(optional)* -- Multi-channel notifications (Slack, Telegram, email, etc.)

## Documentation

Full documentation is generated via [Hermes](https://github.com/divyekant/hermes) in `docs/generated/`:

- **Internal** (9 docs) -- feature handoffs, release notes, FAQ, glossary
- **External** (10 docs) -- getting started, feature docs, config reference, tutorials
- **Marketing** (7 docs) -- feature briefs, blog post, landing page, social posts

See [docs/generated/index.md](docs/generated/index.md) for the full index.

## Migration from v0.1.0

If you have an existing v0.1.0 policy (action-based tiers), Argos will detect the old format and refuse to process it. Run `/watch owner/repo` to re-run onboarding and migrate to the new confidence model. Your old policy will be replaced with the new floors-based format.

## Design

- [docs/plans/2026-03-07-confidence-model-design.md](docs/plans/2026-03-07-confidence-model-design.md) -- v0.2.0 confidence-driven triage model
- [docs/plans/2026-03-06-argos-design.md](docs/plans/2026-03-06-argos-design.md) -- original design document

## License

MIT
