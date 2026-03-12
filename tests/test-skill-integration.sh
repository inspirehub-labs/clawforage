#!/bin/bash
# test-skill-integration.sh — End-to-end test for prompt-optimizer skill
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EXTRACT="$PROJECT_DIR/skills/prompt-optimizer/scripts/extract-transcripts.sh"
VALIDATE="$PROJECT_DIR/skills/prompt-optimizer/scripts/validate-report.sh"
FIXTURE="$SCRIPT_DIR/fixtures/sample-transcript.jsonl"
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

echo "=== Integration Test: prompt-optimizer ==="

# Step 1: Extract transcripts
echo "Step 1: Transcript extraction"
EXTRACT_OUTPUT=$("$EXTRACT" "$FIXTURE" 7)
assert_ok "extraction succeeds" test -n "$EXTRACT_OUTPUT"

# Step 2: Verify extraction has all sections
echo "Step 2: Extraction output sections"
for section in "USER QUESTIONS" "REPEATED PATTERNS" "TOOL USAGE" "FAILURES" "COST SUMMARY"; do
  if echo "$EXTRACT_OUTPUT" | grep -q "$section"; then
    echo "  ✅ Has section: $section"; PASS=$((PASS + 1))
  else
    echo "  ❌ Missing section: $section"; FAIL=$((FAIL + 1))
  fi
done

# Step 3: Create a mock report and validate it
echo "Step 3: Report validation"
MOCK_REPORT=$(mktemp)
WEEK_NUM=$(date +%V)
cat > "$MOCK_REPORT" << EOF
# ClawForage Weekly Optimization — Week ${WEEK_NUM}

**Period:** 2026-03-03 to 2026-03-09
**Messages analyzed:** 8
**Total cost:** \$0.076

## 🔄 Repeated Patterns

- 3x "What's the weather in Hangzhou today?" → Add default location to SOUL.md
- 2x "Search for AI agent framework comparisons" → Create a cron job for weekly AI news digest

## 📝 SOUL.md Suggestions

Add to SOUL.md:
\`\`\`
Default weather location: Hangzhou, China
Preferred research topics: AI agent frameworks, startup regulations
\`\`\`

## 🧩 Recommended Skills

- weather-daily: Auto-fetches weather for configured location on morning greeting
- arxiv-digest: Weekly summary of new papers in configured domains

## ⚠️ Failure Analysis

- Python scraping task needed 2 attempts due to missing beautifulsoup4 → Add dependency pre-check to SOUL.md

## 📊 Usage Stats

- Most used tools: web_search (2x), system.run (2x)
- Average cost per interaction: \$0.0095
- Topics: weather, AI frameworks, web scraping, translation
EOF

assert_ok "mock report validates" "$VALIDATE" "$MOCK_REPORT"
rm -f "$MOCK_REPORT"

# Step 4: Verify SKILL.md exists and has required frontmatter
echo "Step 4: SKILL.md structure"
SKILL_MD="$PROJECT_DIR/skills/prompt-optimizer/SKILL.md"
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
if grep -q "description:" "$SKILL_MD"; then
  echo "  ✅ Has description field"; PASS=$((PASS + 1))
else
  echo "  ❌ Missing description field"; FAIL=$((FAIL + 1))
fi

# Step 5: Verify all required files exist
echo "Step 5: File structure"
for f in \
  "skills/prompt-optimizer/SKILL.md" \
  "skills/prompt-optimizer/scripts/extract-transcripts.sh" \
  "skills/prompt-optimizer/scripts/validate-report.sh" \
  "skills/prompt-optimizer/templates/weekly-report.md"; do
  if [ -f "$PROJECT_DIR/$f" ]; then
    echo "  ✅ Exists: $f"; PASS=$((PASS + 1))
  else
    echo "  ❌ Missing: $f"; FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
