#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VALIDATE="$PROJECT_DIR/skills/prompt-optimizer/scripts/validate-report.sh"
PASS=0
FAIL=0

assert_exit() {
  local label="$1" expected="$2"
  shift 2
  set +e
  "$@" > /dev/null 2>&1
  local actual=$?
  set -e
  if [ "$actual" -eq "$expected" ]; then
    echo "  ✅ $label"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $label — expected exit $expected, got $actual"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test: validate-report.sh ==="

# Valid report
VALID=$(mktemp)
cat > "$VALID" << 'REPORT'
# ClawForage Weekly Optimization — Week 11

**Period:** 2026-03-03 to 2026-03-09
**Messages analyzed:** 42
**Total cost:** $0.35

## 🔄 Repeated Patterns

- 3x "What's the weather" → Add weather location to SOUL.md defaults

## 📝 SOUL.md Suggestions

Add default location preference for weather queries.

## 🧩 Recommended Skills

- weather-auto: Auto-fetches weather for configured location

## ⚠️ Failure Analysis

- Python scraping task failed due to missing dependency → Suggest adding pre-check step

## 📊 Usage Stats

- Most used tools: web_search, system.run
- Average cost per interaction: $0.008
- Topics covered: weather, AI frameworks, web scraping
REPORT

echo "Test 1: Valid report passes"
assert_exit "valid report" 0 "$VALIDATE" "$VALID"

# Missing required section
INVALID=$(mktemp)
echo "# Some random content" > "$INVALID"
echo "Test 2: Invalid report fails"
assert_exit "missing sections" 1 "$VALIDATE" "$INVALID"

# Empty file
EMPTY=$(mktemp)
touch "$EMPTY"
echo "Test 3: Empty file fails"
assert_exit "empty file" 1 "$VALIDATE" "$EMPTY"

rm -f "$VALID" "$INVALID" "$EMPTY"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
