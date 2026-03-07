---
id: feat-005
type: feature-doc
audience: external
topic: Guided Onboarding
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Guided Onboarding

The first time you run `/watch` on a repository, Argos walks you through a conversational setup flow that creates a policy tailored to your preferences. No config files to write by hand, no YAML to look up — just answer questions one at a time, and Argos builds your policy from the answers.

## How It Works

Run `/watch owner/repo` for a repo you haven't watched before. Argos detects that no policy file exists and starts the onboarding flow automatically.

### The 9 Steps

Each step asks one question and waits for your answer. Defaults are clearly marked, so you can press through quickly if the defaults work for you.

**1. Filter Labels**
> Which issue labels should Argos watch for?
> Options: `bug`, `enhancement`, `help-wanted`, or specify your own.
> Default: `["bug", "enhancement", "help-wanted"]`

Unlabeled issues are always included — they need triage too.

**2. Ignore Labels**
> Which labels should Argos skip entirely?
> Options: `wontfix`, `on-hold`, `discussion`, or specify your own.
> Default: `["wontfix", "on-hold", "discussion"]`

These three defaults are always included. You can add more but cannot remove them during onboarding.

**3. Auto Actions**
> Which actions should Argos perform automatically (no approval needed)?
> Options: `label`, `comment`, `create_branch`, `commit_fix`, `open_pr`
> Default: `["label", "comment"]`

These execute immediately when the triage pipeline decides they are appropriate.

**4. Approve Actions**
> Which actions need your approval before executing?
> Options: same list minus what you already put in auto
> Default: `["create_branch", "commit_fix", "open_pr"]`

Approved actions are queued. You review and approve them via `/argos-approve`.

**5. Deny Actions (non-negotiable)**
> The following actions are always denied:
> `close_issue`, `merge_pr`, `force_push`, `delete_branch`

These are hardcoded safety defaults. Argos never performs destructive operations autonomously.

**6. Approval Modes**
> For actions that need approval, what happens when the timeout expires?
> Options per action: `wait` (block until you respond), `timeout` (auto-skip), `default` (auto-proceed)
> Default: `timeout` for all approve-tier actions

`timeout` is the safest default — if you don't respond, the action is simply skipped.

**7. Poll Interval**
> How often should Argos check for new issues?
> Options: `2m` (aggressive), `5m` (recommended), `15m` (relaxed), `30m` (lazy)
> Default: `5m`

This controls both the `/loop` interval and the `poll_interval` in your policy.

**8. Notification Channels**
> Where should Argos send notifications?
> Options: `github-comment` (on the issue), `system` (macOS notification), `session` (CC session context)
> Default: `["github-comment", "session"]`

You can enable multiple channels. Each fires independently.

**9. Guardrails**
> Safety limits:
> - Max actions per hour: `10` (default)
> - Dry run mode: `false` (default)
> - Protected paths: `.env*`, `secrets/`, `*.pem`, `*.key` (defaults)

Guardrails are hard limits that the LLM cannot override.

### What Happens After

Once you confirm your choices, Argos:

1. **Writes the policy** to `~/.claude/argos/policies/<owner>-<repo>.yaml`
2. **Runs a dry run** — fetches current open issues and shows you exactly what it would do, without actually doing anything
3. **Asks for confirmation** — if the dry run looks right, you start the loop

This means you see Argos in action before it touches anything. If the dry run reveals unexpected behavior, you can tweak the policy and re-run `/watch`.

## Re-Onboarding

To start fresh:

```bash
# Delete the policy and re-run /watch
rm ~/.claude/argos/policies/owner-repo.yaml
/watch owner/repo
```

Or edit the YAML directly — changes take effect on the next poll cycle without re-running onboarding.

## Why Conversational Setup?

Traditional tools dump a config file on you and expect you to read docs to fill it in. Argos takes the opposite approach: it asks you what you want in plain language, shows sensible defaults, and builds the config for you. The result is a standard YAML file you can edit later, but you never have to write one from scratch.

The dry run step is especially important — it closes the feedback loop immediately. You don't configure in the dark and hope for the best. You see what Argos would do with your real issues before anything happens.
