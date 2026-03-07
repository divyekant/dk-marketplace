---
type: feature
id: feat-004
title: Notifications
audience: external
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Notifications

## What It Does

Argos uses a pluggable notification system to keep you informed about every action it takes, every approval it needs, and every guardrail it hits. Notifications are routed through **adapters** -- small shell scripts that each handle a different delivery mechanism.

You configure which adapters are active for each event type in your policy YAML, so you get the right signal through the right channel.

## How to Use It

### Configure During Onboarding

When you run `/watch` for a new repo, Argos asks which notification channels you want:

- **github_comment** -- Posts status updates as comments on the issue itself. Visible to all collaborators.
- **system** -- Sends a macOS Notification Center alert. Good for drawing your attention locally.
- **session** -- Writes a note to the session context file, which Argos surfaces when you start a new Claude Code session.

### Edit Directly

Open your policy file and adjust the `notifications` section:

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

Changes take effect on the next poll cycle.

## Adapters

### github_comment

**File:** `lib/adapters/github-comment.sh`

Posts a formatted comment on the GitHub issue using `gh issue comment`. The comment includes:

- The event type (e.g., `auto_actions`, `approval_needed`)
- The action that was taken or proposed
- Details about the action
- A timestamp

Comments use code blocks for the details field to prevent markdown injection from untrusted issue content.

**Best for:** Keeping a visible record of Argos activity on the issue itself. Your team sees what Argos did without leaving GitHub.

### system

**File:** `lib/adapters/system.sh`

Sends a native macOS notification via `osascript`. The notification appears in Notification Center with:

- **Title:** "Argos: owner/repo"
- **Body:** The action and issue summary
- **Subtitle:** The event type

Only works on macOS. Silently skipped on other platforms.

**Best for:** Getting your attention for approval requests or important events without switching to GitHub.

### session

**File:** `lib/adapters/session.sh`

Appends a log line to `~/.claude/argos/session-context.txt`. When you start a new Claude Code session, the `session-start.sh` hook reads this file and injects a summary into your session context -- telling you what Argos did while you were away.

The session file is cleared after being read, so you only see new activity.

**Best for:** Catching up on Argos activity when you return to work. No need to check GitHub or scroll through notifications.

## Notification Routing

Argos routes notifications based on event type. You configure which adapters handle each event:

| Event | When It Fires | Default Adapters |
|-------|--------------|-----------------|
| `auto_actions` | An auto-tier action was executed | `github_comment` |
| `approval_needed` | An approve-tier action is waiting for your sign-off | `system`, `github_comment` |
| `approval_expired` | A pending approval timed out (and was either skipped or auto-proceeded) | `system` |

### How Routing Works

When an event occurs, Argos:

1. Looks up the event type in `notifications` section of the policy.
2. Gets the list of adapter names for that event.
3. Builds a JSON payload with the event details.
4. Dispatches the payload to each adapter in parallel.

If an adapter fails (e.g., `gh` CLI is down, or you are on Linux and the `system` adapter cannot find `osascript`), the failure is logged but does not block the action. Notifications are best-effort.

## Payload Format

Every adapter receives a JSON payload on stdin with this structure:

```json
{
  "event": "auto_actions",
  "repo": "owner/repo",
  "issue": 42,
  "title": "Login button broken on mobile",
  "action": "label",
  "details": "Applied label: bug",
  "timestamp": "2026-03-06T14:30:00Z"
}
```

| Field | Description |
|-------|-------------|
| `event` | The event type that triggered this notification |
| `repo` | The `owner/repo` being watched |
| `issue` | The issue number |
| `title` | The issue title |
| `action` | The action that was taken or proposed |
| `details` | Human-readable details about the action |
| `timestamp` | UTC timestamp of when the notification was generated |

## Configuration Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `notifications.auto_actions` | list | `["github_comment"]` | Adapters to notify when an auto action executes |
| `notifications.approval_needed` | list | `["system", "github_comment"]` | Adapters to notify when an action needs approval |
| `notifications.approval_expired` | list | `["system"]` | Adapters to notify when a pending approval times out |

## Examples

### Minimal notifications (GitHub only)

```yaml
notifications:
  auto_actions:
    - github_comment
  approval_needed:
    - github_comment
  approval_expired:
    - github_comment
```

### Full notifications (all channels)

```yaml
notifications:
  auto_actions:
    - github_comment
    - session
  approval_needed:
    - system
    - github_comment
    - session
  approval_expired:
    - system
    - session
```

### Session-start summary

When you open a new Claude Code session, the session-start hook checks for pending approvals and recent activity. If there is anything to report, you see a message like:

> Argos: 2 pending approval(s) across 1 repo(s). 5 action(s) taken since last session. Run /argos-status for details.

## Writing a Custom Adapter

You can add your own notification adapter by creating a shell script in `lib/adapters/`. The script must:

1. Read a JSON payload from stdin.
2. Extract the fields it needs using `jq`.
3. Deliver the notification via its mechanism (webhook, email, etc.).
4. Use `set -euo pipefail` for safety.

Example -- a Slack webhook adapter:

```bash
#!/bin/bash
# lib/adapters/slack-webhook.sh
set -euo pipefail

PAYLOAD=$(cat)
REPO=$(echo "$PAYLOAD" | jq -r '.repo')
ISSUE=$(echo "$PAYLOAD" | jq -r '.issue')
ACTION=$(echo "$PAYLOAD" | jq -r '.action')
DETAILS=$(echo "$PAYLOAD" | jq -r '.details')

SLACK_WEBHOOK_URL="${ARGOS_SLACK_WEBHOOK:-}"
if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
  echo "Warning: ARGOS_SLACK_WEBHOOK not set" >&2
  exit 0
fi

curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg text "Argos: $ACTION on $REPO#$ISSUE -- $DETAILS" '{text: $text}')"
```

Then reference it in your policy:

```yaml
notifications:
  approval_needed:
    - system
    - slack-webhook
```

**Security note:** Adapter names are validated against a strict regex (`^[a-zA-Z0-9_-]+$`) to prevent path traversal attacks. Only alphanumeric characters, hyphens, and underscores are allowed.
