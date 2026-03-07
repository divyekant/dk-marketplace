---
description: "Stop watching a GitHub repo for new issues"
argument-hint: "owner/repo"
allowed-tools: ["Bash"]
---

# Unwatch Command

You've been asked to stop watching a GitHub repo.

## Arguments

The user provided: `$ARGUMENTS`

Parse the repo from arguments (owner/repo format).

## Stop Watching

1. Clean up state file (optionally -- ask user if they want to preserve history):
   ```bash
   SAFE_NAME="${REPO//\//-}"
   STATE_FILE="$HOME/.claude/argos/state/${SAFE_NAME}.json"
   ```

2. Warn the user clearly:
   "The polling loop is still running — stop it manually (CC doesn't have a /loop stop API yet). Your policy and state have been cleaned up."

3. Optionally remove the policy file (ask first -- user may want to keep it for later).

4. Confirm: "Argos has stopped watching `owner/repo`."
