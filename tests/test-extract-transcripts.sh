#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EXTRACT="$PROJECT_DIR/skills/prompt-optimizer/scripts/extract-transcripts.sh"
FIXTURE="$SCRIPT_DIR/fixtures/sample-transcript.jsonl"
PASS=0
FAIL=0

assert_contains() {
  local label="$1" output="$2" expected="$3"
  if echo "$output" | grep -qF "$expected"; then
    echo "  ✅ $label"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $label — expected to find: $expected"
    FAIL=$((FAIL + 1))
  fi
}

assert_line_count_gte() {
  local label="$1" output="$2" min="$3"
  local count
  count=$(echo "$output" | wc -l | tr -d ' ')
  if [ "$count" -ge "$min" ]; then
    echo "  ✅ $label (got $count lines)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $label — expected >= $min lines, got $count"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test: extract-transcripts.sh ==="

# Test 1: Script runs without error on fixture
echo "Test 1: Script runs on fixture"
OUTPUT=$("$EXTRACT" "$FIXTURE" 7)
assert_line_count_gte "produces output" "$OUTPUT" 5

# Test 2: Extracts user messages
echo "Test 2: Contains user messages"
assert_contains "weather query" "$OUTPUT" "weather"
assert_contains "AI agent query" "$OUTPUT" "AI agent"

# Test 3: Extracts cost data
echo "Test 3: Contains cost summary"
assert_contains "total cost" "$OUTPUT" "Total cost"

# Test 4: Identifies repeated questions
echo "Test 4: Identifies repeated questions"
assert_contains "repeated pattern" "$OUTPUT" "repeated"

# Test 5: Identifies tool usage
echo "Test 5: Identifies tool usage"
assert_contains "tool usage" "$OUTPUT" "system.run"

# Test 6: Identifies failures (error messages in assistant responses)
echo "Test 6: Identifies failures"
assert_contains "failure detected" "$OUTPUT" "error"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
