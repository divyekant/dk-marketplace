---
id: fh-001
type: feature-handoff
audience: internal
topic: Issue Monitoring
status: draft
generated: 2026-03-06
source-tier: direct
hermes-version: 1.0.0
---

# Feature Handoff: Issue Monitoring

## What It Does

Issue Monitoring is the polling subsystem that detects new GitHub issues on watched repositories. It runs on a configurable interval via `/loop`, fetches open issues through the `gh` CLI, applies a series of filters defined in the repo's policy, and passes only genuinely new, relevant issues into the triage pipeline. When no new issues exist, the cycle exits immediately with zero LLM cost.

## How It Works

### Core Flow

1. `/loop` invokes the Argos skill at the configured `poll_interval` (default `5m`).
2. The skill sources `lib/poll.sh` and calls `fetch_issues "$REPO"`, which executes `gh issue list` with JSON output, capped at 50 results per poll.
3. Raw JSON from `gh` is piped through `parse_issues`, which normalizes it into a consistent structure (number, title, labels, created_at, url, author, body).
4. Four filters run in sequence:
   - `filter_new_issues "$LAST_SEEN"` -- discards issues with a number at or below the watermark stored in state.
   - `filter_by_labels "$FILTER_LABELS"` -- keeps only issues that carry at least one of the policy's watched labels, or have no labels at all (so unlabeled issues never slip through).
   - `filter_ignore_labels "$IGNORE_LABELS"` -- drops issues that carry any of the ignore labels (e.g., `wontfix`, `on-hold`).
   - `filter_max_age "$MAX_AGE"` -- drops issues older than the configured maximum age (default 7 days), using ISO timestamp comparison.
5. If the resulting count is zero, the skill returns immediately.
6. Otherwise, the filtered issues proceed to classification and action (see fh-003).

### Key Implementation Details

- `fetch_issues` accepts an optional `since` parameter. When provided, it appends `--search "created:>=$since"` to narrow the API query server-side.
- `parse_issues` uses `jq` to extract `.labels[]?.name` into a flat array, and defaults `.body` to an empty string if null.
- `filter_by_labels` with an empty wanted-labels array passes all issues through (no filter applied).
- `filter_max_age` computes a cutoff date using `date -v-Nd` on macOS or `date -d "N days ago"` on Linux. If neither date variant works, it falls back to passing all issues through.
- The `has_new_issues` convenience function runs the full fetch-parse-filter pipeline and returns a boolean, useful for quick checks.

### State Watermark

After each issue is processed, `set_last_issue_seen "$REPO" "$NUMBER"` advances the watermark in the state file (`~/.claude/argos/state/<owner>-<repo>.json`). This ensures the same issue is never processed twice, even across CC sessions.

## Configuration

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `poll_interval` | Policy YAML root | `5m` | How often `/loop` triggers the skill |
| `filters.labels` | Policy YAML | `["bug", "enhancement", "help-wanted"]` | Issue labels to watch for. Empty list means all labels. |
| `filters.ignore_labels` | Policy YAML | `["wontfix", "on-hold", "discussion"]` | Issues with these labels are skipped |
| `filters.only_new` | Policy YAML | `true` | Only process issues newer than the watermark |
| `filters.max_age` | Policy YAML | `7d` | Maximum age for issues to be considered |

**Files involved:**
- `/Users/divyekant/Projects/argos/lib/poll.sh` -- all polling and filtering functions
- `/Users/divyekant/Projects/argos/lib/state.sh` -- watermark management (`get_last_issue_seen`, `set_last_issue_seen`)
- `/Users/divyekant/Projects/argos/config/default-policy.yaml` -- default filter values

## Edge Cases

1. **gh CLI auth expired or rate-limited.** `fetch_issues` wraps the `gh` call with `2>/dev/null || echo "[]"`. If `gh` fails for any reason (auth, network, API rate limit), the function returns an empty JSON array and the cycle ends with no action.

2. **Issues with no labels.** `filter_by_labels` explicitly passes unlabeled issues through when a labels filter is configured. This is intentional -- unlabeled issues should still be caught and triaged rather than silently dropped.

3. **Repo with >50 open issues.** `fetch_issues` caps at `--limit 50` per poll. If a repo has more than 50 open issues, only the 50 most recent are returned. The watermark system ensures that once processed, issues are not re-evaluated, so the backlog is worked through over multiple polls. However, on initial `/watch` of a busy repo, older issues beyond the 50-issue window may never be seen.

4. **Date parsing differences between macOS and Linux.** `filter_max_age` tries macOS `date -v-Nd` first, then falls back to GNU `date -d`. If neither works (e.g., on a non-standard platform), the filter is a no-op (all issues pass through).

5. **State file missing or corrupted.** If `get_last_issue_seen` fails to read the state file, `jq` returns `0`, effectively treating all issues as new. The `init_state` function creates a fresh state file if none exists.

## Common Questions

### Q1: What happens if the same issue is opened, closed, and reopened?

Argos tracks issues by number watermark, not by open/closed state. Since `filter_new_issues` uses `select(.number > $last)`, a reopened issue with a number below the watermark is not reprocessed. This is by design -- once Argos has triaged an issue, it does not revisit it. A human should handle reopened issues.

### Q2: Can I change the poll interval without re-running onboarding?

Yes. Edit the `poll_interval` field in `~/.claude/argos/policies/<owner>-<repo>.yaml` directly. The change takes effect on the next `/loop` iteration. Note that you must also restart the `/loop` command with the new interval, since `/loop` uses its own timer.

### Q3: How much does each poll cost in tokens?

A poll that finds zero new issues costs zero LLM tokens. The entire fetch-filter pipeline is pure bash and `jq` -- no Claude invocation occurs. LLM tokens are only consumed when the classification and action pipeline runs on new issues.

### Q4: Does Argos handle GitHub API pagination?

No. The `--limit 50` cap means Argos fetches at most 50 issues per poll. For repos with very high issue velocity (>50 new issues in a single poll interval), some issues may be missed until the next cycle. Increasing the limit or decreasing the interval can mitigate this.

### Q5: What if the `jq` parse fails on issue data?

Per SKILL.md section 9, if issue content causes a `jq` parse error, the issue is skipped and processing continues to the next one. The error is logged to Memories MCP with the prefix `argos/<owner>/<repo>/error:`.

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| No issues are ever detected | `gh auth` not valid, or repo name is wrong | Run `gh auth status` and verify `gh repo view owner/repo` works |
| Issues are detected but immediately filtered out | `filters.labels` in policy does not match the labels on incoming issues | Check policy YAML; remember unlabeled issues pass through by default |
| Same issues reprocessed every cycle | State file not being written, or `ARGOS_STATE_DIR` is not persistent | Verify `~/.claude/argos/state/<owner>-<repo>.json` exists and `last_issue_seen` increments |
| Old issues are being picked up on first watch | `max_age` is set too high, or all issues are within the age window | Set `max_age` to a shorter duration (e.g., `1d`) during onboarding, or manually set `last_issue_seen` in the state file |
| `filter_max_age` not filtering anything | Date command variant not recognized on this platform | Test with `date -u -v-7d` (macOS) or `date -u -d "7 days ago"` (Linux) manually |
| `gh` returns partial results | GitHub API rate limiting (5000 requests/hour for authenticated users) | Increase `poll_interval` to reduce API calls, or check `gh api rate_limit` |
