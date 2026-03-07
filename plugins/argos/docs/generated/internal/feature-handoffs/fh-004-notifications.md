---
id: fh-004
type: feature-handoff
audience: internal
topic: Notifications
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Feature Handoff: Notifications

## What It Does

The Notification system is a pluggable dispatcher that routes event notifications to one or more adapters based on the policy configuration. It enables Argos to inform the user (and collaborators) about actions taken, approvals needed, and approvals expired -- through channels like GitHub issue comments, macOS system notifications, and session context injection. The adapter architecture makes it straightforward to add new channels (Slack, email, Telegram) without modifying core logic.

## How It Works

### Architecture

The notification system has three layers:

1. **`notify()` function** (`lib/notify.sh`) -- the public API. Accepts an event type, repo, issue number, title, action, details, and a list of adapter names. Builds a JSON payload and dispatches to each adapter in parallel.

2. **`build_payload()`** -- constructs a standardized JSON payload:
   ```json
   {
     "event": "auto_action_taken",
     "repo": "owner/repo",
     "issue": 42,
     "title": "Login button broken",
     "action": "label",
     "details": "Applied label: bug",
     "timestamp": "2026-03-06T14:30:00Z"
   }
   ```

3. **Adapter scripts** (`lib/adapters/*.sh`) -- each adapter is an executable shell script that reads the JSON payload from stdin and performs its notification action. Adapters run with `set -euo pipefail` and handle their own errors.

### Dispatch Flow

```
notify() called with event + adapter list
  |
  v
build_payload() -> JSON
  |
  v
For each adapter name:
  |
  +-> validate adapter name (regex: ^[a-zA-Z0-9_-]+$)
  +-> dispatch_to_adapter() pipes JSON to lib/adapters/<name>.sh
  +-> runs in background (&), notify() waits for all to complete
```

### Adapter Name Validation

`dispatch_to_adapter` validates the adapter name against `^[a-zA-Z0-9_-]+$` before constructing the script path. This prevents path traversal attacks (e.g., `../../etc/evil`). If the name fails validation, an error is logged to stderr and the adapter is skipped.

### Built-in Adapters

**`github-comment`** (`lib/adapters/github-comment.sh`)
- Posts a formatted comment on the GitHub issue using `gh issue comment`.
- Wraps the details field in a code block to prevent markdown injection from untrusted issue content.
- Uses `printf` and `--body-file -` (piped stdin) to avoid shell expansion of untrusted content.
- Fails silently (`|| true`) if `gh` is unavailable.

**`system`** (`lib/adapters/system.sh`)
- Sends a macOS native notification via `osascript display notification`.
- Sanitizes the title and body with `tr -cd '[:alnum:][:space:]._#/-:'` before interpolating into the AppleScript string, preventing injection.
- Only runs on Darwin (macOS). Silently no-ops on other platforms.

**`session`** (`lib/adapters/session.sh`)
- Appends a one-line summary to `~/.claude/argos/session-context.txt`.
- The `session-start.sh` hook reads this file on CC session start and injects the content as `additional_context`.
- Sanitizes the details field and truncates to 200 characters before writing, preventing stored prompt injection.
- The session file is cleared after being read by the hook.

### Notification Routing in Policy

The policy maps event types to adapter lists:

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

Three event types are defined:
- `auto_actions` -- fired when an auto-tier action is executed.
- `approval_needed` -- fired when an approve-tier action is queued.
- `approval_expired` -- fired when a pending approval times out.

## Configuration

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `notifications.auto_actions` | Policy YAML | `[github_comment]` | Adapters for auto-action notifications |
| `notifications.approval_needed` | Policy YAML | `[system, github_comment]` | Adapters for approval request notifications |
| `notifications.approval_expired` | Policy YAML | `[system]` | Adapters for expired approval notifications |

**Files involved:**
- `/Users/divyekant/Projects/argos/lib/notify.sh` -- `notify`, `build_payload`, `dispatch_to_adapter`
- `/Users/divyekant/Projects/argos/lib/adapters/github-comment.sh` -- GitHub issue comment adapter
- `/Users/divyekant/Projects/argos/lib/adapters/system.sh` -- macOS system notification adapter
- `/Users/divyekant/Projects/argos/lib/adapters/session.sh` -- session context file adapter
- `/Users/divyekant/Projects/argos/lib/policy.sh` -- `get_notification_channels`

## Edge Cases

1. **Adapter script not found.** If the adapter script does not exist at the expected path, `dispatch_to_adapter` logs a warning to stderr but does not fail the overall `notify()` call. Other adapters in the list still execute.

2. **Adapter failure.** Each built-in adapter uses `|| true` or `2>/dev/null` to suppress errors. A failing adapter (e.g., network error during `gh issue comment`) does not block action execution or crash the loop. Per SKILL.md section 9: "Adapter fails (notification) -- Log warning, do not block action execution."

3. **Path traversal in adapter name.** Names like `../../tmp/evil` or `evil.payload` are rejected by the regex validation. The test suite (`test-notify.sh`) explicitly verifies this.

4. **Untrusted content in notification payload.** Issue titles and bodies originate from GitHub users and are untrusted. Each adapter sanitizes content before use:
   - `github-comment` wraps details in a code block.
   - `system` strips non-alphanumeric characters before AppleScript interpolation.
   - `session` sanitizes and truncates before writing to the context file.

5. **Concurrent adapter dispatch.** Adapters run in parallel (backgrounded with `&`). If two adapters write to the same resource (unlikely with built-in adapters), race conditions could occur. The `wait` call ensures all background processes complete before `notify()` returns.

## Common Questions

### Q1: How do I add a custom notification adapter?

Create a new shell script in `lib/adapters/` with the adapter name (e.g., `lib/adapters/slack.sh`). The script should read a JSON payload from stdin, extract the fields it needs via `jq`, and perform its notification action. Make the script executable (`chmod +x`). Then add the adapter name to the relevant `notifications.*` lists in the policy YAML.

### Q2: Can I disable all notifications?

Set all notification lists to empty arrays in the policy YAML:
```yaml
notifications:
  auto_actions: []
  approval_needed: []
  approval_expired: []
```
Note: this means no approval requests will be surfaced, so approve-tier actions will only be visible via `/argos-status`.

### Q3: Why does the session adapter truncate details to 200 characters?

The session context file is read by the `session-start.sh` hook and injected into the CC session as `additional_context`. Long or malicious details could pollute the session context. The 200-character limit, combined with character sanitization, prevents stored prompt injection and keeps session context concise.

### Q4: Do notifications fire during dry run mode?

Yes. Per SKILL.md section 8, dry run mode still sends notifications. The details field includes a `[DRY RUN]` prefix so recipients can distinguish simulated actions from real ones. This allows users to validate their notification routing without making any GitHub-mutating changes.

### Q5: What is the payload format for custom adapters?

All adapters receive the same JSON on stdin with these fields: `event` (string), `repo` (string), `issue` (number), `title` (string), `action` (string), `details` (string), `timestamp` (ISO 8601 string). Custom adapters should parse this with `jq` and handle errors gracefully.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| No GitHub comments appearing on issues | `gh` CLI not authenticated, or `github_comment` not in the policy's notification lists | Run `gh auth status`; check policy YAML `notifications` section |
| No macOS notifications | Not running on macOS, or Notification Center is silenced | Verify `uname` returns `Darwin`; check macOS notification settings |
| Session context not injected on startup | `session` adapter not in notification lists, or `session-start.sh` hook not running | Add `session` to a notification list; verify `hooks/hooks.json` is properly configured |
| Adapter name rejected | Name contains dots, slashes, or special characters | Use only alphanumeric characters, hyphens, and underscores in adapter names |
| Notification payload missing fields | `build_payload` received empty arguments | Ensure all six arguments are passed to `notify()` |
| Stale session context | Session file not cleared after read | Verify `session-start.sh` clears the file with `: > "$ARGOS_SESSION_FILE"` |
