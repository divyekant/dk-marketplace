# pencil-prototyping Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude Code skill that launches Pencil.dev on demand and enables visual prototyping from any conversation.

**Architecture:** Shell script (`bin/pencil-start.sh`) handles install/launch/readiness. Skill instructions (`skill.md`) orchestrate the flow: detect state, run script, handle MCP connection, create canvases, draw prototypes, capture screenshots.

**Tech Stack:** Bash (script), Markdown (skill), bats (testing)

---

### Task 1: Set up bats testing framework

**Files:**
- Create: `test/pencil-start.bats`
- Create: `test/test_helper.bash`

**Step 1: Install bats-core**

Run: `~/homebrew/bin/brew install bats-core`
Expected: bats installed at `~/homebrew/bin/bats`

**Step 2: Create test helper with common setup**

```bash
# test/test_helper.bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PENCIL_START="${SCRIPT_DIR}/bin/pencil-start.sh"

# Mock directory for test isolation
setup() {
  TEST_TEMP="$(mktemp -d)"
  export PENCIL_APP_PATH="${TEST_TEMP}/Applications/Pencil.app"
  export PENCIL_DOWNLOAD_DIR="${TEST_TEMP}/Downloads"
  mkdir -p "${PENCIL_DOWNLOAD_DIR}"
}

teardown() {
  rm -rf "${TEST_TEMP}"
}
```

**Step 3: Create initial test file with a smoke test**

```bash
# test/pencil-start.bats
#!/usr/bin/env bats

load test_helper

@test "script exists and is executable" {
  [ -f "${PENCIL_START}" ]
  [ -x "${PENCIL_START}" ]
}

@test "--help prints usage" {
  run "${PENCIL_START}" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage"* ]]
}
```

**Step 4: Create minimal bin/pencil-start.sh to make smoke test pass**

```bash
#!/usr/bin/env bash
# bin/pencil-start.sh — Install, launch, and manage Pencil.dev

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: pencil-start.sh [OPTIONS]

Options:
  --check     Check if Pencil is installed (exit 0=yes, 1=no)
  --install   Download and install Pencil
  --start     Launch Pencil and wait for readiness
  --status    Report install/running/port state
  --help      Show this help

No flag: run full sequence (check → install if needed → start)

Exit codes:
  0  Success (Pencil installed and running)
  1  Failure (timeout, download error, etc.)
  2  Installed but needs activation (first-time)
USAGE
}

main() {
  case "${1:-}" in
    --help) usage; exit 0 ;;
    *) usage; exit 0 ;;
  esac
}

main "$@"
```

**Step 5: Run tests**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: 2 tests, 2 passed

**Step 6: Commit**

```bash
git add bin/pencil-start.sh test/
git commit -m "chore: set up bats testing and initial script skeleton"
```

---

### Task 2: Implement --check flag

**Files:**
- Modify: `bin/pencil-start.sh`
- Modify: `test/pencil-start.bats`

**Step 1: Write the failing tests**

```bash
@test "--check returns 0 when Pencil.app exists at user Applications" {
  mkdir -p "${TEST_TEMP}/Applications/Pencil.app"
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
    run "${PENCIL_START}" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"installed"* ]]
}

@test "--check returns 0 when Pencil.app exists at system Applications" {
  mkdir -p "${TEST_TEMP}/SysApplications/Pencil.app"
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_SYS_APP="${TEST_TEMP}/SysApplications/Pencil.app" \
    run "${PENCIL_START}" --check
  [ "$status" -eq 0 ]
}

@test "--check returns 1 when Pencil.app not found" {
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_SYS_APP="${TEST_TEMP}/SysApplications/Pencil.app" \
    run "${PENCIL_START}" --check
  [ "$status" -eq 1 ]
  [[ "$output" == *"not installed"* ]]
}
```

**Step 2: Run tests to verify they fail**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: 3 failures

**Step 3: Implement --check in pencil-start.sh**

Add configurable paths (for testability) and check_installed function:

```bash
# Configurable paths (overridable for testing)
PENCIL_USER_APP="${PENCIL_USER_APP:-$HOME/Applications/Pencil.app}"
PENCIL_SYS_APP="${PENCIL_SYS_APP:-/Applications/Pencil.app}"

find_pencil() {
  if [ -d "${PENCIL_USER_APP}" ]; then
    echo "${PENCIL_USER_APP}"
    return 0
  elif [ -d "${PENCIL_SYS_APP}" ]; then
    echo "${PENCIL_SYS_APP}"
    return 0
  fi
  return 1
}

check_installed() {
  local path
  if path="$(find_pencil)"; then
    echo "Pencil is installed at ${path}"
    return 0
  else
    echo "Pencil is not installed"
    return 1
  fi
}
```

Update main case: `--check) check_installed; exit $? ;;`

**Step 4: Run tests**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: All pass

**Step 5: Commit**

```bash
git add bin/pencil-start.sh test/pencil-start.bats
git commit -m "feat: add --check flag to detect Pencil installation"
```

---

### Task 3: Implement --install flag

**Files:**
- Modify: `bin/pencil-start.sh`
- Modify: `test/pencil-start.bats`

**Step 1: Write the failing tests**

```bash
@test "--install detects arm64 architecture" {
  # Mock uname
  mock_uname() { echo "arm64"; }
  export -f mock_uname
  PENCIL_UNAME_CMD="mock_uname" \
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_DOWNLOAD_DIR="${TEST_TEMP}/Downloads" \
  PENCIL_DRY_RUN=1 \
    run "${PENCIL_START}" --install
  [[ "$output" == *"arm64"* ]]
}

@test "--install detects x86_64 architecture" {
  mock_uname() { echo "x86_64"; }
  export -f mock_uname
  PENCIL_UNAME_CMD="mock_uname" \
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_DOWNLOAD_DIR="${TEST_TEMP}/Downloads" \
  PENCIL_DRY_RUN=1 \
    run "${PENCIL_START}" --install
  [[ "$output" == *"x64"* ]]
}

@test "--install skips if already installed" {
  mkdir -p "${TEST_TEMP}/Applications/Pencil.app"
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
    run "${PENCIL_START}" --install
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}
```

**Step 2: Run tests to verify they fail**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: 3 new failures

**Step 3: Implement --install**

```bash
PENCIL_DOWNLOAD_DIR="${PENCIL_DOWNLOAD_DIR:-$HOME/Downloads}"
PENCIL_DRY_RUN="${PENCIL_DRY_RUN:-0}"
PENCIL_UNAME_CMD="${PENCIL_UNAME_CMD:-uname -m}"
PENCIL_DMG_BASE="https://5ykymftd1soethh5.public.blob.vercel-storage.com"

detect_arch() {
  local arch
  arch="$(eval "${PENCIL_UNAME_CMD}")"
  case "${arch}" in
    arm64) echo "arm64" ;;
    x86_64) echo "x64" ;;
    *) echo "unknown"; return 1 ;;
  esac
}

install_pencil() {
  if find_pencil > /dev/null 2>&1; then
    echo "Pencil is already installed"
    return 0
  fi

  local arch dmg_name dmg_url dmg_path

  arch="$(detect_arch)" || { echo "Unsupported architecture"; return 1; }
  dmg_name="Pencil-mac-${arch}.dmg"
  dmg_url="${PENCIL_DMG_BASE}/${dmg_name}"
  dmg_path="${PENCIL_DOWNLOAD_DIR}/${dmg_name}"

  echo "Detected architecture: ${arch}"
  echo "Downloading ${dmg_name}..."

  if [ "${PENCIL_DRY_RUN}" = "1" ]; then
    echo "DRY RUN: would download ${dmg_url} to ${dmg_path}"
    return 0
  fi

  curl -fSL -o "${dmg_path}" "${dmg_url}" || {
    echo "Download failed. Install manually from https://www.pencil.dev/downloads"
    return 1
  }

  echo "Mounting DMG..."
  local mount_point
  mount_point="$(hdiutil attach "${dmg_path}" -nobrowse 2>/dev/null | grep '/Volumes/' | awk '{print $NF}')"

  if [ -z "${mount_point}" ]; then
    # Try alternative parsing — hdiutil output can vary
    mount_point="$(hdiutil attach "${dmg_path}" -nobrowse 2>/dev/null | tail -1 | sed 's/.*\(\/Volumes\/.*\)/\1/')"
  fi

  echo "Copying Pencil.app to ~/Applications..."
  mkdir -p "$(dirname "${PENCIL_USER_APP}")"
  cp -R "${mount_point}/Pencil.app" "${PENCIL_USER_APP}"

  echo "Cleaning up..."
  hdiutil detach "${mount_point}" 2>/dev/null
  rm -f "${dmg_path}"

  echo "Pencil installed at ${PENCIL_USER_APP}"
  return 2  # Needs activation
}
```

Update main case: `--install) install_pencil; exit $? ;;`

**Step 4: Run tests**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: All pass

**Step 5: Commit**

```bash
git add bin/pencil-start.sh test/pencil-start.bats
git commit -m "feat: add --install flag for automated Pencil download"
```

---

### Task 4: Implement --start flag

**Files:**
- Modify: `bin/pencil-start.sh`
- Modify: `test/pencil-start.bats`

**Step 1: Write the failing tests**

```bash
@test "--start fails if Pencil not installed" {
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_SYS_APP="${TEST_TEMP}/SysApplications/Pencil.app" \
    run "${PENCIL_START}" --start
  [ "$status" -eq 1 ]
  [[ "$output" == *"not installed"* ]]
}

@test "--start reports already running when process found" {
  # Mock pgrep to simulate running process
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_PGREP_CMD="echo 12345" \
    run "${PENCIL_START}" --start
  [ "$status" -eq 0 ]
  [[ "$output" == *"already running"* ]]
}
```

**Step 2: Run tests to verify they fail**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: 2 new failures

**Step 3: Implement --start**

```bash
PENCIL_PGREP_CMD="${PENCIL_PGREP_CMD:-pgrep -f Pencil.app}"
PENCIL_PORT="${PENCIL_PORT:-59066}"
PENCIL_START_TIMEOUT="${PENCIL_START_TIMEOUT:-15}"

is_running() {
  eval "${PENCIL_PGREP_CMD}" > /dev/null 2>&1
}

wait_for_port() {
  local timeout="${PENCIL_START_TIMEOUT}"
  local elapsed=0
  echo "Waiting for Pencil on port ${PENCIL_PORT}..."
  while [ "${elapsed}" -lt "${timeout}" ]; do
    if curl -sf "http://localhost:${PENCIL_PORT}" > /dev/null 2>&1; then
      echo "Pencil is ready on port ${PENCIL_PORT}"
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  echo "Timeout waiting for Pencil (${timeout}s)"
  return 1
}

start_pencil() {
  local pencil_path

  if is_running; then
    echo "Pencil is already running"
    return 0
  fi

  pencil_path="$(find_pencil)" || {
    echo "Pencil is not installed. Run with --install first."
    return 1
  }

  echo "Launching Pencil..."
  open "${pencil_path}"
  wait_for_port
}
```

Update main case: `--start) start_pencil; exit $? ;;`

**Step 4: Run tests**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: All pass

**Step 5: Commit**

```bash
git add bin/pencil-start.sh test/pencil-start.bats
git commit -m "feat: add --start flag to launch Pencil and wait for readiness"
```

---

### Task 5: Implement --status flag and default (no flag) behavior

**Files:**
- Modify: `bin/pencil-start.sh`
- Modify: `test/pencil-start.bats`

**Step 1: Write the failing tests**

```bash
@test "--status reports not installed" {
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_SYS_APP="${TEST_TEMP}/SysApplications/Pencil.app" \
  PENCIL_PGREP_CMD="false" \
    run "${PENCIL_START}" --status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installed: no"* ]]
  [[ "$output" == *"Running: no"* ]]
}

@test "--status reports installed but not running" {
  mkdir -p "${TEST_TEMP}/Applications/Pencil.app"
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_PGREP_CMD="false" \
    run "${PENCIL_START}" --status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installed: yes"* ]]
  [[ "$output" == *"Running: no"* ]]
}

@test "no flag runs full sequence — skips install when already installed" {
  mkdir -p "${TEST_TEMP}/Applications/Pencil.app"
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_PGREP_CMD="echo 12345" \
    run "${PENCIL_START}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already running"* ]]
}
```

**Step 2: Run tests to verify they fail**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: 3 new failures

**Step 3: Implement --status and default behavior**

```bash
report_status() {
  local installed="no" running="no" port="no"

  if find_pencil > /dev/null 2>&1; then
    installed="yes ($(find_pencil))"
  fi

  if is_running; then
    running="yes (PID: $(eval "${PENCIL_PGREP_CMD}" | head -1))"
  fi

  if curl -sf "http://localhost:${PENCIL_PORT}" > /dev/null 2>&1; then
    port="yes (${PENCIL_PORT})"
  fi

  echo "Pencil Status:"
  echo "  Installed: ${installed}"
  echo "  Running: ${running}"
  echo "  Port: ${port}"
}

full_sequence() {
  # Step 1: Check/Install
  if ! find_pencil > /dev/null 2>&1; then
    install_pencil
    local install_exit=$?
    if [ "${install_exit}" -eq 2 ]; then
      echo "ACTIVATE: Open Pencil, activate with your email, then enable Claude Code in Settings → Agents and MCP"
      exit 2
    elif [ "${install_exit}" -ne 0 ]; then
      exit 1
    fi
  fi

  # Step 2: Start
  start_pencil
}
```

Update main:
```bash
main() {
  case "${1:-}" in
    --help) usage; exit 0 ;;
    --check) check_installed; exit $? ;;
    --install) install_pencil; exit $? ;;
    --start) start_pencil; exit $? ;;
    --status) report_status; exit 0 ;;
    "") full_sequence ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
}
```

**Step 4: Run tests**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: All pass

**Step 5: Commit**

```bash
git add bin/pencil-start.sh test/pencil-start.bats
git commit -m "feat: add --status flag and default full-sequence behavior"
```

---

### Task 6: Write skill.md

**Files:**
- Create: `skill.md`

**Step 1: Write skill.md**

```markdown
---
name: pencil-prototyping
description: Launch Pencil.dev on demand and prototype visuals on a canvas. Handles install, launch, MCP connection, canvas creation, drawing, and screenshot capture.
argument-hint: "<topic> [--path=docs/designs/] [--open=existing.pen]"
allowed-tools: Bash, Read, mcp__pencil__batch_design, mcp__pencil__batch_get, mcp__pencil__get_editor_state, mcp__pencil__get_guidelines, mcp__pencil__get_screenshot, mcp__pencil__get_style_guide, mcp__pencil__get_style_guide_tags, mcp__pencil__get_variables, mcp__pencil__set_variables, mcp__pencil__open_document, mcp__pencil__snapshot_layout, mcp__pencil__find_empty_space_on_canvas, mcp__pencil__search_all_unique_properties, mcp__pencil__replace_all_matching_properties, AskUserQuestion, Skill
---

# Pencil Prototyping

Prototype visuals on a Pencil.dev canvas — on demand, from any conversation.

## Step 1: Ensure Pencil is Ready

Run the startup script:

```bash
bash ~/.claude/skills/pencil-prototyping/bin/pencil-start.sh
```

**Interpret exit codes:**
- **Exit 0** → Pencil is installed and running. Continue to Step 2.
- **Exit 1** → Something failed (download, timeout). Show the error output to the user and stop.
- **Exit 2** → First-time install. Tell the user:
  > Pencil has been installed. Please:
  > 1. Activate with your email in the Pencil window
  > 2. Go to Settings → Agents and MCP → enable Claude Code
  > 3. Confirm when done

  After user confirms, invoke the `restart` skill to restart Claude Code for MCP connection.

## Step 2: Check MCP Connection

After Step 1 succeeds (exit 0), check if Pencil MCP tools are available by calling:

```
mcp__pencil__get_editor_state
```

- **If it works** → MCP is connected. Continue to Step 3.
- **If it errors** → Pencil is running but MCP isn't connected (CC was started before Pencil). Tell the user:
  > Pencil is running but MCP isn't connected yet. Restarting Claude Code to establish the connection.

  Invoke the `restart` skill.

## Step 3: Create or Open Canvas

Parse the user's arguments:
- `<topic>` → the subject of the prototype (e.g., "login-flow", "dashboard")
- `--path=<dir>` → custom output directory (default: `docs/designs/` in current project)
- `--open=<file.pen>` → open an existing .pen file instead of creating new

**For new canvas:**
1. Create the output directory if it doesn't exist: `mkdir -p <path>`
2. Call `mcp__pencil__open_document` with `filePathOrTemplate: "new"`
3. Note: the .pen file will be saved by the user in Pencil (File → Save As to `<path>/<topic>.pen`)

**For existing file:**
1. Call `mcp__pencil__open_document` with `filePathOrTemplate: "<absolute-path>"`

## Step 4: Prototype

Now use the Pencil MCP tools to design:

1. **Get design guidelines** — call `get_guidelines` with the relevant topic (`landing-page`, `design-system`, `web-app`, `mobile-app`, etc.)
2. **Get style guide** — call `get_style_guide_tags` then `get_style_guide` with relevant tags for visual direction
3. **Get available components** — call `batch_get` with `patterns: [{ reusable: true }]` to see what components are available
4. **Design** — use `batch_design` to create shapes, insert components, update properties
5. **Verify** — call `get_screenshot` periodically to verify the design looks correct
6. **Iterate** — ask the user for feedback, make adjustments

## Step 5: Capture

When the user is satisfied with the prototype:

1. Call `get_screenshot` for the final state
2. Tell the user where the .pen file and screenshot are saved
3. Suggest: "You can continue editing in Pencil, or I can make more changes."

## Conductor Integration

This skill is available at any point in any pipeline. During explore/shape phases, proactively offer:
> I can prototype this visually on a canvas — want me to open Pencil?
```

**Step 2: Verify skill.md has correct frontmatter**

Run: `head -5 ~/Projects/pencil-prototyping/skill.md`
Expected: YAML frontmatter with name, description, argument-hint

**Step 3: Commit**

```bash
git add skill.md
git commit -m "feat: add skill.md with prototyping flow instructions"
```

---

### Task 7: Create symlink and verify end-to-end

**Files:**
- No new files — verification only

**Step 1: Create symlink**

Run: `ln -sf ~/Projects/pencil-prototyping ~/.claude/skills/pencil-prototyping`
Expected: symlink created

**Step 2: Verify skill is discoverable**

Run: `ls -la ~/.claude/skills/pencil-prototyping/skill.md`
Expected: file exists and is readable

**Step 3: Verify script is executable**

Run: `chmod +x ~/Projects/pencil-prototyping/bin/pencil-start.sh && ls -la ~/Projects/pencil-prototyping/bin/pencil-start.sh`
Expected: `-rwxr-xr-x`

**Step 4: Run all tests**

Run: `cd ~/Projects/pencil-prototyping && ~/homebrew/bin/bats test/`
Expected: All tests pass

**Step 5: Run pencil-start.sh --status**

Run: `bash ~/Projects/pencil-prototyping/bin/pencil-start.sh --status`
Expected: Shows Pencil as installed and running (since we installed it earlier)

**Step 6: Commit any remaining changes**

```bash
git add -A
git commit -m "chore: verify end-to-end setup"
```

---

### Task 8: Final documentation pass

**Files:**
- Modify: `README.md` (update if any details changed during implementation)
- Modify: `CHANGELOG.md` (update with all features)

**Step 1: Update CHANGELOG.md**

Add entries for all features implemented:

```markdown
## [0.1.0] - 2026-03-02

### Added
- `bin/pencil-start.sh` with --check, --install, --start, --status flags
- Automated Pencil.dev download and installation (ARM64 + x86_64)
- Port readiness polling with configurable timeout
- `skill.md` with full prototyping flow (install → launch → canvas → draw → capture)
- Conductor integration as always-available + shape phase skill
- bats test suite
```

**Step 2: Verify README accuracy**

Read through README.md. Verify install instructions, usage examples, and prerequisites match actual implementation.

**Step 3: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: update changelog and verify readme for v0.1.0"
```
