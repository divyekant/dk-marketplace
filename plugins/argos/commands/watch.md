---
description: "Start watching a GitHub repo for new issues"
argument-hint: "owner/repo"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/lib/*:*)", "Skill"]
---

# Watch Command

You've been asked to start watching a GitHub repo for new issues using Argos.

## Arguments

The user provided: `$ARGUMENTS`

Parse the repo from arguments. It should be in `owner/repo` format.

## Prerequisites Check

Run these checks before proceeding:

1. Verify `gh` CLI is installed and authenticated:
   ```bash
   gh auth status
   ```

2. Verify `jq` is installed:
   ```bash
   jq --version
   ```

3. Verify the repo exists and is accessible:
   ```bash
   gh repo view "$REPO" --json name -q .name
   ```

## Policy Check

Check if a policy file exists for this repo:
```bash
SAFE_NAME="${REPO//\//-}"
POLICY_FILE="$HOME/.claude/argos/policies/${SAFE_NAME}.yaml"
```

- If the policy file exists, load it and proceed to **Dry Run**.
- If no policy file exists, run the **Onboarding Flow** below.

## Onboarding Flow (if no policy exists)

Guide the user through creating a policy for this repo. Ask one question at a time, wait for the answer, then proceed to the next. Present each question with checkbox-style options and clearly marked defaults.

### Step 1: Issue Types

Ask:

> **What types of issues should Argos act on?**
>
> Pick the labels Argos should watch for. Pre-selected defaults are marked with `[x]`:
>
> - `[x]` **bug** -- crash reports, regressions, broken behavior
> - `[x]` **enhancement** -- feature requests, improvements
> - `[ ]` **help-wanted** -- issues explicitly seeking contributors
> - `[ ]` **question** -- user questions / support requests
>
> You can also type additional custom labels (comma-separated).
> Unlabeled issues are always included so nothing slips through.

Store the user's selections as `filter_labels`. Default: `["bug", "enhancement"]`.

### Step 2: Auto Actions (no approval needed)

Ask:

> **What should Argos do automatically, without asking you first?**
>
> These actions happen immediately when a matching issue is found:
>
> - `[x]` **label** -- apply triage labels (e.g., `priority`, `area/*`)
> - `[x]` **comment_triage** -- post a triage comment acknowledging the issue, asking clarifying questions if needed
> - `[ ]` **assign** -- auto-assign the issue to a team member based on area
> - `[x]` **close_duplicate** -- detect and close duplicate issues with a link to the original
>
> Which of these should Argos handle on its own?

Store the user's selections as `actions_auto`. Default: `["label", "comment_triage", "close_duplicate"]`.

### Step 3: Approve Actions (require your sign-off)

Ask:

> **What actions should Argos propose but wait for your approval?**
>
> These actions are prepared but only executed after you approve them via `/argos-approve`:
>
> - `[x]` **comment_diagnosis** -- post a root-cause analysis comment on the issue
> - `[x]` **create_branch** -- create a fix branch from the default branch
> - `[x]` **push_commits** -- write and push code changes to the fix branch
> - `[x]` **open_pr** -- open a pull request with the fix
>
> Which of these should require your approval?

Store the user's selections as `actions_approve`. Default: `["comment_diagnosis", "create_branch", "push_commits", "open_pr"]`.

### Step 4: Approval Modes

For each action the user placed in the approve tier, ask:

> **How should Argos handle approval for `<action>`?**
>
> Choose one:
>
> 1. **wait** -- Argos blocks until you explicitly approve or reject. Nothing happens without your say-so. *(safest)*
> 2. **timeout** `<duration>` -- Argos waits for your response; if you don't respond within the timeout, the action is **skipped**. *(safe default for advisory actions)*
> 3. **default** `<duration>` -- Argos waits for your response; if you don't respond within the timeout, the action **proceeds automatically**. *(use for low-risk actions you usually approve)*

Present sensible per-action defaults:

| Action              | Default Mode  | Default Timeout | Rationale                                      |
|---------------------|---------------|-----------------|-------------------------------------------------|
| comment_diagnosis   | timeout       | 2h              | Advisory comment -- safe to skip if unreviewed  |
| create_branch       | default       | 4h              | Low risk -- just a branch, no code yet          |
| push_commits        | wait          | --              | Code changes -- always review                   |
| open_pr             | wait          | --              | Public-facing -- always review                  |

Ask: "These are the recommended defaults. Want to adjust any of them?"

Store as `approval_modes` map.

### Step 5: Poll Interval

Ask:

> **How often should Argos check for new issues?**
>
> | Interval | Label          | Best for                                     |
> |----------|----------------|----------------------------------------------|
> | `2m`     | Aggressive     | High-traffic repos, SLA-sensitive projects   |
> | `5m`     | Recommended    | Most repos -- good balance of speed and cost |
> | `15m`    | Relaxed        | Lower-traffic repos, background monitoring   |
> | `30m`    | Lazy           | Repos with infrequent issues                 |
>
> Recommended: **5m**

Store as `poll_interval`. Default: `5m`.

### Step 6: Notification Channels

Ask:

> **How should Argos notify you about its actions?**
>
> - `[x]` **github_comment** -- post status updates as comments on the issue itself
> - `[x]` **system** -- macOS system notification (shows in Notification Center)
> - `[ ]` **session** -- inject a context note into the current Claude Code session
>
> For auto actions, Argos always posts a GitHub comment. This controls additional channels.

Store as `notification_channels`. Default: `["github_comment", "system"]`.

### Step 7: Guardrails

Present the default guardrails and ask if the user wants to adjust:

> **Safety guardrails** -- these limits prevent Argos from doing too much damage if something goes wrong.
>
> | Guardrail              | Default        | Description                                           |
> |------------------------|----------------|-------------------------------------------------------|
> | `max_actions_per_hour` | **10**         | Hard cap on total actions (auto + approved) per hour  |
> | `max_open_prs`         | **3**          | Won't open new PRs if this many Argos PRs are open    |
> | `require_tests`        | **true**       | Refuse to open a PR unless it includes test changes   |
> | `max_files_changed`    | **10**         | Skip issues whose fix would touch more than N files   |
> | `protected_paths`      | `.env*`, `*.secret`, `config/production.*` | Never modify files matching these globs |
> | `dry_run`              | **false**      | If true, Argos logs what it would do but takes no action |
>
> **These defaults are intentionally conservative.** Want to adjust any of them?

Store as `guardrails` map.

### Step 8: Generate Policy YAML

Build the policy YAML from all collected answers. Use this template, filling in the user's selections:

```yaml
repo: "<owner>/<repo>"
poll_interval: <poll_interval>

actions:
  auto:
    <for each auto action>
    - <action>
  approve:
    <for each approve action>
    - <action>
  deny:
    - close_issue
    - merge_pr
    - force_push
    - delete_branch

approval_modes:
  <for each approve action>
  <action>:
    mode: <mode>
    timeout: <timeout if mode is timeout or default>

filters:
  labels: <filter_labels array>
  ignore_labels: ["wontfix", "on-hold", "discussion"]
  only_new: true
  max_age: 7d

notifications:
  auto_actions:
    - github_comment
  approval_needed:
    <notification_channels as list>
  approval_expired:
    - system

guardrails:
  max_actions_per_hour: <value>
  max_open_prs: <value>
  require_tests: <value>
  max_files_changed: <value>
  protected_paths:
    <for each pattern>
    - "<pattern>"
  dry_run: <value>
```

Ensure the `deny` list always includes `close_issue`, `merge_pr`, `force_push`, and `delete_branch` -- these are hard-coded safety defaults the user cannot remove during onboarding.

Ensure `ignore_labels` always includes `wontfix`, `on-hold`, `discussion`.

Write the generated YAML to the policy file:
```bash
mkdir -p "$HOME/.claude/argos/policies"
cat > "$POLICY_FILE" << 'POLICY_EOF'
<generated YAML content>
POLICY_EOF
```

### Step 9: Confirmation

Show the user the full generated YAML and ask:

> **Here's your Argos policy for `<owner>/<repo>`:**
>
> ```yaml
> <full generated YAML>
> ```
>
> Does this look right? I can adjust any section -- just tell me what to change.

If the user requests changes, update the relevant section and re-display. Loop until the user confirms. Re-write the file after each change.

## Dry Run

After the policy is confirmed (whether newly created or previously existing), perform a dry run to show the user what Argos would do with real issues.

### Fetch current issues

Source the polling library and fetch open issues for the repo:

```bash
source "${CLAUDE_PLUGIN_ROOT}/lib/poll.sh"
source "${CLAUDE_PLUGIN_ROOT}/lib/policy.sh"

POLICY_JSON=$(load_policy "$POLICY_FILE")
LABELS=$(echo "$POLICY_JSON" | get_filter_labels)
IGNORE=$(echo "$POLICY_JSON" | get_ignore_labels)

ISSUES=$(fetch_issues "$REPO" | parse_issues | filter_by_labels "$LABELS" | filter_ignore_labels "$IGNORE")
echo "$ISSUES" | jq -r '.[] | [.number, .title, (.labels | join(",")), .author] | @tsv'
```

### Evaluate each issue against the policy

For each issue returned, determine what Argos WOULD do based on the policy tiers. Present results as a table:

> **Dry run results for `<owner>/<repo>`** -- showing what Argos would do for current open issues:
>
> | Issue # | Title (truncated) | Auto Actions | Approve Actions | Tier |
> |---------|-------------------|--------------|-----------------|------|
> | #42 | Login crash on iOS 18 | label, comment_triage | comment_diagnosis, create_branch, push_commits, open_pr | approve |
> | #38 | Add dark mode toggle | label, comment_triage | comment_diagnosis, create_branch, push_commits, open_pr | approve |
> | #35 | Duplicate of #28 | close_duplicate | -- | auto |
>
> **Legend:**
> - **Auto Actions** -- would execute immediately, no approval needed
> - **Approve Actions** -- would be queued, waiting for your `/argos-approve`
> - **Tier** -- highest tier action determines the row's tier (`auto` = fully automatic, `approve` = needs sign-off)

If no issues match, say:

> No open issues match your policy filters right now. That's fine -- Argos will start catching new ones as they come in.

Ask:

> **Look good? Start watching for real?**

## Start Watching

If user confirms:
```bash
# Create state directory
mkdir -p "$HOME/.claude/argos/state"
```

Tell the user:
"Argos is now watching `owner/repo`. I'll check every [interval] for new issues.

To start the loop, run:
`/loop [interval] invoke the argos skill for [owner/repo]`

Other commands:
- `/argos-status` -- see what's happening
- `/argos-approve #N` -- approve pending actions
- `/unwatch owner/repo` -- stop watching"
