#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONNECT="$PROJECT_DIR/skills/research-agent/scripts/build-connections.sh"
KNOWLEDGE_DIR="$SCRIPT_DIR/fixtures/sample-knowledge-dir"
PASS=0
FAIL=0

assert_contains() {
  local label="$1" output="$2" expected="$3"
  if echo "$output" | grep -qF "$expected"; then
    echo "  ✅ $label"; PASS=$((PASS + 1))
  else
    echo "  ❌ $label — expected to find: $expected"; FAIL=$((FAIL + 1))
  fi
}

echo "=== Test: build-connections.sh ==="

OUTPUT=$("$CONNECT" "$KNOWLEDGE_DIR")

# Test 1: Finds cross-article entities
echo "Test 1: Finds cross-article entities"
assert_contains "MCP appears in multiple" "$OUTPUT" "MCP"

# Test 2: Shows which articles share entities
echo "Test 2: Shows co-occurrence articles"
assert_contains "langchain article" "$OUTPUT" "langchain"
assert_contains "crewai article" "$OUTPUT" "crewai"

# Test 3: Identifies the domain
echo "Test 3: Has connections section"
assert_contains "connections header" "$OUTPUT" "CONNECTIONS"

# Test 4: Identifies timeline
echo "Test 4: Has timeline section"
assert_contains "timeline header" "$OUTPUT" "TIMELINE"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
