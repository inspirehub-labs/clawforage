#!/bin/bash
# test-research-integration.sh — End-to-end test for research-agent
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EXTRACT="$PROJECT_DIR/skills/research-agent/scripts/extract-entities.sh"
CONNECT="$PROJECT_DIR/skills/research-agent/scripts/build-connections.sh"
VALIDATE="$PROJECT_DIR/skills/research-agent/scripts/validate-report.sh"
KNOWLEDGE_DIR="$SCRIPT_DIR/fixtures/sample-knowledge-dir"
PASS=0
FAIL=0

assert_ok() {
  local label="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo "  ✅ $label"; PASS=$((PASS + 1))
  else
    echo "  ❌ $label"; FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local label="$1" output="$2" expected="$3"
  if echo "$output" | grep -qF "$expected"; then
    echo "  ✅ $label"; PASS=$((PASS + 1))
  else
    echo "  ❌ $label — expected: $expected"; FAIL=$((FAIL + 1))
  fi
}

echo "=== Integration Test: research-agent ==="

# Step 1: Full pipeline — entities then connections
echo "Step 1: Entity → Connection pipeline"
ENTITIES=$("$EXTRACT" "$KNOWLEDGE_DIR")
CONNECTIONS=$("$CONNECT" "$KNOWLEDGE_DIR")
assert_contains "entities has MCP" "$ENTITIES" "MCP"
assert_contains "connections has shared entities" "$CONNECTIONS" "CONNECTIONS"
assert_contains "timeline built" "$CONNECTIONS" "TIMELINE"

# Step 2: Mock report validates
echo "Step 2: Report validation"
MOCK=$(mktemp)
cat > "$MOCK" << 'EOF'
# Domain Research Report: AI agent frameworks — Week 11

**Period:** 2026-03-09 to 2026-03-11
**Articles analyzed:** 3
**Domain:** AI agent frameworks

## 🔑 Key Developments

The AI agent framework space saw major activity this week. MCP adoption accelerated across all major players.

## 🏢 Entity Map

- **OpenAI**: Updated Agents SDK with streaming (Tier 1: OpenAI Blog)
- **CrewAI**: Raised $50M Series B (Tier 1: VentureBeat)
- **LangChain**: Released v0.3 with native MCP (Tier 1: TechCrunch)

## 🔗 Connections

MCP emerged as the unifying theme — all three frameworks are converging on it as the standard protocol.

## 📈 Outlook

MCP standardization is accelerating. Expect consolidation as smaller frameworks adopt it.

## 📚 Sources

- 2026-03-09: OpenAI Blog — OpenAI Agents SDK (https://example.com/openai-agents-streaming)
- 2026-03-10: VentureBeat — CrewAI Series B (https://example.com/crewai-series-b)
- 2026-03-11: TechCrunch — LangChain v0.3 (https://example.com/langchain-v03-mcp)
EOF
assert_ok "mock report validates" "$VALIDATE" "$MOCK"
rm -f "$MOCK"

# Step 3: File structure check
echo "Step 3: File structure"
for f in \
  "skills/research-agent/SKILL.md" \
  "skills/research-agent/scripts/extract-entities.sh" \
  "skills/research-agent/scripts/build-connections.sh" \
  "skills/research-agent/scripts/validate-report.sh" \
  "skills/research-agent/templates/domain-report.md" \
  "skills/research-agent/templates/sources-example.md"; do
  if [ -f "$PROJECT_DIR/$f" ]; then
    echo "  ✅ Exists: $f"; PASS=$((PASS + 1))
  else
    echo "  ❌ Missing: $f"; FAIL=$((FAIL + 1))
  fi
done

# Step 4: SKILL.md structure
echo "Step 4: SKILL.md structure"
SKILL_MD="$PROJECT_DIR/skills/research-agent/SKILL.md"
if head -1 "$SKILL_MD" | grep -q "^---"; then
  echo "  ✅ Has YAML frontmatter"; PASS=$((PASS + 1))
else
  echo "  ❌ Missing YAML frontmatter"; FAIL=$((FAIL + 1))
fi
if grep -q "name:" "$SKILL_MD"; then
  echo "  ✅ Has name field"; PASS=$((PASS + 1))
else
  echo "  ❌ Missing name field"; FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
