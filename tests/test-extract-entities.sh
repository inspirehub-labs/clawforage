#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EXTRACT="$PROJECT_DIR/skills/research-agent/scripts/extract-entities.sh"
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

assert_line_count_gte() {
  local label="$1" output="$2" min="$3"
  local count
  count=$(echo "$output" | wc -l | tr -d ' ')
  if [ "$count" -ge "$min" ]; then
    echo "  ✅ $label (got $count lines)"; PASS=$((PASS + 1))
  else
    echo "  ❌ $label — expected >= $min lines, got $count"; FAIL=$((FAIL + 1))
  fi
}

echo "=== Test: extract-entities.sh ==="

# Test 1: Runs on knowledge directory
echo "Test 1: Runs on knowledge directory"
OUTPUT=$("$EXTRACT" "$KNOWLEDGE_DIR")
assert_line_count_gte "produces output" "$OUTPUT" 5

# Test 2: Extracts companies
echo "Test 2: Extracts companies"
assert_contains "OpenAI" "$OUTPUT" "OpenAI"
assert_contains "CrewAI" "$OUTPUT" "CrewAI"
assert_contains "LangChain" "$OUTPUT" "LangChain"

# Test 3: Extracts people
echo "Test 3: Extracts people"
assert_contains "Sam Altman" "$OUTPUT" "Sam Altman"
assert_contains "Harrison Chase" "$OUTPUT" "Harrison Chase"

# Test 4: Extracts technologies
echo "Test 4: Extracts technologies"
assert_contains "MCP" "$OUTPUT" "MCP"

# Test 5: Shows article count per entity
echo "Test 5: Shows frequency"
assert_contains "frequency marker" "$OUTPUT" "x"

# Test 6: Runs on single file
echo "Test 6: Single file mode"
SINGLE=$("$EXTRACT" "$KNOWLEDGE_DIR/2026-03-11-langchain-mcp.md")
assert_contains "single file LangChain" "$SINGLE" "LangChain"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
