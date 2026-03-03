#!/usr/bin/env bash
setup() {
  TEST_TEMP="$(mktemp -d)"
  export TEST_TEMP
}

teardown() {
  rm -rf "$TEST_TEMP"
}
