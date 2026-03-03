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
