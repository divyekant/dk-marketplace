---
id: feat-006
type: feature-doc
audience: external
topic: Zero-Cost Polling Architecture
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Zero-Cost Polling Architecture

Most issue automation tools either require a webhook server or run an always-on process that consumes resources continuously. Argos takes a fundamentally different approach: its entire polling pipeline is pure bash and `jq`, with zero LLM tokens consumed until an issue actually needs attention.

## Why This Matters

LLM tokens cost money. If your monitoring tool invokes an LLM on every poll — even to decide "nothing new" — you are paying for inaction. At a 5-minute interval, that is 288 LLM calls per day, per repo, just to learn there is nothing to do.

Argos eliminates this entirely. The poll cycle works like this:

```
/loop invokes Argos
  → gh issue list (GitHub CLI, no LLM)
  → jq filters (bash, no LLM)
  → 0 new issues? Exit immediately. Done.
  → New issues? NOW invoke Claude for triage and action.
```

The fetch, parse, and filter stages are shell scripts. They call `gh` for data, pipe through `jq` for filtering, and compare against a watermark stored in a local JSON file. No AI model is involved at any point until there is actual work to do.

## Comparison

| Approach | Idle Cost | Infrastructure | Local Codebase Access |
|----------|-----------|---------------|----------------------|
| **Argos** | Zero tokens | None — runs inside Claude Code | Full — it is your local machine |
| Webhook bots | Varies — server always running | Webhook endpoint, server, deployment | None — runs in cloud |
| LLM-based pollers | Tokens every cycle | LLM API calls on timer | Depends on setup |
| GitHub Actions | Minutes consumed | GitHub-hosted runners | Checkout only |

### No infrastructure to maintain

Argos runs inside Claude Code on your machine. There is no server to deploy, no webhook endpoint to expose, no cloud function to manage. You start it with `/loop 5m /watch owner/repo` and stop it by ending the loop. That is the entire operational surface.

### Full local codebase access

Because Argos runs where your code lives, it can do things webhook-based tools cannot:
- Read your source files to understand the issue in context
- Search your codebase for related code
- Create branches and commits against your local repo
- Use your local tools (linters, test runners, build systems)

A webhook bot receives an event payload with the issue text and has to work blind. Argos sees the issue and your entire codebase.

### No exposed endpoints

Webhook-based automation requires a publicly reachable URL. That means DNS, TLS certificates, firewall rules, authentication, and uptime monitoring. Argos makes outbound `gh` CLI calls only — no inbound traffic, no attack surface.

## The Numbers

For a repo with 2-3 new issues per day, polling every 5 minutes:

| Metric | Per Day |
|--------|---------|
| Total polls | 288 |
| Polls with no new issues | ~285 |
| Token cost for empty polls | **0** |
| Polls that trigger triage | ~3 |
| Tokens consumed | Only for those 3 issues |

Compare this to an LLM-based poller that invokes a model on every cycle: 285 wasted calls per day, multiplied by every repo you watch.

## How the Filter Pipeline Works

The four-stage filter pipeline runs entirely in bash:

1. **Watermark filter** — `jq 'select(.number > $last)'` — skips issues already processed
2. **Label filter** — keeps issues matching watched labels (or unlabeled)
3. **Ignore-label filter** — drops issues with skip labels (`wontfix`, `on-hold`)
4. **Max-age filter** — drops issues older than the configured window (default 7 days)

Each filter is a `jq` expression piped in sequence. The output is a count. If zero, the skill returns immediately — no LLM invocation, no API mutations, no cost.

## Scaling

Watch 10 repos at 5-minute intervals? That is 2,880 polls per day. If each repo averages 2 new issues, you consume tokens for 20 triage calls. The other 2,860 polls cost nothing.

This linear scaling with zero idle cost is what makes Argos practical for watching multiple repositories without budget concerns.
