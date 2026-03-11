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

1. Clean up worktrees and branches used for PR reviews:
   ```bash
   SAFE_NAME="${REPO//\//-}"
   PROJECT_PATH=$(jq -r '.project_path // empty' "$HOME/.claude/argos/state/${SAFE_NAME}.json" 2>/dev/null)
   if [[ -n "$PROJECT_PATH" ]]; then
     # Remove all Argos worktrees
     for wt in "$PROJECT_PATH/.argos/worktrees"/*/; do
       if [[ -d "$wt" ]]; then
         git -C "$PROJECT_PATH" worktree remove --force "$wt" 2>/dev/null
       fi
     done
     rm -rf "$PROJECT_PATH/.argos/worktrees" 2>/dev/null
     # Clean up local argos/* branches
     git -C "$PROJECT_PATH" branch --list 'argos/*' | while read -r branch; do
       git -C "$PROJECT_PATH" branch -D "$branch" 2>/dev/null
     done
   fi
   ```

2. Clean up state file (optionally -- ask user if they want to preserve history):
   ```bash
   STATE_FILE="$HOME/.claude/argos/state/${SAFE_NAME}.json"
   ```

3. Warn the user clearly:
   "The polling loop is still running — stop it manually (CC doesn't have a /loop stop API yet). Your policy and state have been cleaned up."

4. Optionally remove the policy file (ask first -- user may want to keep it for later).

5. Confirm: "Argos has stopped watching `owner/repo`."
