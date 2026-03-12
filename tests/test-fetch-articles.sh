#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FETCH="$PROJECT_DIR/skills/knowledge-harvester/scripts/fetch-articles.sh"
FIXTURE_RSS="$SCRIPT_DIR/fixtures/sample-rss-response.xml"
FIXTURE_DOMAINS="$SCRIPT_DIR/fixtures/sample-domains.md"
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

assert_json_count() {
  local label="$1" output="$2" min="$3"
  local count
  count=$(echo "$output" | jq -s 'length' 2>/dev/null || echo "0")
  if [ "$count" -ge "$min" ]; then
    echo "  ✅ $label (got $count items)"; PASS=$((PASS + 1))
  else
    echo "  ❌ $label — expected >= $min items, got $count"; FAIL=$((FAIL + 1))
  fi
}

echo "=== Test: fetch-articles.sh ==="

# Test 1: Parse RSS from file (offline mode)
echo "Test 1: Parse RSS fixture into JSON"
OUTPUT=$("$FETCH" --from-file "$FIXTURE_RSS" "AI agent frameworks")
assert_json_count "produces JSON items" "$OUTPUT" 3

# Test 2: JSON has required fields
echo "Test 2: JSON has required fields"
FIRST=$(echo "$OUTPUT" | head -1)
assert_contains "has title" "$FIRST" "title"
assert_contains "has url" "$FIRST" "url"
assert_contains "has source" "$FIRST" "source"
assert_contains "has date" "$FIRST" "date"
assert_contains "has description" "$FIRST" "description"
assert_contains "has domain" "$FIRST" "domain"

# Test 3: Domain tag is set correctly
echo "Test 3: Domain tag propagation"
assert_contains "domain set" "$FIRST" "AI agent frameworks"

# Test 4: Parse domains file
echo "Test 4: Parse domains config"
DOMAINS=$("$FETCH" --list-domains "$FIXTURE_DOMAINS")
assert_contains "has AI domain" "$DOMAINS" "AI agent frameworks"
assert_contains "has startup domain" "$DOMAINS" "startup regulations"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
