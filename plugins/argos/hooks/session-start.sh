#!/bin/bash
# hooks/session-start.sh — Runs on CC session start (async)
# Summarizes pending Argos approvals and recent actions for the user.
# Outputs JSON with additional_context for the SessionStart hook.
set -euo pipefail

ARGOS_STATE_DIR="${ARGOS_STATE_DIR:-$HOME/.claude/argos/state}"
ARGOS_SESSION_FILE="${ARGOS_SESSION_FILE:-$HOME/.claude/argos/session-context.txt}"

# ── 1. Check if any state exists ──────────────────────────────────────────────
if [[ ! -d "$ARGOS_STATE_DIR" ]] || [[ -z "$(ls -A "$ARGOS_STATE_DIR" 2>/dev/null)" ]]; then
  exit 0
fi

issue_pending=0
pr_pending=0
repos_with_pending=0

# ── 2. Count pending approvals across state files ─────────────────────────────
# Count by type: "issue" or null for issues, "pr" for PR reviews
for state_file in "$ARGOS_STATE_DIR"/*.json; do
  [[ -f "$state_file" ]] || continue

  file_issue=$(jq '[.pending_approvals[] | select(.type == "issue" or .type == null)] | length' "$state_file" 2>/dev/null || echo 0)
  file_pr=$(jq '[.pending_approvals[] | select(.type == "pr")] | length' "$state_file" 2>/dev/null || echo 0)
  file_total=$((file_issue + file_pr))
  if [[ "$file_total" -gt 0 ]]; then
    issue_pending=$((issue_pending + file_issue))
    pr_pending=$((pr_pending + file_pr))
    repos_with_pending=$((repos_with_pending + 1))
  fi
done

# ── 3. Read and clear session context ─────────────────────────────────────────
recent_actions=0
if [[ -f "$ARGOS_SESSION_FILE" ]]; then
  recent_actions=$(wc -l < "$ARGOS_SESSION_FILE" | tr -d ' ')
  # Clear the file after reading
  : > "$ARGOS_SESSION_FILE"
fi

# ── 4. Output JSON ───────────────────────────────────────────────────────────
parts=()

if [[ "$issue_pending" -gt 0 ]] || [[ "$pr_pending" -gt 0 ]]; then
  parts+=("$issue_pending issue approval(s) and $pr_pending PR review(s) pending across $repos_with_pending repo(s).")
fi

if [[ "$recent_actions" -gt 0 ]]; then
  parts+=("$recent_actions action(s) taken since last session.")
fi

if [[ ${#parts[@]} -eq 0 ]]; then
  cat <<EOF
{
  "additional_context": ""
}
EOF
else
  summary="Argos: ${parts[*]} Run /argos-status for details."
  # Use jq to safely encode the string as JSON (strip trailing newline)
  context=$(printf '%s' "$summary" | jq -Rs '.')
  cat <<EOF
{
  "additional_context": $context
}
EOF
fi
