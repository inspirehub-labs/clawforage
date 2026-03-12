# Knowledge Harvester Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an OpenClaw skill that runs daily via cron, fetches trending content from licensed APIs in user-configured domains, summarizes articles into Markdown files, and drops them into the agent's memory for automatic RAG indexing.

**Architecture:** Three bash scripts handle the pipeline: `fetch-articles.sh` calls Google News RSS (free, no API key) and outputs raw article metadata as JSON; `dedup-articles.sh` filters out articles already in `memory/knowledge/`; the SKILL.md agent instructions orchestrate the pipeline — fetching, deduplication, LLM summarization, and writing Markdown files. A `domains.md` config file lets users specify topics.

**Tech Stack:** Bash, curl (RSS fetching), jq (XML/JSON processing), OpenClaw skill system (SKILL.md + cron), Markdown output to `memory/knowledge/`

---

## File Structure

```
skills/knowledge-harvester/
├── SKILL.md                     # Agent instructions (rewrite existing stub)
├── scripts/
│   ├── fetch-articles.sh        # Fetches articles from Google News RSS → JSON stdout
│   ├── dedup-articles.sh        # Filters out already-harvested articles
│   └── validate-knowledge.sh    # Validates output Markdown files
├── templates/
│   ├── knowledge-article.md     # Template for individual article summaries
│   └── domains-example.md       # Example domains config
└── README.md                    # ClawHub listing docs
```

```
tests/
├── fixtures/
│   ├── sample-rss-response.xml  # Mock RSS feed response
│   ├── sample-domains.md        # Test domain config
│   └── sample-knowledge-article.md  # Example valid output
├── test-fetch-articles.sh       # Tests for fetch script
├── test-dedup-articles.sh       # Tests for dedup script
└── test-knowledge-integration.sh # End-to-end test
```

---

## Chunk 1: RSS Fetch Script

### Task 1: Create test fixtures

**Files:**
- Create: `tests/fixtures/sample-rss-response.xml`
- Create: `tests/fixtures/sample-domains.md`
- Create: `tests/fixtures/sample-knowledge-article.md`

- [ ] **Step 1: Write mock RSS response**

This is a realistic Google News RSS response with 3 articles:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>AI agent frameworks - Google News</title>
    <link>https://news.google.com</link>
    <description>Google News</description>
    <item>
      <title>LangChain v0.3 Released With Native MCP Support</title>
      <link>https://example.com/langchain-v03-mcp</link>
      <pubDate>Wed, 11 Mar 2026 10:00:00 GMT</pubDate>
      <description>LangChain has released version 0.3 with native Model Context Protocol support, enabling seamless integration with OpenClaw and other agent frameworks.</description>
      <source url="https://techcrunch.com">TechCrunch</source>
    </item>
    <item>
      <title>CrewAI Raises $50M Series B for Multi-Agent Orchestration</title>
      <link>https://example.com/crewai-series-b</link>
      <pubDate>Tue, 10 Mar 2026 14:30:00 GMT</pubDate>
      <description>CrewAI has closed a $50M Series B round led by Sequoia to expand its role-based multi-agent orchestration platform.</description>
      <source url="https://venturebeat.com">VentureBeat</source>
    </item>
    <item>
      <title>OpenAI Agents SDK Now Supports Tool Streaming</title>
      <link>https://example.com/openai-agents-streaming</link>
      <pubDate>Mon, 09 Mar 2026 09:15:00 GMT</pubDate>
      <description>OpenAI updated its Agents SDK with tool streaming capabilities, reducing latency for complex multi-step agent workflows.</description>
      <source url="https://openai.com/blog">OpenAI Blog</source>
    </item>
  </channel>
</rss>
```

- [ ] **Step 2: Write sample domains config**

```markdown
# My Domains
- AI agent frameworks
- startup regulations China
- sailing weather New Zealand
```

- [ ] **Step 3: Write sample valid knowledge article**

```markdown
---
date: 2026-03-11
source: TechCrunch
url: https://example.com/langchain-v03-mcp
domain: AI agent frameworks
harvested: 2026-03-12
---

# LangChain v0.3 Released With Native MCP Support

LangChain version 0.3 introduces native Model Context Protocol (MCP) support, enabling direct integration with agent frameworks like OpenClaw. The release includes improved tool calling, streaming support, and a redesigned memory system. This is significant for the agent ecosystem as MCP becomes a de facto standard for agent-tool communication.

**Key facts:** MCP native support, improved tool calling, streaming, redesigned memory. **Impact:** Strengthens MCP as the standard agent protocol, benefits OpenClaw users directly.
```

- [ ] **Step 4: Commit fixtures**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add tests/fixtures/sample-rss-response.xml tests/fixtures/sample-domains.md tests/fixtures/sample-knowledge-article.md
git commit -m "test: add knowledge-harvester fixtures (RSS, domains, article)"
```

---

### Task 2: Write fetch-articles.sh + tests

**Files:**
- Create: `skills/knowledge-harvester/scripts/fetch-articles.sh`
- Create: `tests/test-fetch-articles.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test-fetch-articles.sh`:

```bash
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

# Test 1: Parse RSS from file (offline mode for testing)
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x tests/test-fetch-articles.sh
bash tests/test-fetch-articles.sh
```

Expected: FAIL — script not found

- [ ] **Step 3: Write the fetch script**

Create `skills/knowledge-harvester/scripts/fetch-articles.sh`:

```bash
#!/bin/bash
# fetch-articles.sh — Fetch articles from Google News RSS or local file
# Usage:
#   fetch-articles.sh <domain_query>                    # live fetch from Google News RSS
#   fetch-articles.sh --from-file <rss.xml> <domain>    # parse local RSS file (for testing)
#   fetch-articles.sh --list-domains <domains.md>       # list domains from config file
# Output: One JSON object per line (JSONL) to stdout
set -euo pipefail

# --- Parse domains from config file ---
list_domains() {
  local config="$1"
  grep -E '^\s*-\s+' "$config" | sed 's/^\s*-\s*//' | sed 's/\s*$//'
}

# --- Parse RSS XML into JSONL ---
parse_rss_to_jsonl() {
  local rss_content="$1"
  local domain="$2"
  local today
  today=$(date +%Y-%m-%d)

  # Use xmllint if available, fall back to awk-based parsing
  if command -v xmllint &>/dev/null; then
    echo "$rss_content" | xmllint --xpath '//item' - 2>/dev/null | \
      awk -v domain="$domain" -v today="$today" '
        BEGIN { RS="</item>"; FS="\n" }
        {
          title=""; link=""; pubDate=""; desc=""; src=""
          for (i=1; i<=NF; i++) {
            if ($i ~ /<title>/) { gsub(/.*<title>|<\/title>.*/, "", $i); title=$i }
            if ($i ~ /<link>/) { gsub(/.*<link>|<\/link>.*/, "", $i); link=$i }
            if ($i ~ /<pubDate>/) { gsub(/.*<pubDate>|<\/pubDate>.*/, "", $i); pubDate=$i }
            if ($i ~ /<description>/) { gsub(/.*<description>|<\/description>.*/, "", $i); desc=$i }
            if ($i ~ /<source/) { gsub(/.*<source[^>]*>|<\/source>.*/, "", $i); src=$i }
          }
          if (title != "") {
            gsub(/"/, "\\\"", title)
            gsub(/"/, "\\\"", desc)
            gsub(/"/, "\\\"", src)
            printf "{\"title\":\"%s\",\"url\":\"%s\",\"date\":\"%s\",\"description\":\"%s\",\"source\":\"%s\",\"domain\":\"%s\",\"harvested\":\"%s\"}\n", title, link, pubDate, desc, src, domain, today
          }
        }
      '
  else
    # Fallback: pure awk parsing (no xmllint needed)
    echo "$rss_content" | awk -v domain="$domain" -v today="$today" '
      BEGIN { RS="</item>"; FS="\n" }
      {
        title=""; link=""; pubDate=""; desc=""; src=""
        for (i=1; i<=NF; i++) {
          if ($i ~ /<title>/) { gsub(/.*<title>|<\/title>.*/, "", $i); title=$i }
          if ($i ~ /<link>/) { gsub(/.*<link>|<\/link>.*/, "", $i); link=$i }
          if ($i ~ /<pubDate>/) { gsub(/.*<pubDate>|<\/pubDate>.*/, "", $i); pubDate=$i }
          if ($i ~ /<description>/) { gsub(/.*<description>|<\/description>.*/, "", $i); desc=$i }
          if ($i ~ /<source/) { gsub(/.*<source[^>]*>|<\/source>.*/, "", $i); src=$i }
        }
        if (title != "") {
          gsub(/"/, "\\\"", title)
          gsub(/"/, "\\\"", desc)
          gsub(/"/, "\\\"", src)
          printf "{\"title\":\"%s\",\"url\":\"%s\",\"date\":\"%s\",\"description\":\"%s\",\"source\":\"%s\",\"domain\":\"%s\",\"harvested\":\"%s\"}\n", title, link, pubDate, desc, src, domain, today
        }
      }
    '
  fi
}

# --- Main ---
case "${1:-}" in
  --list-domains)
    CONFIG="${2:?Usage: fetch-articles.sh --list-domains <domains.md>}"
    list_domains "$CONFIG"
    ;;
  --from-file)
    RSS_FILE="${2:?Usage: fetch-articles.sh --from-file <rss.xml> <domain>}"
    DOMAIN="${3:?Usage: fetch-articles.sh --from-file <rss.xml> <domain>}"
    RSS_CONTENT=$(cat "$RSS_FILE")
    parse_rss_to_jsonl "$RSS_CONTENT" "$DOMAIN"
    ;;
  *)
    QUERY="${1:?Usage: fetch-articles.sh <domain_query>}"
    ENCODED_QUERY=$(printf '%s' "$QUERY" | jq -sRr @uri 2>/dev/null || printf '%s' "$QUERY" | sed 's/ /+/g')
    RSS_URL="https://news.google.com/rss/search?q=${ENCODED_QUERY}&hl=en&gl=US&ceid=US:en"
    RSS_CONTENT=$(curl -sL --max-time 15 "$RSS_URL" 2>/dev/null || echo "")
    if [ -z "$RSS_CONTENT" ]; then
      echo "ERROR: Failed to fetch RSS from Google News" >&2
      exit 1
    fi
    parse_rss_to_jsonl "$RSS_CONTENT" "$QUERY"
    ;;
esac
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x skills/knowledge-harvester/scripts/fetch-articles.sh
bash tests/test-fetch-articles.sh
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/knowledge-harvester/scripts/fetch-articles.sh tests/test-fetch-articles.sh
git commit -m "feat: add RSS article fetcher with offline test support"
```

---

## Chunk 2: Deduplication Script

### Task 3: Write dedup-articles.sh + tests

**Files:**
- Create: `skills/knowledge-harvester/scripts/dedup-articles.sh`
- Create: `tests/test-dedup-articles.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test-dedup-articles.sh`:

```bash
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
  count=$(echo "$output" | jq -s 'length' 2>/dev/null || echo "0")
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
INPUT=$(cat << 'JSONL'
{"title":"LangChain v0.3 Released","url":"https://example.com/langchain-v03-mcp","source":"TechCrunch","domain":"AI"}
{"title":"CrewAI Raises $50M","url":"https://example.com/crewai-series-b","source":"VentureBeat","domain":"AI"}
{"title":"OpenAI Agents SDK Update","url":"https://example.com/openai-agents-streaming","source":"OpenAI","domain":"AI"}
JSONL
)

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
OUTPUT3=$(echo "$INPUT" | "$DEDUP" "$TMPDIR/knowledge")
assert_json_count "0 articles" "$OUTPUT3" 0

rm -rf "$TMPDIR" "$EMPTY_DIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x tests/test-dedup-articles.sh
bash tests/test-dedup-articles.sh
```

Expected: FAIL — script not found

- [ ] **Step 3: Write the dedup script**

Create `skills/knowledge-harvester/scripts/dedup-articles.sh`:

```bash
#!/bin/bash
# dedup-articles.sh — Filter out articles already in knowledge directory
# Usage: echo '<jsonl>' | dedup-articles.sh <knowledge_dir>
# Input:  JSONL on stdin (each line has a "url" field)
# Output: JSONL on stdout (only articles whose URL is NOT in any existing .md file)
set -euo pipefail

KNOWLEDGE_DIR="${1:?Usage: echo '<jsonl>' | dedup-articles.sh <knowledge_dir>}"

# Build set of known URLs from existing Markdown files
KNOWN_URLS=""
if [ -d "$KNOWLEDGE_DIR" ]; then
  KNOWN_URLS=$(grep -rh '^url:' "$KNOWLEDGE_DIR"/*.md 2>/dev/null | sed 's/^url:\s*//' | sed 's/\s*$//' || true)
fi

# Filter stdin JSONL: pass through lines whose url is NOT in KNOWN_URLS
while IFS= read -r line; do
  [ -z "$line" ] && continue
  url=$(echo "$line" | jq -r '.url' 2>/dev/null || echo "")
  [ -z "$url" ] && continue
  if ! echo "$KNOWN_URLS" | grep -qF "$url"; then
    echo "$line"
  fi
done
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x skills/knowledge-harvester/scripts/dedup-articles.sh
bash tests/test-dedup-articles.sh
```

Expected: All 3 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/knowledge-harvester/scripts/dedup-articles.sh tests/test-dedup-articles.sh
git commit -m "feat: add article deduplication script with tests"
```

---

## Chunk 3: Validation, Templates, and SKILL.md

### Task 4: Write validate-knowledge.sh + tests

**Files:**
- Create: `skills/knowledge-harvester/scripts/validate-knowledge.sh`

- [ ] **Step 1: Write the validation script**

```bash
#!/bin/bash
# validate-knowledge.sh — Validate a knowledge article Markdown file
# Usage: validate-knowledge.sh <article.md>
# Exit 0 if valid, 1 if invalid
set -euo pipefail

ARTICLE="${1:?Usage: validate-knowledge.sh <article.md>}"

if [ ! -s "$ARTICLE" ]; then
  echo "ERROR: Article file is empty or missing: $ARTICLE"
  exit 1
fi

ERRORS=0

check_field() {
  local field="$1"
  if ! grep -q "^${field}:" "$ARTICLE"; then
    echo "ERROR: Missing frontmatter field: $field"
    ERRORS=$((ERRORS + 1))
  fi
}

# Check YAML frontmatter exists
if ! head -1 "$ARTICLE" | grep -q "^---"; then
  echo "ERROR: Missing YAML frontmatter"
  ERRORS=$((ERRORS + 1))
else
  check_field "date"
  check_field "source"
  check_field "url"
  check_field "domain"
fi

# Check has a heading
if ! grep -q "^# " "$ARTICLE"; then
  echo "ERROR: Missing article title (# heading)"
  ERRORS=$((ERRORS + 1))
fi

# Check word count (should be 50-300 words in body)
BODY=$(sed -n '/^---$/,/^---$/!p' "$ARTICLE" | tail -n +2)
WORD_COUNT=$(echo "$BODY" | wc -w | tr -d ' ')
if [ "$WORD_COUNT" -lt 30 ]; then
  echo "WARNING: Article body is very short ($WORD_COUNT words)"
fi

if [ "$ERRORS" -gt 0 ]; then
  echo "Validation failed: $ERRORS error(s)"
  exit 1
fi

echo "Article validation passed ($WORD_COUNT words)"
exit 0
```

- [ ] **Step 2: Quick inline test**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x skills/knowledge-harvester/scripts/validate-knowledge.sh
# Should pass on fixture
bash skills/knowledge-harvester/scripts/validate-knowledge.sh tests/fixtures/sample-knowledge-article.md
# Should fail on empty file
touch /tmp/empty.md && bash skills/knowledge-harvester/scripts/validate-knowledge.sh /tmp/empty.md || echo "Correctly failed"
```

- [ ] **Step 3: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/knowledge-harvester/scripts/validate-knowledge.sh
git commit -m "feat: add knowledge article validator"
```

---

### Task 5: Create templates and domain config example

**Files:**
- Create: `skills/knowledge-harvester/templates/knowledge-article.md`
- Create: `skills/knowledge-harvester/templates/domains-example.md`

- [ ] **Step 1: Write article template**

```markdown
---
date: {DATE}
source: {SOURCE}
url: {URL}
domain: {DOMAIN}
harvested: {HARVESTED_DATE}
---

# {TITLE}

{SUMMARY — 100-200 words capturing key facts, entities, and implications}

**Key facts:** {bullet points} **Impact:** {why this matters to the user}
```

- [ ] **Step 2: Write domains example**

```markdown
# My Domains

Configure your interests below. The Knowledge Harvester will fetch daily articles for each domain.

- AI agent frameworks
- startup regulations China
- sailing weather New Zealand

## Notes
- One domain per line, prefixed with `-`
- Be specific: "AI agent frameworks" is better than "AI"
- Add/remove domains anytime — changes take effect on next run
```

- [ ] **Step 3: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/knowledge-harvester/templates/
git commit -m "feat: add knowledge article template and domain config example"
```

---

### Task 6: Rewrite production SKILL.md

**Files:**
- Modify: `skills/knowledge-harvester/SKILL.md`

- [ ] **Step 1: Write the full SKILL.md**

```markdown
---
name: clawforage-knowledge-harvester
description: Daily automated briefings — fetches trending content via Google News RSS, summarizes into memory for RAG retrieval
version: 0.1.0
emoji: "📰"
user-invocable: true
metadata: {"openclaw":{"requires":{"bins":["jq","curl","bash"]}}}
---

# Knowledge Harvester

You are a knowledge curation agent run by ClawForage. Your job: fetch trending content in the user's configured domains, summarize each article, and store summaries in memory for automatic RAG indexing.

## Step 1: Read Domain Configuration

```bash
cat memory/clawforage/domains.md 2>/dev/null || echo "No domains configured"
```

If no domains file exists, create a default one:

```bash
mkdir -p memory/clawforage
cp {baseDir}/templates/domains-example.md memory/clawforage/domains.md
```

Then inform the user they should edit `memory/clawforage/domains.md` with their interests and stop.

## Step 2: Fetch Articles for Each Domain

For each domain in the config, run the fetch script:

```bash
bash {baseDir}/scripts/fetch-articles.sh "<domain_query>"
```

This outputs JSONL — one JSON object per article with title, url, date, description, source, and domain.

Limit to top 10 articles per domain (first 10 lines of output).

## Step 3: Deduplicate

Pipe the articles through the dedup script to filter out already-harvested content:

```bash
bash {baseDir}/scripts/fetch-articles.sh "<domain>" | head -10 | bash {baseDir}/scripts/dedup-articles.sh memory/knowledge
```

## Step 4: Summarize and Write

For each new article from the dedup output:

1. Read the article's `description` field (from the RSS feed)
2. Write a 100-200 word summary capturing:
   - Key facts and data points
   - Named entities (people, companies, products)
   - Why this matters (implications)
3. Save to `memory/knowledge/{DATE}-{slug}.md` using the template format:

```markdown
---
date: {article date, YYYY-MM-DD format}
source: {source publication}
url: {original URL}
domain: {domain from config}
harvested: {today's date}
---

# {Article Title}

{Your 100-200 word summary}

**Key facts:** {comma-separated key points} **Impact:** {one sentence on why this matters}
```

The slug should be the title in lowercase, spaces replaced with hyphens, max 50 chars.

Create the directory if needed:

```bash
mkdir -p memory/knowledge
```

## Step 5: Validate Output

For each file written, validate it:

```bash
bash {baseDir}/scripts/validate-knowledge.sh memory/knowledge/{filename}.md
```

Fix any validation errors before finishing.

## Step 6: Summary

After processing all domains, output a brief summary:
- How many domains processed
- How many new articles harvested
- How many skipped (duplicates)
- Total estimated cost

## Constraints

- **Licensed sources only**: Use Google News RSS — never scrape websites directly
- **Summaries only**: Never reproduce more than 10 consecutive words from any source
- **Always attribute**: Every article must have source and URL in frontmatter
- **Rate limits**: Max 100 API calls per run, max 10 articles per domain
- **Cheapest model**: Run on the cheapest available model for summarization
- **Privacy**: Domain interests are personal — never share externally
```

- [ ] **Step 2: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/knowledge-harvester/SKILL.md
git commit -m "feat: rewrite knowledge-harvester SKILL.md with full agent instructions"
```

---

## Chunk 4: Integration Test, README, Final Verification

### Task 7: Write integration test

**Files:**
- Create: `tests/test-knowledge-integration.sh`

- [ ] **Step 1: Write integration test**

```bash
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
```

- [ ] **Step 2: Run integration test**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x tests/test-knowledge-integration.sh
bash tests/test-knowledge-integration.sh
```

Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add tests/test-knowledge-integration.sh
git commit -m "test: add knowledge-harvester integration test"
```

---

### Task 8: Write README

**Files:**
- Create: `skills/knowledge-harvester/README.md`

- [ ] **Step 1: Write README for ClawHub**

```markdown
# 📰 ClawForage Knowledge Harvester

Wake up to an AI that already read today's news in your domains.

## What It Does

Runs daily (default 2am) to:
- Fetch trending articles from Google News RSS in your configured domains
- Summarize each article into 100-200 words
- Store summaries as Markdown in `memory/knowledge/` for automatic RAG indexing
- Deduplicate to avoid re-processing known content

Next time you ask a question, your agent has fresh context to draw from.

## Install

```bash
openclaw skill install clawforage/knowledge-harvester
```

## Setup

1. Create your domain config:
```bash
mkdir -p memory/clawforage
cat > memory/clawforage/domains.md << 'EOF'
# My Domains
- AI agent frameworks
- startup news Asia
- renewable energy
EOF
```

2. The harvester runs automatically at 2am daily, or invoke manually:
```
/clawforage-knowledge-harvester
```

## Requirements

- `jq` — `brew install jq` or `apt install jq`
- `curl` — usually pre-installed
- `bash` (v4+)
- No API keys required (uses Google News RSS)

## Cost

~$0.02–0.05 per run (10 articles). Uses cheapest available model for summarization.

## Legal Safety

- Uses Google News RSS (public, free, no scraping)
- Stores summaries only — never reproduces source content
- Always attributes source with URL
- User controls which domains to track

## Part of ClawForage

Built by [InspireHub Labs](https://inspireehub.ai). See also:
- [Prompt Optimizer](../prompt-optimizer/) — weekly agent self-improvement
- [Research Agent](../research-agent/) — deep domain research
```

- [ ] **Step 2: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/knowledge-harvester/README.md
git commit -m "docs: add knowledge-harvester README"
```

---

### Task 9: Run all tests and final commit

- [ ] **Step 1: Run ALL test suites (both skills)**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
echo "=== Running ALL tests ===" && \
bash tests/test-extract-transcripts.sh && echo "" && \
bash tests/test-validate-report.sh && echo "" && \
bash tests/test-skill-integration.sh && echo "" && \
bash tests/test-fetch-articles.sh && echo "" && \
bash tests/test-dedup-articles.sh && echo "" && \
bash tests/test-knowledge-integration.sh && echo "" && \
echo "=== ALL TESTS PASSED ==="
```

Expected: All tests pass across both skills

- [ ] **Step 2: Verify complete file structure**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
find skills/knowledge-harvester -type f | sort
```

Expected:
```
skills/knowledge-harvester/README.md
skills/knowledge-harvester/SKILL.md
skills/knowledge-harvester/scripts/dedup-articles.sh
skills/knowledge-harvester/scripts/fetch-articles.sh
skills/knowledge-harvester/scripts/validate-knowledge.sh
skills/knowledge-harvester/templates/domains-example.md
skills/knowledge-harvester/templates/knowledge-article.md
```

- [ ] **Step 3: Final commit if needed**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git status
# If anything remains:
git add -A && git commit -m "chore: knowledge-harvester v0.1.0 complete"
```
