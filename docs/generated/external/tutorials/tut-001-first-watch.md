---
type: tutorial
id: tut-001
title: "Your First Watch: Set Up Argos on a Real Repo"
audience: external
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Tutorial: Your First Watch

In this tutorial, you will set up Argos on a real GitHub repository, configure a policy, see it triage an issue, and learn how to review and approve actions. By the end, you will have a working Argos setup monitoring your repo.

**Time required:** About 10 minutes.

**What you will need:**

- Claude Code with Argos plugin installed
- A GitHub repository you have write access to
- `gh` CLI authenticated (`gh auth login`)
- `jq` installed
- `python3` with PyYAML (`pip3 install pyyaml`)

---

## Step 1: Verify Prerequisites

Open a Claude Code session. Before starting, confirm everything is in place.

Run:

```
/watch myorg/myapp
```

(Replace `myorg/myapp` with your actual repository.)

Argos checks prerequisites automatically:

- Is `gh` CLI installed and authenticated?
- Is `jq` available?
- Does the repo exist and is it accessible?

If any check fails, Argos tells you exactly what to fix. For example:

> `gh` CLI is not authenticated. Run `gh auth login` to set up authentication.

Once all checks pass, Argos moves to policy creation.

---

## Step 2: Walk Through Onboarding

Since this is your first time watching this repo, Argos starts the guided onboarding flow. It asks one question at a time and waits for your answer.

### 2a: Issue Types

Argos asks:

> **What types of issues should Argos act on?**
>
> - `[x]` **bug**
> - `[x]` **enhancement**
> - `[ ]` **help-wanted**
> - `[ ]` **question**

For this tutorial, accept the defaults (bug and enhancement). Just say "defaults are fine" or press enter.

### 2b: Auto Actions

> **What should Argos do automatically?**
>
> - `[x]` **label** -- apply triage labels
> - `[x]` **comment_triage** -- post an acknowledgment comment
> - `[ ]` **assign** -- auto-assign to a team member
> - `[x]` **close_duplicate** -- detect and close duplicates

Accept the defaults. These are low-risk actions that do not change code.

### 2c: Approve Actions

> **What actions should require your approval?**
>
> - `[x]` **comment_diagnosis** -- root-cause analysis comment
> - `[x]` **create_branch** -- create a fix branch
> - `[x]` **push_commits** -- write and push code
> - `[x]` **open_pr** -- open a pull request

Accept the defaults. These higher-risk actions will wait for your sign-off.

### 2d: Approval Modes

Argos shows recommended modes for each approve-tier action:

| Action | Mode | Timeout |
|--------|------|---------|
| comment_diagnosis | timeout | 2h |
| create_branch | timeout | 4h |
| push_commits | wait | -- |
| open_pr | wait | -- |

For this tutorial, accept the defaults. You can always change them later in the policy file.

### 2e: Poll Interval

> **How often should Argos check for new issues?**

Choose **5m** (Recommended). This gives you a good balance between responsiveness and resource usage.

### 2f: Notification Channels

> **How should Argos notify you?**
>
> - `[x]` **github_comment**
> - `[x]` **system** (macOS notifications)
> - `[ ]` **session**

Accept the defaults. You will see action summaries as GitHub comments on the issue and get macOS alerts for approval requests.

### 2g: Guardrails

Argos shows the safety guardrails with conservative defaults:

| Guardrail | Default |
|-----------|---------|
| max_actions_per_hour | 10 |
| max_open_prs | 3 |
| require_tests | true |
| max_files_changed | 10 |
| protected_paths | .env*, *.secret, config/production.* |
| dry_run | **false** |

**Recommendation for your first watch:** Change `dry_run` to `true`. This lets you observe Argos's behavior without it taking real actions. Tell Argos:

> "Set dry_run to true."

---

## Step 3: Review the Generated Policy

Argos generates a YAML file and shows it to you:

```yaml
repo: myorg/myapp
poll_interval: 5m

actions:
  auto:
    - label
    - comment_triage
    - close_duplicate
  approve:
    - comment_diagnosis
    - create_branch
    - push_commits
    - open_pr
  deny:
    - close_issue
    - merge_pr
    - force_push
    - delete_branch

approval_modes:
  comment_diagnosis:
    mode: timeout
    timeout: 2h
  create_branch:
    mode: timeout
    timeout: 4h
  push_commits:
    mode: wait
  open_pr:
    mode: wait

filters:
  labels: ["bug", "enhancement"]
  ignore_labels: ["wontfix", "on-hold", "discussion"]
  only_new: true
  max_age: 7d

notifications:
  auto_actions:
    - github_comment
  approval_needed:
    - system
    - github_comment
  approval_expired:
    - system

guardrails:
  max_actions_per_hour: 10
  max_open_prs: 3
  require_tests: true
  max_files_changed: 10
  protected_paths:
    - ".env*"
    - "*.secret"
    - "config/production.*"
  dry_run: true
```

Review it. If anything looks wrong, tell Argos what to change. When you are satisfied, confirm.

The policy is saved to `~/.claude/argos/policies/myorg-myapp.yaml`.

---

## Step 4: See the Dry Run

Argos fetches your repo's open issues and shows what it **would** do:

```
Dry run results for myorg/myapp:

| Issue # | Title                      | Auto Actions          | Approve Actions                              |
|---------|----------------------------|-----------------------|----------------------------------------------|
| #12     | API returns 500 on POST    | label, comment_triage | comment_diagnosis, create_branch, push, pr   |
| #10     | Add pagination support     | label, comment_triage | comment_diagnosis, create_branch, push, pr   |
| #8      | API returns 500 on POST    | close_duplicate (#12) | --                                           |
```

This is exactly what Argos would do if dry_run were `false`. Since it is `true`, no actions are actually taken.

Confirm to start watching.

---

## Step 5: Start the Monitoring Loop

Argos tells you to run:

```
/loop 5m invoke the argos skill for myorg/myapp
```

This starts a background loop that checks for new issues every 5 minutes.

---

## Step 6: Create a Test Issue

Go to your repo on GitHub and create a new issue:

- **Title:** "Login page crashes when email contains a plus sign"
- **Labels:** `bug`
- **Body:** "When I try to log in with an email like user+test@example.com, the page shows a white screen. Console shows TypeError."

Wait for the next poll cycle (up to 5 minutes).

---

## Step 7: See Argos Respond (Dry Run)

Since `dry_run` is `true`, Argos logs what it would do. You will receive a system notification:

> Argos: myorg/myapp -- [DRY RUN] label on #13: Login page crashes when email contains a plus sign

Check the status:

```
/argos-status
```

You will see the issue listed under recent actions with `[DRY RUN]` prefixed.

---

## Step 8: Go Live

Now that you have seen how Argos behaves, turn off dry run mode. Open the policy file:

```bash
nano ~/.claude/argos/policies/myorg-myapp.yaml
```

Change:

```yaml
  dry_run: false
```

Save the file. On the next poll cycle, Argos will take real actions.

---

## Step 9: See Real Actions

Create another test issue (or wait for a real one). This time, Argos will:

1. **Classify** the issue based on labels and content.
2. **Apply a label** (auto action) -- you will see a `bug` label added.
3. **Post a triage comment** (auto action) -- the issue gets a comment from your GitHub user (via `gh`) summarizing the classification and next steps.
4. **Queue a diagnosis** (approve action) -- you will get a macOS notification asking you to review.

---

## Step 10: Approve an Action

Check pending approvals:

```
/argos-status
```

You will see something like:

```
Pending Approvals
| # | Issue                                   | Action            | Proposed | Mode | Expires |
|---|-----------------------------------------|-------------------|----------|------|---------|
| 1 | #14 "Login crashes with plus sign email" | comment_diagnosis | 2m ago   | timeout 2h | in 1h 58m |
```

To approve the diagnosis:

```
/argos-approve #14
```

Argos reads your codebase, identifies the likely root cause, and posts a detailed analysis comment on the issue.

To reject it instead:

```
/argos-approve #14 reject
```

---

## What You Learned

- How to install and set up Argos on a real repository.
- How the onboarding flow creates a policy tailored to your preferences.
- How dry run mode lets you preview behavior safely.
- How Argos classifies issues and takes actions based on policy tiers.
- How to review and approve pending actions.
- How to check status and monitor Argos's activity.

## Next Steps

- **Customize your policy** -- Edit `~/.claude/argos/policies/myorg-myapp.yaml` to adjust tiers, guardrails, and notification channels. See the [Config Reference](../config-reference.md).
- **Watch more repos** -- Run `/watch` for other repositories. Each gets its own independent policy.
- **Write a custom adapter** -- See the [Notifications feature doc](../features/feat-004-notifications.md) for instructions on creating your own notification adapter (Slack, email, etc.).
- **Learn about triage** -- Read the [Issue Triage feature doc](../features/feat-003-issue-triage.md) for details on classification rules, duplicate detection, and the action pipeline.
