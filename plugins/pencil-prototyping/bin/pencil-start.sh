#!/usr/bin/env bash
# bin/pencil-start.sh — Install, launch, and manage Pencil.dev

set -euo pipefail

# Configurable paths (overridable for testing)
PENCIL_USER_APP="${PENCIL_USER_APP:-$HOME/Applications/Pencil.app}"
PENCIL_SYS_APP="${PENCIL_SYS_APP:-/Applications/Pencil.app}"
PENCIL_DOWNLOAD_DIR="${PENCIL_DOWNLOAD_DIR:-$HOME/Downloads}"
PENCIL_DRY_RUN="${PENCIL_DRY_RUN:-0}"
PENCIL_UNAME_CMD="${PENCIL_UNAME_CMD:-uname -m}"
PENCIL_DMG_BASE="https://5ykymftd1soethh5.public.blob.vercel-storage.com"
PENCIL_PGREP_CMD="${PENCIL_PGREP_CMD:-pgrep -f Pencil.app}"
PENCIL_PORT="${PENCIL_PORT:-59066}"
PENCIL_TIMEOUT="${PENCIL_TIMEOUT:-15}"

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

detect_arch() {
  local arch
  # PENCIL_UNAME_CMD is eval'd for test injection; in production only the default is used
  arch="$(eval "${PENCIL_UNAME_CMD}")"
  case "${arch}" in
    arm64) echo "arm64" ;;
    x86_64) echo "x64" ;;
    *) echo "unknown"; return 1 ;;
  esac
}

is_running() {
  # PENCIL_PGREP_CMD is eval'd for test injection; in production only the default is used
  eval "${PENCIL_PGREP_CMD}" > /dev/null 2>&1
}

wait_for_port() {
  local timeout="${PENCIL_TIMEOUT}"
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
  local hdi_output mount_point
  hdi_output="$(hdiutil attach "${dmg_path}" -nobrowse 2>/dev/null)" || {
    echo "Failed to mount DMG. Install manually from https://www.pencil.dev/downloads"
    rm -f "${dmg_path}"
    return 1
  }
  mount_point="$(echo "${hdi_output}" | grep -o '/Volumes/.*$' | head -1)"

  if [ -z "${mount_point}" ]; then
    echo "Failed to determine mount point. Install manually from https://www.pencil.dev/downloads"
    rm -f "${dmg_path}"
    return 1
  fi

  echo "Copying Pencil.app to ~/Applications..."
  mkdir -p "$(dirname "${PENCIL_USER_APP}")"
  cp -R "${mount_point}/Pencil.app" "${PENCIL_USER_APP}"

  echo "Cleaning up..."
  hdiutil detach "${mount_point}" 2>/dev/null || echo "Warning: could not unmount ${mount_point}"
  rm -f "${dmg_path}"

  echo "Pencil installed at ${PENCIL_USER_APP}"
  return 2  # Needs activation
}

report_status() {
  local installed="no" running="no" port="no" pencil_path

  if pencil_path="$(find_pencil 2>/dev/null)"; then
    installed="yes (${pencil_path})"
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
    local install_exit=0
    install_pencil || install_exit=$?
    if [ "${install_exit}" -eq 2 ]; then
      echo "ACTIVATE: Open Pencil, activate with your email, then enable your agent integration in Settings → Agents and MCP"
      exit 2
    elif [ "${install_exit}" -ne 0 ]; then
      exit 1
    fi
  fi

  # Step 2: Start
  start_pencil
}

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
    --check) check_installed; exit $? ;;
    --install) install_pencil; exit $? ;;
    --start) start_pencil; exit $? ;;
    --status) report_status; exit 0 ;;
    "") full_sequence ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
}

main "$@"
