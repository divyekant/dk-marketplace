# Your GitHub Issues Are Piling Up. Here Is What We Built About It.

Nobody becomes a developer to triage issues.

Yet here we are. Every morning starts the same way: open GitHub, scan the issue list, mentally sort the new ones. Is this a real bug or a configuration mistake? Is this a duplicate of #87? Which files does this even touch? You spend fifteen minutes on each issue before writing a single line of code, and half the time the answer is "this is the same auth bug we fixed last month."

Server-side tools help at the margins. GitHub Actions can auto-label based on file paths. Copilot can suggest code when you ask it to. But none of them can do the thing you actually need: open the codebase, read the relevant files, figure out what is going on, and tell you whether this issue is worth your time -- all before you context-switch out of whatever you are building.

That is the gap Argos fills.

## What Argos Does

Argos is a Claude Code plugin that watches your GitHub repositories for new issues and acts on them. It runs locally on your machine, inside your existing Claude Code setup. One command starts it:

```
/watch owner/repo
```

From that point, Argos polls for new issues in the background using the GitHub CLI. When nothing is happening, it consumes zero tokens -- the polling is pure bash. When a new issue arrives, it invokes Claude Code with full access to your local codebase and takes action according to a policy you define.

What kind of action? That depends on what you allow:

- **Classify the issue** as a bug, enhancement, or duplicate
- **Apply labels** based on content analysis
- **Post a diagnostic comment** identifying affected files and likely root cause
- **Create a branch** and push a fix
- **Open a pull request** with the changes
- **Close duplicates** with a reference to the original

Each of these actions falls into one of three tiers that you configure in a YAML policy file:

- **Auto** -- happens immediately, no approval needed
- **Approve** -- queued for your review before execution
- **Deny** -- never happens, period

This is the part that matters. Argos is not a black box that does whatever it wants. You define the boundaries. You decide that labeling and triage comments are automatic, that PRs need your sign-off, and that force-pushing is forbidden. The policy file is version-controlled, auditable, and trivial to change.

## Zero-Cost Until It Matters

Here is something most automation tools get wrong: they burn resources even when nothing is happening. A webhook bot needs a server running 24/7. An LLM-based poller invokes a model on every cycle to decide "nope, nothing new." At a 5-minute interval, that is 288 LLM calls per day per repo — just to learn there is nothing to do.

Argos does not work this way. Its entire polling pipeline is bash and `jq`:

1. `gh issue list` fetches open issues (GitHub CLI, no LLM)
2. `jq` filters against a watermark, labels, and age (bash, no LLM)
3. Zero new issues? Exit immediately. No model invoked. Zero tokens consumed.
4. New issues found? NOW Claude activates for triage and action.

Watch 10 repos at 5-minute intervals and you get 2,880 polls per day. If each repo averages 2 new issues, you pay for 20 triage calls. The other 2,860 polls cost nothing. No server running, no webhook endpoint exposed, no cloud function to manage. Just a loop on your machine that checks and exits.

This is not a minor optimization. It is an architectural decision that makes Argos practical for watching many repositories without worrying about your token budget.

## Why Local-First Changes Everything

Every competing tool in this space runs server-side. GitHub Agentic Workflows, Copilot Coding Agent, claude-code-action -- they all execute on remote infrastructure with limited context. They can see a PR diff or an issue body, but they cannot read your codebase. They do not know that your authentication logic lives in three files across two packages, or that the last four bugs in the payments module were all caused by the same race condition.

Argos runs on your machine. It has the same access Claude Code has: your full local repository, your MCP servers, your skills, your Memories. When it investigates an issue, it can grep through your codebase, read your test files, check your configuration -- the same things you would do manually, but faster and without pulling you out of flow.

This is not just a convenience difference. It is a capability difference. A server-side tool that reads an issue titled "Login fails on mobile" can apply a "bug" label. Argos can trace the authentication flow, identify the mobile-specific code path, find the null check that is missing, and post a comment that says "This is likely caused by a missing null check in `src/middleware/auth.ts:142`. The mobile OAuth flow skips the session validation step that the desktop flow handles at line 89."

That is the difference between automation and investigation.

## It Gets Smarter

Argos integrates with Memories MCP, which means it persists what it learns across sessions. After a few weeks of watching your repo, it knows things:

- Issues mentioning "timeout" usually involve the database connection pool
- PRs touching `src/api/routes.ts` tend to break the integration tests
- Duplicate reports cluster around the same three features after every release
- Developer A handles frontend issues; Developer B handles infrastructure

This is not theoretical. Every triage decision, every resolution, every pattern gets stored. The next time a similar issue arrives, Argos catches the duplicate faster, routes the assignment better, and writes a more accurate diagnostic comment.

## Guardrails Are Not Optional

Giving an AI agent autonomy over your repository sounds risky. We agree. That is why Argos has hard guardrails that apply regardless of your policy configuration:

- **Max actions per hour** (default: 10) -- prevents runaway behavior
- **Max open PRs** (default: 3) -- limits concurrent automated changes
- **Protected file paths** -- `.env`, secrets, and production configs are untouchable
- **Max files changed per action** (default: 10) -- scopes automated fixes
- **Dry-run mode** -- simulates a full cycle without executing anything

These are not suggestions. They are enforced limits. Even if your policy says "auto-approve everything," the guardrails still apply.

## How It Compares

The alternatives fall into two categories: server-side tools that lack local context, and reactive tools that do not watch for issues proactively.

GitHub Agentic Workflows runs on GitHub's infrastructure with limited customization. Copilot Coding Agent activates only when you invoke it. claude-code-action runs in CI, not locally. None of them offer tiered autonomy. None of them learn across sessions.

Argos is the only tool that is proactive, local-first, and policy-governed. It watches without being asked, investigates with full codebase access, and respects boundaries you define in a single YAML file.

## Getting Started

Argos requires Claude Code, the GitHub CLI (`gh`), and Memories MCP. Install the plugin, run `/watch owner/repo`, and walk through the guided setup. Argos will ask you which labels to watch, which actions to automate, and how you want to be notified. It generates your policy file, runs a dry-run cycle to show you what would happen, and then starts watching.

Four commands cover ongoing use:

- `/watch owner/repo` -- start monitoring
- `/unwatch owner/repo` -- stop monitoring
- `/argos-status` -- see what Argos has been doing
- `/argos-approve` -- review actions waiting for your sign-off

The project is MIT licensed and designed to be extended. Custom notification adapters are shell scripts. Policy files are YAML. Everything is auditable, everything is local.

Your issues are piling up. Argos is ready to start working through them -- on your terms.
