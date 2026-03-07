---
id: fh-003
type: feature-handoff
audience: internal
topic: Issue Triage
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Feature Handoff: Issue Triage

## What It Does

Issue Triage is the classification and action pipeline that runs for each new issue detected by the polling subsystem. It determines what category an issue belongs to (bug, enhancement, duplicate, question, or other), then queues the appropriate actions through the tiered autonomy system. The pipeline covers everything from reading the issue data to posting triage comments, assigning owners, closing duplicates, performing code diagnosis, creating fix branches, pushing commits, and opening pull requests.

## How It Works

### Classification Rules (SKILL.md Section 3)

Each new issue is classified into one of five categories:

| Category | Criteria |
|----------|----------|
| `bug` | Labels include "bug", or title/body contains: crash, error, broken, fails, regression |
| `enhancement` | Labels include "enhancement" or "feature", or title starts with "feat"/"add"/"improve" |
| `duplicate` | Title has high similarity (>70%) to an existing open issue |
| `question` | Labels include "question", or title starts with "how"/"why"/"is there" |
| `other` | Anything that does not match above |

Classification rules:
1. If the issue already has labels, trust them. Do not reclassify.
2. If unlabeled, analyze title and body to suggest classification.
3. Duplicate detection fetches open issues and compares titles using substring matching and keyword overlap.
4. When uncertain, classify as `other` and add a triage comment instead of taking action.

### Action Definitions (SKILL.md Section 4)

Each classification triggers a set of actions. Each action goes through the tier check before execution.

**`label`** -- Adds a classification label. Validates against a whitelist (`bug enhancement duplicate question other security-review`) to prevent injection via manipulated LLM output.

**`comment_triage`** -- Posts an acknowledgment comment with the detected classification, planned next steps, and whether any actions require approval. Uses the `github-comment` notification adapter.

**`assign`** -- Assigns the issue to a person based on a label-to-owner mapping in the policy, if configured. Skipped if no mapping exists.

**`close_duplicate`** -- When an issue is classified as `duplicate`, posts a comment linking to the original issue and closes the duplicate.

**`comment_diagnosis`** -- A deeper analysis action: searches the codebase for files related to the issue description, analyzes the relevant code, and posts a detailed diagnosis comment with likely root cause, affected files, and suggested fix approach.

**`create_branch`** -- Creates a fix branch (`fix/issue-<NUMBER>`) from main and pushes it.

**`push_commits`** -- Implements the fix using CC's coding abilities. Checks `require_tests`, verifies no protected paths are modified, verifies `max_files_changed`, sanitizes the issue title for the commit message, and stages only specific files (never `git add -A`).

**`open_pr`** -- Creates a pull request linking back to the issue. Before creating, checks `max_open_prs` guardrail. Sanitizes the issue title in the PR title.

### Processing Loop

For each issue in the filtered results (SKILL.md Section 4):

```
1. Extract issue fields: number, title, body, labels, author, url
2. Run security checks (see fh-006)
3. Classify the issue
4. For each relevant action:
   a. Check tier (auto/approve/deny)
   b. Check rate limit
   c. Check dry_run flag
   d. Execute (auto) or queue (approve) or skip (deny)
5. Update watermark: set_last_issue_seen
```

After processing all new issues, the skill also sweeps pending approvals (Step 5 of the workflow) to check for expired timeouts.

### Memories Integration

Before classifying, the skill searches Memories MCP for similar past issues:
```
memory_search: "argos/<owner>/<repo>/" + keywords from issue title
```

If 3+ similar issues appear in a week, the triage comment includes a note suggesting a broader investigation.

After every action:
```
memory_add: "argos/<owner>/<repo>/issue-<N>: <action> -- <outcome>. Files: <relevant_paths>"
```

After closing a duplicate:
```
memory_add: "argos/<owner>/<repo>/duplicate: #<N> duplicates #<original>. Title: <title>"
```

## Configuration

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `actions.auto` | Policy YAML | `[label, comment_triage, assign, close_duplicate]` | Actions that run without approval |
| `actions.approve` | Policy YAML | `[comment_diagnosis, create_branch, push_commits, open_pr]` | Actions that require approval |
| `guardrails.max_files_changed` | Policy YAML | `10` | Max files a fix can touch |
| `guardrails.require_tests` | Policy YAML | `true` | Whether PRs must include test changes |
| `guardrails.max_open_prs` | Policy YAML | `3` | Max simultaneous Argos PRs |
| `guardrails.protected_paths` | Policy YAML | `[".env*", "*.secret", "config/production.*"]` | Files Argos must never modify |

**Files involved:**
- `/Users/divyekant/Projects/argos/skills/argos/SKILL.md` -- classification rules (section 3), action definitions (section 4), execution pipeline (section 5)
- `/Users/divyekant/Projects/argos/lib/policy.sh` -- `get_action_tier`, `is_path_protected`, `get_guardrail`
- `/Users/divyekant/Projects/argos/lib/state.sh` -- `set_last_issue_seen`, `add_pending_approval`, `increment_actions_count`
- `/Users/divyekant/Projects/argos/lib/notify.sh` -- `notify` for triage comments and approval requests

## Edge Cases

1. **Issue with conflicting labels.** If an issue has both "bug" and "enhancement" labels, the classification follows priority order (bug > enhancement > duplicate > question > other). Since existing labels are trusted without reclassification, the first matching label wins.

2. **Duplicate detection false positive.** Title similarity uses substring matching and keyword overlap, not exact matching. A 70% threshold can produce false positives for repos with similar issue naming conventions. The `close_duplicate` action is in the `auto` tier by default, so false-positive closures can happen without approval. Operators concerned about this should move `close_duplicate` to the `approve` tier.

3. **Issue body is extremely long.** There is no explicit truncation of the issue body before classification. Very long bodies increase LLM token consumption during classification. The `gh` CLI may also truncate extremely long bodies.

4. **Label not in whitelist.** If classification produces a label not in the allowed set (`bug enhancement duplicate question other security-review`), the `label` action logs a warning and skips -- it does not apply the invalid label.

5. **`max_open_prs` reached.** The `open_pr` action checks open PR count before creating. If the limit is reached, the action is silently skipped with a guardrail log, even if it was approved. The PR is not queued for later -- the user must manually intervene or wait for existing PRs to close.

## Common Questions

### Q1: What determines which actions run for each classification?

The classification determines context, but the set of actions is defined by the policy's tier lists. For example, if `label` is in `auto`, Argos applies a label for every new issue regardless of classification. The classification value affects what label is applied, what the triage comment says, and whether `close_duplicate` is triggered (only for `duplicate` classification). Actions like `comment_diagnosis`, `create_branch`, `push_commits`, and `open_pr` are typically relevant only for `bug` classifications but are gated by tier, not classification.

### Q2: How does duplicate detection work without a similarity API?

Argos fetches open issues for the repo and compares titles using substring matching and keyword overlap. It does not use embedding-based similarity. The 70% threshold refers to keyword overlap ratio. This is a heuristic, not a precise metric, and can be improved in future versions.

### Q3: Can Argos handle issues in languages other than English?

Classification rules reference English keywords ("crash", "error", "broken", etc.) and English question patterns ("how", "why", "is there"). Issues in other languages will likely be classified as `other` unless they carry an explicit label. Label-based classification works regardless of language.

### Q4: What happens if the codebase analysis for `comment_diagnosis` finds nothing relevant?

If no relevant files are found, the diagnosis comment states that no matching code was identified and suggests the issue may need manual investigation. The action still counts toward the rate limit and is recorded in Memories MCP.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Issue classified incorrectly | Heuristic keyword matching is imprecise | Add the correct label to the issue manually; Argos trusts existing labels |
| Duplicate not detected | Title similarity below 70% threshold | Close manually; consider adding a memory entry for future detection |
| False duplicate closure | Title keywords overlap coincidentally | Move `close_duplicate` to `approve` tier in the policy |
| `label` action skipped with whitelist warning | Classification produced a non-standard label | Check SKILL.md section 4 for the allowed label set |
| `open_pr` silently skipped | `max_open_prs` guardrail exceeded | Close or merge existing Argos PRs, or increase the guardrail value |
| Triage comment missing planned actions | Classification defaulted to `other` | Review issue content; if labels are missing, add them and let the next cycle reclassify |
