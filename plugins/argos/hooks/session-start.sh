#!/bin/bash
# hooks/session-start.sh — Runs on CC session start (async)
# Summarizes pending Argos approvals and recent actions for the user.
# Outputs JSON with additional_context for the SessionStart hook.
set -euo pipefail

ARGOS_STATE_DIR="${ARGOS_STATE_DIR:-$HOME/.claude/argos/state}"
ARGOS_POLICY_DIR="${ARGOS_POLICY_DIR:-$HOME/.claude/argos/policies}"
ARGOS_SESSION_FILE="${ARGOS_SESSION_FILE:-$HOME/.claude/argos/session-context.txt}"

# ── 1. Check if any state exists ──────────────────────────────────────────────
if [[ ! -d "$ARGOS_STATE_DIR" ]] || [[ -z "$(ls -A "$ARGOS_STATE_DIR" 2>/dev/null)" ]]; then
  exit 0
fi

# ── Helper: parse duration string (e.g. "2h", "30m", "1d") to seconds ────────
duration_to_seconds() {
  local dur="$1"
  local num="${dur%[hHmMdD]}"
  local unit="${dur##*[0-9]}"
  case "$unit" in
    h|H) echo $((num * 3600)) ;;
    m|M) echo $((num * 60)) ;;
    d|D) echo $((num * 86400)) ;;
    *)   echo $((num * 3600)) ;;  # default to hours
  esac
}

# ── Helper: ISO date to epoch (portable macOS/Linux) ──────────────────────────
iso_to_epoch() {
  local iso="$1"
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso" "+%s" 2>/dev/null; then
    return
  fi
  # GNU date fallback
  date -d "$iso" "+%s" 2>/dev/null || echo "0"
}

now_epoch=$(date "+%s")

total_pending=0
repos_with_pending=0
expired_count=0

# ── 2. Process each state file ────────────────────────────────────────────────
for state_file in "$ARGOS_STATE_DIR"/*.json; do
  [[ -f "$state_file" ]] || continue

  basename_noext=$(basename "$state_file" .json)
  # Convert owner-repo back to owner/repo for policy lookup
  repo_slug="${basename_noext/-//}"

  pending_count=$(jq '.pending_approvals | length' "$state_file" 2>/dev/null || echo 0)
  [[ "$pending_count" -eq 0 ]] && continue

  # Find the matching policy file (try both owner-repo.yaml and owner-repo.yml)
  policy_file=""
  for ext in yaml yml; do
    candidate="$ARGOS_POLICY_DIR/$basename_noext.$ext"
    if [[ -f "$candidate" ]]; then
      policy_file="$candidate"
      break
    fi
  done

  # Load policy as JSON (needed for approval_modes)
  policy_json="{}"
  if [[ -n "$policy_file" ]]; then
    policy_json=$(python3 -c "
import yaml, json, sys
with open(sys.argv[1]) as f:
    print(json.dumps(yaml.safe_load(f)))
" "$policy_file" 2>/dev/null || echo '{}')
  fi

  # ── 2b. Check for expired timeouts ───────────────────────────────────────
  # Build a list of non-expired pending approvals
  indices_to_remove=()
  approval_count=$(jq '.pending_approvals | length' "$state_file")

  for ((i = 0; i < approval_count; i++)); do
    entry=$(jq -r ".pending_approvals[$i]" "$state_file")
    mode=$(echo "$entry" | jq -r '.mode // "wait"')
    proposed_at=$(echo "$entry" | jq -r '.proposed_at // ""')
    action=$(echo "$entry" | jq -r '.action // ""')

    # Only timeout and default modes expire; wait never expires automatically
    if [[ "$mode" == "wait" ]] || [[ -z "$proposed_at" ]]; then
      continue
    fi

    # Get timeout duration from policy
    timeout_dur=$(echo "$policy_json" | jq -r --arg action "$action" \
      '.approval_modes[$action].timeout // "24h"' 2>/dev/null || echo "24h")
    timeout_secs=$(duration_to_seconds "$timeout_dur")
    proposed_epoch=$(iso_to_epoch "$proposed_at")

    if [[ "$proposed_epoch" -eq 0 ]]; then
      continue
    fi

    expires_at=$((proposed_epoch + timeout_secs))

    if [[ "$now_epoch" -ge "$expires_at" ]]; then
      indices_to_remove+=("$i")
      expired_count=$((expired_count + 1))
    fi
  done

  # Remove expired entries from state (process in reverse to preserve indices)
  if [[ ${#indices_to_remove[@]} -gt 0 ]]; then
    tmp_file="${state_file}.tmp.$$"
    cp "$state_file" "$tmp_file"
    for ((j = ${#indices_to_remove[@]} - 1; j >= 0; j--)); do
      idx=${indices_to_remove[$j]}
      jq "del(.pending_approvals[$idx])" "$tmp_file" > "${tmp_file}.2"
      mv "${tmp_file}.2" "$tmp_file"
    done
    mv "$tmp_file" "$state_file"
  fi

  # Recount after removals
  remaining=$(jq '.pending_approvals | length' "$state_file" 2>/dev/null || echo 0)
  if [[ "$remaining" -gt 0 ]]; then
    total_pending=$((total_pending + remaining))
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

if [[ "$total_pending" -gt 0 ]]; then
  parts+=("$total_pending pending approval(s) across $repos_with_pending repo(s).")
fi

if [[ "$expired_count" -gt 0 ]]; then
  parts+=("$expired_count expired approval(s) auto-resolved.")
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
