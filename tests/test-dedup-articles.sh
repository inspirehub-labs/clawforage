#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEDUP="$PROJECT_DIR/skills/knowledge-harvester/scripts/dedup-articles.sh"
PASS=0
FAIL=0

assert_json_count() {
  local label="$1" output="$2" expected="$3"
  local count
  if [ -z "$output" ]; then
    count=0
  else
    count=$(echo "$output" | jq -s 'length' 2>/dev/null || echo "0")
  fi
  if [ "$count" -eq "$expected" ]; then
    echo "  ✅ $label (got $count)"; PASS=$((PASS + 1))
  else
    echo "  ❌ $label — expected $expected, got $count"; FAIL=$((FAIL + 1))
  fi
}

echo "=== Test: dedup-articles.sh ==="

# Setup: create temp knowledge dir with one existing article
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/knowledge"
cat > "$TMPDIR/knowledge/2026-03-11-langchain-v03-mcp.md" << 'EOF'
---
url: https://example.com/langchain-v03-mcp
---
# LangChain v0.3
EOF

# Input: 3 articles, one already harvested (matching URL)
INPUT='{"title":"LangChain v0.3 Released","url":"https://example.com/langchain-v03-mcp","source":"TechCrunch","domain":"AI"}
{"title":"CrewAI Raises $50M","url":"https://example.com/crewai-series-b","source":"VentureBeat","domain":"AI"}
{"title":"OpenAI Agents SDK Update","url":"https://example.com/openai-agents-streaming","source":"OpenAI","domain":"AI"}'

# Test 1: Filters out existing article
echo "Test 1: Filters duplicates by URL"
OUTPUT=$(echo "$INPUT" | "$DEDUP" "$TMPDIR/knowledge")
assert_json_count "2 new articles" "$OUTPUT" 2

# Test 2: Empty knowledge dir → all pass through
echo "Test 2: No existing articles → all pass"
EMPTY_DIR=$(mktemp -d)
OUTPUT2=$(echo "$INPUT" | "$DEDUP" "$EMPTY_DIR")
assert_json_count "3 articles pass" "$OUTPUT2" 3

# Test 3: All duplicates → empty output
echo "Test 3: All duplicates → zero output"
cat > "$TMPDIR/knowledge/2026-03-10-crewai.md" << 'EOF'
---
url: https://example.com/crewai-series-b
---
EOF
cat > "$TMPDIR/knowledge/2026-03-09-openai.md" << 'EOF'
---
url: https://example.com/openai-agents-streaming
---
EOF
OUTPUT3=$(echo "$INPUT" | "$DEDUP" "$TMPDIR/knowledge" || true)
assert_json_count "0 articles" "$OUTPUT3" 0

rm -rf "$TMPDIR" "$EMPTY_DIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
