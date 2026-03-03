#!/usr/bin/env bats

load test_helper

@test "script exists and is executable" {
  [ -x "hooks/session-start.sh" ]
}

@test "exits silently with no cwd" {
  echo '{}' | bash hooks/session-start.sh
}

@test "exits silently when no .kalos.yaml" {
  echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh
}

@test "returns status line when .kalos.yaml exists" {
  mkdir -p "$TEST_TEMP/.git"
  cat > "$TEST_TEMP/.kalos.yaml" << 'YAML'
extends: modern
version: 0.1.0
YAML
  cat > "$TEST_TEMP/CLAUDE.md" << 'MD'
# Test
<!-- KALOS:START -->
rules here
<!-- KALOS:END -->
MD

  result=$(echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh)
  echo "$result" | jq -e '.hookSpecificOutput.additionalContext' | grep -q "Kalos:"
}

@test "detects missing KALOS section in CLAUDE.md" {
  mkdir -p "$TEST_TEMP/.git"
  cat > "$TEST_TEMP/.kalos.yaml" << 'YAML'
extends: modern
version: 0.1.0
YAML
  echo "# No kalos section" > "$TEST_TEMP/CLAUDE.md"

  result=$(echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh)
  echo "$result" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "MISSING"
}

@test "detects drift when no CLAUDE.md exists" {
  mkdir -p "$TEST_TEMP/.git"
  cat > "$TEST_TEMP/.kalos.yaml" << 'YAML'
extends: modern
version: 0.1.0
YAML

  result=$(echo "{\"cwd\": \"$TEST_TEMP\"}" | bash hooks/session-start.sh)
  echo "$result" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "MISSING"
}
