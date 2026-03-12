#!/bin/bash
# test-knowledge-integration.sh — End-to-end test for knowledge-harvester
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FETCH="$PROJECT_DIR/skills/knowledge-harvester/scripts/fetch-articles.sh"
DEDUP="$PROJECT_DIR/skills/knowledge-harvester/scripts/dedup-articles.sh"
VALIDATE="$PROJECT_DIR/skills/knowledge-harvester/scripts/validate-knowledge.sh"
FIXTURE_RSS="$SCRIPT_DIR/fixtures/sample-rss-response.xml"
FIXTURE_DOMAINS="$SCRIPT_DIR/fixtures/sample-domains.md"
FIXTURE_ARTICLE="$SCRIPT_DIR/fixtures/sample-knowledge-article.md"
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

echo "=== Integration Test: knowledge-harvester ==="

# Step 1: Fetch → Dedup pipeline
echo "Step 1: Fetch and dedup pipeline"
TMPDIR=$(mktemp -d)
FETCHED=$("$FETCH" --from-file "$FIXTURE_RSS" "AI agent frameworks")
DEDUPED=$(echo "$FETCHED" | "$DEDUP" "$TMPDIR")
COUNT=$(echo "$DEDUPED" | jq -s 'length')
if [ "$COUNT" -ge 1 ]; then
  echo "  ✅ Pipeline produces $COUNT articles"; PASS=$((PASS + 1))
else
  echo "  ❌ Pipeline produced 0 articles"; FAIL=$((FAIL + 1))
fi

# Step 2: Domain parsing
echo "Step 2: Domain config parsing"
DOMAINS=$("$FETCH" --list-domains "$FIXTURE_DOMAINS")
DOMAIN_COUNT=$(echo "$DOMAINS" | wc -l | tr -d ' ')
if [ "$DOMAIN_COUNT" -ge 3 ]; then
  echo "  ✅ Parsed $DOMAIN_COUNT domains"; PASS=$((PASS + 1))
else
  echo "  ❌ Expected >= 3 domains, got $DOMAIN_COUNT"; FAIL=$((FAIL + 1))
fi

# Step 3: Validate fixture article
echo "Step 3: Article validation"
assert_ok "fixture article validates" "$VALIDATE" "$FIXTURE_ARTICLE"

# Step 4: Dedup correctly filters
echo "Step 4: Dedup filters known URLs"
mkdir -p "$TMPDIR/knowledge"
FIRST_URL=$(echo "$FETCHED" | head -1 | jq -r '.url')
cat > "$TMPDIR/knowledge/existing.md" << EOF
---
url: $FIRST_URL
---
# Existing
EOF
DEDUPED2=$(echo "$FETCHED" | "$DEDUP" "$TMPDIR/knowledge")
COUNT2=$(echo "$DEDUPED2" | jq -s 'length')
if [ "$COUNT2" -lt "$COUNT" ]; then
  echo "  ✅ Dedup removed 1 article ($COUNT → $COUNT2)"; PASS=$((PASS + 1))
else
  echo "  ❌ Dedup did not filter (still $COUNT2)"; FAIL=$((FAIL + 1))
fi

# Step 5: File structure check
echo "Step 5: File structure"
for f in \
  "skills/knowledge-harvester/SKILL.md" \
  "skills/knowledge-harvester/scripts/fetch-articles.sh" \
  "skills/knowledge-harvester/scripts/dedup-articles.sh" \
  "skills/knowledge-harvester/scripts/validate-knowledge.sh" \
  "skills/knowledge-harvester/templates/knowledge-article.md" \
  "skills/knowledge-harvester/templates/domains-example.md"; do
  if [ -f "$PROJECT_DIR/$f" ]; then
    echo "  ✅ Exists: $f"; PASS=$((PASS + 1))
  else
    echo "  ❌ Missing: $f"; FAIL=$((FAIL + 1))
  fi
done

rm -rf "$TMPDIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
