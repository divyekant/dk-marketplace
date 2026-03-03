#!/usr/bin/env bats

load test_helper

@test "script exists and is executable" {
  [ -x bin/capture.sh ]
}

@test "prints usage with no arguments" {
  run bash bin/capture.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "prints usage with --help" {
  run bash bin/capture.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "fails gracefully when no browser tool available" {
  CAPTURE_NPX_CMD="false" run bash bin/capture.sh "https://example.com" "$TEST_TEMP/output"
  [ "$status" -eq 2 ]
  [[ "$output" == *"No headless browser available"* ]]
}

@test "detects puppeteer availability" {
  CAPTURE_NPX_CMD="echo puppeteer" run bash bin/capture.sh --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"puppeteer"* ]] || [[ "$output" == *"playwright"* ]]
}

@test "validates URL format" {
  run bash bin/capture.sh "not-a-url" "$TEST_TEMP/output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid URL"* ]]
}

@test "validates output directory exists" {
  run bash bin/capture.sh "https://example.com" "/nonexistent/path/output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Output directory"* ]]
}
