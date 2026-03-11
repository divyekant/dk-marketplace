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

@test "--install detects arm64 architecture" {
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

@test "--install fails on unsupported architecture" {
  mock_uname() { echo "riscv64"; }
  export -f mock_uname
  PENCIL_UNAME_CMD="mock_uname" \
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_DOWNLOAD_DIR="${TEST_TEMP}/Downloads" \
  PENCIL_DRY_RUN=1 \
    run "${PENCIL_START}" --install
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported"* ]]
}

@test "--install skips if already installed" {
  mkdir -p "${TEST_TEMP}/Applications/Pencil.app"
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
    run "${PENCIL_START}" --install
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}

@test "--start fails if Pencil not installed" {
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_SYS_APP="${TEST_TEMP}/SysApplications/Pencil.app" \
  PENCIL_PGREP_CMD="false" \
    run "${PENCIL_START}" --start
  [ "$status" -eq 1 ]
  [[ "$output" == *"not installed"* ]]
}

@test "--start reports already running when process found" {
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_PGREP_CMD="echo 12345" \
    run "${PENCIL_START}" --start
  [ "$status" -eq 0 ]
  [[ "$output" == *"already running"* ]]
}

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

@test "no flag prints host-neutral activation instructions after first-time install" {
  MOCK_BIN="${TEST_TEMP}/mock-bin"
  mkdir -p "${MOCK_BIN}"

  cat > "${MOCK_BIN}/curl" <<'EOF'
#!/usr/bin/env bash
out=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    out="$2"
    shift 2
  else
    shift
  fi
done
touch "${out}"
EOF
  chmod +x "${MOCK_BIN}/curl"

  cat > "${MOCK_BIN}/hdiutil" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "attach" ]; then
  echo "/dev/disk9 Apple_HFS /Volumes/Pencil"
  exit 0
fi
if [ "$1" = "detach" ]; then
  exit 0
fi
exit 1
EOF
  chmod +x "${MOCK_BIN}/hdiutil"

  cat > "${MOCK_BIN}/cp" <<'EOF'
#!/usr/bin/env bash
dest="${3}"
mkdir -p "${dest}"
EOF
  chmod +x "${MOCK_BIN}/cp"

  PATH="${MOCK_BIN}:$PATH" \
  PENCIL_USER_APP="${TEST_TEMP}/Applications/Pencil.app" \
  PENCIL_SYS_APP="${TEST_TEMP}/SysApplications/Pencil.app" \
  PENCIL_DOWNLOAD_DIR="${TEST_TEMP}/Downloads" \
    run "${PENCIL_START}"

  [ "$status" -eq 2 ]
  [[ "$output" == *"ACTIVATE:"* ]]
  [[ "$output" == *"enable your agent integration in Settings → Agents and MCP"* ]]
}
