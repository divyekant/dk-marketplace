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

## Re-watch Handling

Check if a policy file already exists for this repo:
```bash
SAFE_NAME="${REPO//\//-}"
POLICY_FILE="$HOME/.claude/argos/policies/${SAFE_NAME}.yaml"
```

If the policy file exists, read the current poll interval from it and ask:

> **You're already watching `<owner/repo>` (every <interval>). What would you like to do?**
>
> 1. **Update policy** -- re-run onboarding to change settings
> 2. **Change interval** -- keep policy, adjust poll frequency
> 3. **Restart loop** -- same settings, fresh start

Act accordingly:

- **Option 1:** Delete the existing policy file and proceed to the **Onboarding Flow** below.
- **Option 2:** Ask for the new interval, update `poll_interval` in the policy file, then proceed to **Start Watching**.
- **Option 3:** Proceed directly to **Start Watching** with the existing policy.

If no policy file exists, proceed to the **Onboarding Flow**.

## Policy Check

Check if a policy file exists for this repo:
```bash
SAFE_NAME="${REPO//\//-}"
POLICY_FILE="$HOME/.claude/argos/policies/${SAFE_NAME}.yaml"
```

- If the policy file exists and uses the **new format** (has a `floors:` key), proceed to **Dry Run**.
- If the policy file exists but uses the **old format** (has an `actions:` key instead of `floors:`), tell the user:
  > "Your policy for `<owner/repo>` uses the old action-based format. The new confidence model replaces action tiers with oversight levels. I'll re-run onboarding to migrate your settings."
  Then proceed to the **Onboarding Flow**.
- If no policy file exists, run the **Onboarding Flow** below.

## Onboarding Flow

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

### Step 2: Confidence Floor

Ask:

> **What's the minimum oversight level for all issues?**
>
> This sets a blanket floor -- Argos will never operate below this level of oversight, regardless of how confident it is.
>
> 1. **Level 1 -- Fully autonomous** -- Argos can fix things end-to-end without any review. *(For mature, well-tested repos where you trust Argos completely.)*
> 2. **Level 2 -- Fix + summary review** -- Argos fixes things but you get a concise summary to glance at. *(Recommended for most repos.)*
> 3. **Level 3 -- Fix + thorough review** -- Argos fixes things but you review the full diff before it goes live. *(For repos where you want close oversight.)*
> 4. **Level 4 -- Investigate only** -- Argos only investigates and reports. You decide what to do. *(Maximum control.)*
>
> Recommended: **Level 2**

Store as `floors.minimum`. Default: `2`.

### Step 3: Sensitive Paths

Ask:

> **Any paths that should always require higher oversight?**
>
> Fixes touching these paths will be escalated to at least the specified level, even if Argos is confident about the fix. Here are some sensible defaults:
>
> | Path Pattern | Minimum Level | Reason |
> |-------------|---------------|--------|
> | `src/auth/**` | 3 | Authentication logic -- always review thoroughly |
> | `src/payments/**` | 4 | Payment processing -- human approval required |
> | `config/production.*` | 5 | Production config -- can't touch |
>
> You can **add**, **remove**, or **adjust** levels for any path.
> Type paths in glob format (e.g., `src/database/**`) with a level number.

Store as `floors.paths`. Defaults:
- `"src/auth/**": 3`
- `"src/payments/**": 4`
- `"config/production.*": 5`

### Step 4: Enhancement Handling

Ask:

> **How should Argos handle enhancement/feature requests?**
>
> Enhancements expand product surface area and usually need human judgment. Choose a default oversight level:
>
> 1. **Level 4 -- Investigate only** -- Argos analyzes the request and writes up a recommendation, but you decide. *(Recommended)*
> 2. **Level 5 -- Can't touch** -- Argos labels the issue and flags it for you. No investigation, no fix attempt.
>
> Questions and support requests are always set to Level 5 (flag only).
>
> Recommended: **Level 4**

Store as `floors.types.enhancement`. Default: `4`.
Always set `floors.types.question` to `5`.

### Step 5: Author Trust

Ask:

> **Should Argos treat unknown contributors differently?**
>
> Anyone can open an issue on a public repo. Unknown authors could steer Argos to investigate or fix arbitrary parts of the codebase. Setting a floor for unknown authors adds a safety layer.
>
> - `[x]` **Yes** -- unknown/first-time authors floor at **Level 4** (investigate only, you decide). *(Recommended)*
> - `[ ]` **No** -- treat all authors the same, let the AI judge.
>
> You can also add **trusted GitHub usernames** who bypass this floor:
> *(Comma-separated, e.g., `alice, bob, carol`)*

Store as `floors.authors.unknown` (default: `4`) and `floors.authors.trusted` (default: `[]`).

### Step 6: Poll Interval

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

### Step 7: Notification Channels

Ask:

> **How should Argos notify you about its actions?**
>
> Each channel is tagged as **external** (visible to anyone) or **internal** (visible only to you). Argos tailors notification content based on the audience -- external notifications are sanitized and minimal, internal ones include full analysis.
>
> - `[x]` **github_comment** *(external)* -- post status updates as comments on the issue itself
> - `[x]` **system** *(internal)* -- macOS system notification (shows in Notification Center)
> - `[ ]` **session** *(internal)* -- inject a context note into the current Claude Code session
> - `[ ]` **pheme** *(internal)* -- send via Pheme to Slack, Telegram, email, etc. *(requires Pheme MCP server)*
>
> For auto actions, Argos always posts a GitHub comment. This controls additional channels.
>
> If the user selects **pheme**, verify the Pheme MCP server is available by calling `mcp__pheme__list_channels()`. If it's not available, warn the user and skip pheme.

Store as `notifications.channels` array with `name` and `type` for each. Defaults:
- `{ name: "github_comment", type: "external" }`
- `{ name: "system", type: "internal" }`

### Step 8: Guardrails

Present the default guardrails and ask if the user wants to adjust:

> **Safety guardrails** -- these limits prevent Argos from doing too much damage if something goes wrong.
>
> | Guardrail              | Default        | Description                                           |
> |------------------------|----------------|-------------------------------------------------------|
> | `max_actions_per_hour` | **10**         | Hard cap on total actions per hour                    |
> | `max_open_prs`         | **3**          | Won't open new PRs if this many Argos PRs are open    |
> | `require_tests`        | **true**       | Refuse to open a PR unless it includes test changes   |
> | `max_files_changed`    | **10**         | Skip issues whose fix would touch more than N files   |
> | `dry_run`              | **false**      | If true, Argos logs what it would do but takes no action |
>
> **Hard-coded denials (cannot be changed):**
> - **Denied actions:** `close_issue`, `merge_pr`, `force_push`, `delete_branch` -- always denied regardless of confidence level.
> - **Denied paths:** `.env*`, `*.secret`, `*.pem`, `*.key`, `config/production.*` -- never modified regardless of confidence level.
>
> **These defaults are intentionally conservative.** Want to adjust any of the guardrail values?

Store as `guardrails` map. The `deny` section is hardcoded and not user-adjustable.

### Step 9: Generate Policy YAML

Build the policy YAML from all collected answers. Use this template, filling in the user's selections:

```yaml
repo: "<owner>/<repo>"
poll_interval: <poll_interval>

floors:
  paths:
    <for each path>
    "<pattern>": <level>
  types:
    enhancement: <level>
    question: 5
  authors:
    trusted: <trusted_list>
    unknown: <unknown_floor>
  minimum: <minimum>

deny:
  actions:
    - close_issue
    - merge_pr
    - force_push
    - delete_branch
  paths:
    - ".env*"
    - "*.secret"
    - "*.pem"
    - "*.key"
    - "config/production.*"

guardrails:
  max_actions_per_hour: <value>
  max_open_prs: <value>
  require_tests: <value>
  max_files_changed: <value>
  dry_run: <value>

filters:
  labels: <filter_labels>
  ignore_labels: ["wontfix", "on-hold", "discussion"]
  only_new: true
  max_age: 7d

notifications:
  channels:
    <for each channel>
    - name: <name>
      type: <type>
```

Ensure the `deny.actions` list always includes `close_issue`, `merge_pr`, `force_push`, and `delete_branch` -- these are hard-coded safety defaults the user cannot remove during onboarding.

Ensure the `deny.paths` list always includes `.env*`, `*.secret`, `*.pem`, `*.key`, and `config/production.*`.

Ensure `filters.ignore_labels` always includes `wontfix`, `on-hold`, `discussion`.

Ensure `floors.types.question` is always `5`.

Write the generated YAML to the policy file:
```bash
mkdir -p "$HOME/.claude/argos/policies"
cat > "$POLICY_FILE" << 'POLICY_EOF'
<generated YAML content>
POLICY_EOF
```

### Confirmation

Show the user the full generated YAML and ask:

> **Here's your Argos policy for `<owner/repo>`:**
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

For each issue returned, evaluate it against the policy's floors and constraints. Classify each issue and estimate what confidence level the AI would assign. Present results as a table:

> **Dry run results for `<owner/repo>`** -- showing how Argos would handle current open issues:
>
> | Issue # | Title | Classification | Estimated Level | Reason |
> |---------|-------|---------------|----------------|--------|
> | #42 | Login crash on iOS 18 | bug | Level 2 (fix + summary) | Isolated crash, clear repro, 1 file |
> | #38 | Add dark mode toggle | enhancement | Level 4 (investigate only) | Enhancement floor = 4 |
> | #35 | Duplicate of #28 | bug | Level 1 (auto-fix) | Obvious duplicate, link and close |
> | #29 | Update auth token rotation | bug | Level 3 (fix + thorough) | Touches src/auth/**, floor = 3 |
>
> **Level legend:**
> - **Level 1** -- fully autonomous, no review
> - **Level 2** -- fix + summary review
> - **Level 3** -- fix + thorough review
> - **Level 4** -- investigate only, human decides
> - **Level 5** -- can't touch, flagged for human

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

Then directly start the loop by invoking the Skill tool:

```
Invoke Skill: loop
Args: "<poll_interval> invoke the argos skill for <owner/repo>"
```

Tell the user:

"Argos is now watching `owner/repo` every <interval>. The loop is running.

Commands:
- `/argos-status` -- see what's happening
- `/argos-approve` -- approve pending actions
- `/unwatch owner/repo` -- stop watching"
