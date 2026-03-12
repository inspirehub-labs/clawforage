# Prompt Optimizer — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fully functional OpenClaw skill that analyzes JSONL conversation transcripts weekly and produces actionable optimization reports written to memory.

**Architecture:** A single OpenClaw skill (`SKILL.md`) with two supporting bash scripts: one to extract and preprocess transcripts from JSONL into a clean text summary, and one to validate output format. The SKILL.md instructs the agent on what to analyze and how to write the report. Cron triggers the skill weekly in an isolated session.

**Tech Stack:** Bash (jq for JSONL parsing), OpenClaw skill system (SKILL.md + cron), Markdown output to `memory/`

---

## File Structure

```
skills/prompt-optimizer/
├── SKILL.md                    # Main skill — agent instructions
├── scripts/
│   ├── extract-transcripts.sh  # Parses JSONL → clean text summary
│   └── validate-report.sh      # Validates report format
├── templates/
│   └── weekly-report.md        # Report template
└── README.md                   # Skill documentation for ClawHub
```

```
tests/
├── fixtures/
│   ├── sample-transcript.jsonl  # Mock transcript data
│   └── sample-soul.md           # Mock SOUL.md
├── test-extract-transcripts.sh  # Tests for extraction script
├── test-validate-report.sh      # Tests for validation script
└── test-skill-integration.sh    # End-to-end skill test
```

---

## Chunk 1: Transcript Extraction Script

### Task 1: Create test fixture — sample JSONL transcript

**Files:**
- Create: `tests/fixtures/sample-transcript.jsonl`

- [ ] **Step 1: Write sample transcript fixture**

Create a realistic JSONL file with diverse message types — user questions, assistant responses, tool calls, failures. Include repeated patterns and a failed task.

```jsonl
{"type":"message","timestamp":"2026-03-10T09:15:00Z","message":{"role":"user","content":[{"type":"text","text":"What's the weather in Hangzhou today?"}]}}
{"type":"message","timestamp":"2026-03-10T09:15:05Z","message":{"role":"assistant","content":[{"type":"text","text":"The current weather in Hangzhou is 18°C with partly cloudy skies."}],"usage":{"cost":{"total":"0.003"}}}}
{"type":"message","timestamp":"2026-03-10T10:30:00Z","message":{"role":"user","content":[{"type":"text","text":"Search for AI agent framework comparisons 2026"}]}}
{"type":"message","timestamp":"2026-03-10T10:30:12Z","message":{"role":"assistant","content":[{"type":"toolUse","name":"web_search","input":{"query":"AI agent framework comparisons 2026"}},{"type":"text","text":"Here are the top AI agent frameworks in 2026..."}],"usage":{"cost":{"total":"0.008"}}}}
{"type":"message","timestamp":"2026-03-10T14:00:00Z","message":{"role":"user","content":[{"type":"text","text":"What's the weather in Hangzhou today?"}]}}
{"type":"message","timestamp":"2026-03-10T14:00:04Z","message":{"role":"assistant","content":[{"type":"text","text":"Currently 21°C and sunny in Hangzhou."}],"usage":{"cost":{"total":"0.003"}}}}
{"type":"message","timestamp":"2026-03-11T08:00:00Z","message":{"role":"user","content":[{"type":"text","text":"Help me write a Python script to scrape product prices"}]}}
{"type":"message","timestamp":"2026-03-11T08:00:30Z","message":{"role":"assistant","content":[{"type":"toolUse","name":"system.run","input":{"command":"python3 scraper.py"}},{"type":"text","text":"I encountered an error: ModuleNotFoundError: No module named 'beautifulsoup4'. Let me try installing it..."}],"usage":{"cost":{"total":"0.012"}}}}
{"type":"message","timestamp":"2026-03-11T08:01:00Z","message":{"role":"user","content":[{"type":"text","text":"Help me write a Python script to scrape product prices"}]}}
{"type":"message","timestamp":"2026-03-11T08:01:15Z","message":{"role":"assistant","content":[{"type":"toolUse","name":"system.run","input":{"command":"pip install beautifulsoup4 && python3 scraper.py"}},{"type":"text","text":"Successfully scraped 45 products with prices."}],"usage":{"cost":{"total":"0.015"}}}}
{"type":"message","timestamp":"2026-03-11T11:00:00Z","message":{"role":"user","content":[{"type":"text","text":"Search for AI agent framework comparisons 2026"}]}}
{"type":"message","timestamp":"2026-03-11T11:00:10Z","message":{"role":"assistant","content":[{"type":"text","text":"Based on the latest comparisons of AI agent frameworks..."}],"usage":{"cost":{"total":"0.007"}}}}
{"type":"message","timestamp":"2026-03-12T09:00:00Z","message":{"role":"user","content":[{"type":"text","text":"What's the weather in Hangzhou today?"}]}}
{"type":"message","timestamp":"2026-03-12T09:00:03Z","message":{"role":"assistant","content":[{"type":"text","text":"Hangzhou weather: 16°C, light rain expected this afternoon."}],"usage":{"cost":{"total":"0.003"}}}}
{"type":"message","timestamp":"2026-03-12T15:00:00Z","message":{"role":"user","content":[{"type":"text","text":"Translate this document from Chinese to English"}]}}
{"type":"message","timestamp":"2026-03-12T15:00:20Z","message":{"role":"assistant","content":[{"type":"text","text":"Here is the translated document..."}],"usage":{"cost":{"total":"0.025"}}}}
```

- [ ] **Step 2: Commit fixture**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add tests/fixtures/sample-transcript.jsonl
git commit -m "test: add sample JSONL transcript fixture for prompt-optimizer"
```

---

### Task 2: Write the transcript extraction script

**Files:**
- Create: `skills/prompt-optimizer/scripts/extract-transcripts.sh`
- Test: `tests/test-extract-transcripts.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test-extract-transcripts.sh`:

```bash
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
    ((PASS++))
  else
    echo "  ❌ $label — expected to find: $expected"
    ((FAIL++))
  fi
}

assert_line_count_gte() {
  local label="$1" output="$2" min="$3"
  local count
  count=$(echo "$output" | wc -l | tr -d ' ')
  if [ "$count" -ge "$min" ]; then
    echo "  ✅ $label (got $count lines)"
    ((PASS++))
  else
    echo "  ❌ $label — expected >= $min lines, got $count"
    ((FAIL++))
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x tests/test-extract-transcripts.sh
bash tests/test-extract-transcripts.sh
```

Expected: FAIL — script not found

- [ ] **Step 3: Write the extraction script**

Create `skills/prompt-optimizer/scripts/extract-transcripts.sh`:

```bash
#!/bin/bash
# extract-transcripts.sh — Parse JSONL transcripts into a structured text summary
# Usage: extract-transcripts.sh <jsonl_file_or_dir> [days_back]
# Output: Structured text summary to stdout
set -euo pipefail

INPUT="${1:?Usage: extract-transcripts.sh <jsonl_file_or_dir> [days_back]}"
DAYS_BACK="${2:-7}"
CUTOFF_DATE=$(date -v-${DAYS_BACK}d +%Y-%m-%d 2>/dev/null || date -d "${DAYS_BACK} days ago" +%Y-%m-%d)

# Collect JSONL files
FILES=()
if [ -d "$INPUT" ]; then
  while IFS= read -r f; do FILES+=("$f"); done < <(find "$INPUT" -name "*.jsonl" -type f)
else
  FILES=("$INPUT")
fi

if [ ${#FILES[@]} -eq 0 ]; then
  echo "No JSONL files found in $INPUT"
  exit 1
fi

# Parse all files
ALL_MESSAGES=""
for FILE in "${FILES[@]}"; do
  ALL_MESSAGES+=$(cat "$FILE")
  ALL_MESSAGES+=$'\n'
done

# Extract user questions
echo "=== USER QUESTIONS ==="
echo "$ALL_MESSAGES" | jq -r '
  select(.type == "message" and .message.role == "user")
  | .timestamp + " | " + (.message.content[] | select(.type == "text") | .text)
' 2>/dev/null | sort || true

# Find repeated questions (by similarity — exact match for MVP)
echo ""
echo "=== REPEATED PATTERNS ==="
echo "$ALL_MESSAGES" | jq -r '
  select(.type == "message" and .message.role == "user")
  | (.message.content[] | select(.type == "text") | .text)
' 2>/dev/null | sort | uniq -c | sort -rn | head -10 | while read -r count question; do
  if [ "$count" -gt 1 ]; then
    echo "  ${count}x repeated: $question"
  fi
done || true

# Extract tool usage
echo ""
echo "=== TOOL USAGE ==="
echo "$ALL_MESSAGES" | jq -r '
  select(.type == "message" and .message.role == "assistant")
  | .message.content[]
  | select(.type == "toolUse")
  | .name
' 2>/dev/null | sort | uniq -c | sort -rn || true

# Extract failures (assistant messages containing error indicators)
echo ""
echo "=== FAILURES & ERRORS ==="
echo "$ALL_MESSAGES" | jq -r '
  select(.type == "message" and .message.role == "assistant")
  | .timestamp as $ts
  | .message.content[]
  | select(.type == "text")
  | select(.text | test("error|Error|ERROR|fail|Fail|FAIL|exception|Exception"; "i"))
  | $ts + " | " + .text
' 2>/dev/null | head -20 || true

# Cost summary
echo ""
echo "=== COST SUMMARY ==="
TOTAL_COST=$(echo "$ALL_MESSAGES" | jq -r '
  select(.type == "message" and .message.role == "assistant" and .message.usage.cost.total != null)
  | .message.usage.cost.total
' 2>/dev/null | awk '{s+=$1} END {printf "%.4f", s}' || echo "0")
MSG_COUNT=$(echo "$ALL_MESSAGES" | jq -r '
  select(.type == "message" and .message.role == "user")
  | .timestamp
' 2>/dev/null | wc -l | tr -d ' ' || echo "0")
echo "Total cost: \$${TOTAL_COST}"
echo "Total user messages: ${MSG_COUNT}"
if [ "$MSG_COUNT" -gt 0 ]; then
  AVG=$(echo "$TOTAL_COST $MSG_COUNT" | awk '{printf "%.4f", $1/$2}')
  echo "Average cost per interaction: \$${AVG}"
fi
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x skills/prompt-optimizer/scripts/extract-transcripts.sh
bash tests/test-extract-transcripts.sh
```

Expected: All 6 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/prompt-optimizer/scripts/extract-transcripts.sh tests/test-extract-transcripts.sh
git commit -m "feat: add transcript extraction script with tests"
```

---

## Chunk 2: Report Template & Validation

### Task 3: Create report template

**Files:**
- Create: `skills/prompt-optimizer/templates/weekly-report.md`

- [ ] **Step 1: Write the report template**

```markdown
# ClawForage Weekly Optimization — Week {WEEK_NUMBER}

**Period:** {START_DATE} to {END_DATE}
**Messages analyzed:** {MSG_COUNT}
**Total cost:** ${TOTAL_COST}

## 🔄 Repeated Patterns

{REPEATED_PATTERNS}

## 📝 SOUL.md Suggestions

{SOUL_SUGGESTIONS}

## 🧩 Recommended Skills

{SKILL_RECOMMENDATIONS}

## ⚠️ Failure Analysis

{FAILURE_ANALYSIS}

## 📊 Usage Stats

- Most used tools: {TOP_TOOLS}
- Average cost per interaction: ${AVG_COST}
- Topics covered: {TOPICS}

---
*Generated by ClawForage Prompt Optimizer v0.1.0*
```

- [ ] **Step 2: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/prompt-optimizer/templates/weekly-report.md
git commit -m "feat: add weekly report template"
```

---

### Task 4: Write report validation script

**Files:**
- Create: `skills/prompt-optimizer/scripts/validate-report.sh`
- Test: `tests/test-validate-report.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test-validate-report.sh`:

```bash
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
    ((PASS++))
  else
    echo "  ❌ $label — expected exit $expected, got $actual"
    ((FAIL++))
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x tests/test-validate-report.sh
bash tests/test-validate-report.sh
```

Expected: FAIL — script not found

- [ ] **Step 3: Write the validation script**

Create `skills/prompt-optimizer/scripts/validate-report.sh`:

```bash
#!/bin/bash
# validate-report.sh — Validate that a weekly report has all required sections
# Usage: validate-report.sh <report.md>
# Exit 0 if valid, 1 if invalid
set -euo pipefail

REPORT="${1:?Usage: validate-report.sh <report.md>}"

if [ ! -s "$REPORT" ]; then
  echo "ERROR: Report file is empty or missing: $REPORT"
  exit 1
fi

ERRORS=0

check_section() {
  local section="$1"
  if ! grep -q "$section" "$REPORT"; then
    echo "ERROR: Missing required section: $section"
    ((ERRORS++))
  fi
}

check_section "# ClawForage Weekly Optimization"
check_section "Repeated Patterns"
check_section "SOUL.md Suggestions"
check_section "Recommended Skills"
check_section "Failure Analysis"

if [ "$ERRORS" -gt 0 ]; then
  echo "Validation failed: $ERRORS missing section(s)"
  exit 1
fi

echo "Report validation passed"
exit 0
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x skills/prompt-optimizer/scripts/validate-report.sh
bash tests/test-validate-report.sh
```

Expected: All 3 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/prompt-optimizer/scripts/validate-report.sh tests/test-validate-report.sh
git commit -m "feat: add report validation script with tests"
```

---

## Chunk 3: SKILL.md — Full Agent Instructions

### Task 5: Write the production SKILL.md

**Files:**
- Modify: `skills/prompt-optimizer/SKILL.md`

- [ ] **Step 1: Write the full SKILL.md with proper OpenClaw frontmatter and agent instructions**

```markdown
---
name: clawforage-prompt-optimizer
description: Analyzes your conversation transcripts weekly to find patterns, suggest SOUL.md improvements, and recommend skills
version: 0.1.0
emoji: "🔧"
user-invocable: true
metadata: {"openclaw":{"requires":{"bins":["jq","bash"]}}}
---

# Prompt & Workflow Optimizer

You are a meta-analysis agent run by ClawForage. Your job: review the user's recent conversation transcripts and produce an actionable weekly optimization report.

## Step 1: Extract Transcript Data

Run the extraction script on the user's transcripts directory:

```bash
bash {baseDir}/scripts/extract-transcripts.sh ~/.openclaw/agents/default/sessions/ 7
```

This outputs a structured summary of:
- All user questions from the past 7 days
- Repeated questions (exact matches)
- Tool usage frequency
- Failures and errors
- Cost summary

Read the output carefully before proceeding.

## Step 2: Read Current SOUL.md

```bash
cat memory/SOUL.md 2>/dev/null || echo "No SOUL.md found"
```

Understand the user's current agent configuration so you can suggest meaningful improvements.

## Step 3: Analyze and Write Report

Based on the extracted data and current SOUL.md, write a report to `memory/optimization/week-{WEEK}.md`.

Create the directory first:

```bash
mkdir -p memory/optimization
```

Your report MUST follow this structure:

### Repeated Patterns
Identify questions asked 2+ times. For each:
- State the pattern and frequency
- Suggest a concrete action: add info to SOUL.md, create a cron job, or install a skill

### SOUL.md Suggestions
Propose specific additions or changes to SOUL.md. Write them as ready-to-copy text blocks. Examples:
- Adding default preferences ("Default weather location: Hangzhou")
- Adding workflow shortcuts ("When asked to translate, always use DeepL API first")
- Removing outdated instructions

### Recommended Skills
Based on the user's most common tasks, search ClawHub for relevant skills. For each:
- Skill name and what it does
- Why it matches the user's usage pattern
- Install command

### Failure Analysis
For each error or multi-attempt task:
- What went wrong
- Root cause (missing dependency, unclear prompt, wrong tool)
- Suggested prevention (add to SOUL.md, install dependency, create pre-check skill)

### Usage Stats
Summarize: message count, total cost, average cost, top tools, topic distribution.

## Step 4: Validate Report

```bash
bash {baseDir}/scripts/validate-report.sh memory/optimization/week-{WEEK}.md
```

If validation fails, fix the missing sections and re-validate.

## Constraints

- **Read-only**: Never modify transcripts, SOUL.md, or any existing files
- **Suggestions only**: Present changes for user approval, never auto-apply
- **Concise**: Max 500 words per report
- **Cheap model**: This skill should run on the cheapest available model (GPT-5 nano or equivalent)
- **Privacy**: Never include full message content in reports — summarize patterns only
```

- [ ] **Step 2: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/prompt-optimizer/SKILL.md
git commit -m "feat: rewrite SKILL.md with full OpenClaw-compatible agent instructions"
```

---

## Chunk 4: Integration Test & Documentation

### Task 6: Write integration test

**Files:**
- Create: `tests/test-skill-integration.sh`

- [ ] **Step 1: Write integration test**

This test simulates the full skill flow: extraction → analysis input → validation.

```bash
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
    echo "  ✅ $label"; ((PASS++))
  else
    echo "  ❌ $label"; ((FAIL++))
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
    echo "  ✅ Has section: $section"; ((PASS++))
  else
    echo "  ❌ Missing section: $section"; ((FAIL++))
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

- Python scraping task needed 2 attempts due to missing beautifulsoup4 → Add dependency pre-check to SOUL.md: "Before running Python scripts, verify required packages are installed"

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
  echo "  ✅ Has YAML frontmatter"; ((PASS++))
else
  echo "  ❌ Missing YAML frontmatter"; ((FAIL++))
fi
if grep -q "name:" "$SKILL_MD"; then
  echo "  ✅ Has name field"; ((PASS++))
else
  echo "  ❌ Missing name field"; ((FAIL++))
fi
if grep -q "description:" "$SKILL_MD"; then
  echo "  ✅ Has description field"; ((PASS++))
else
  echo "  ❌ Missing description field"; ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
```

- [ ] **Step 2: Run integration test**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
chmod +x tests/test-skill-integration.sh
bash tests/test-skill-integration.sh
```

Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add tests/test-skill-integration.sh
git commit -m "test: add integration test for prompt-optimizer skill"
```

---

### Task 7: Write skill README and sample SOUL.md fixture

**Files:**
- Create: `skills/prompt-optimizer/README.md`
- Create: `tests/fixtures/sample-soul.md`

- [ ] **Step 1: Write README.md for ClawHub listing**

```markdown
# 🔧 ClawForage Prompt Optimizer

Analyzes your conversation transcripts and suggests improvements to your agent configuration.

## What It Does

Runs weekly (or on-demand) to:
- Find questions you ask repeatedly → suggests adding defaults to SOUL.md
- Track which tools you use most → recommends relevant ClawHub skills
- Identify task failures → suggests preventive measures
- Summarize your AI spending → cost transparency

## Install

```bash
openclaw skill install clawforage/prompt-optimizer
```

## Requirements

- `jq` (JSON processor) — install via `brew install jq` or `apt install jq`
- `bash` (v4+)

## Schedule

Default: Sunday 3am (weekly). Change via:
```bash
openclaw cron edit clawforage-prompt-optimizer --cron "0 9 * * 1"
```

## Cost

~$0.05–0.15 per run (depends on transcript volume). Uses cheapest available model.

## Output

Weekly reports saved to `memory/optimization/week-{N}.md`. Never modifies your SOUL.md — only suggests changes for your approval.

## Part of ClawForage

Built by [InspireHub Labs](https://inspireehub.ai). See also:
- [Knowledge Harvester](../knowledge-harvester/) — automated daily briefings
- [Research Agent](../research-agent/) — domain-specific deep research
```

- [ ] **Step 2: Write sample SOUL.md fixture**

```markdown
# SOUL.md

**Identity**
Personal AI assistant for Daniel. Focus on tech startup tasks, product strategy, and development.

**Preferences**
Language: Chinese for casual, English for technical. Structured output preferred.

**Current Focus**
- InspireHub platform development
- Company setup in Hangzhou
- AI product ecosystem design
```

- [ ] **Step 3: Commit**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git add skills/prompt-optimizer/README.md tests/fixtures/sample-soul.md
git commit -m "docs: add prompt-optimizer README and sample SOUL.md fixture"
```

---

### Task 8: Run all tests and final commit

- [ ] **Step 1: Run all tests**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
echo "=== Running all tests ===" && \
bash tests/test-extract-transcripts.sh && \
bash tests/test-validate-report.sh && \
bash tests/test-skill-integration.sh && \
echo "=== ALL TESTS PASSED ==="
```

Expected: All tests pass

- [ ] **Step 2: Verify file structure**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
find skills/prompt-optimizer -type f | sort
find tests -type f | sort
```

Expected:
```
skills/prompt-optimizer/README.md
skills/prompt-optimizer/SKILL.md
skills/prompt-optimizer/scripts/extract-transcripts.sh
skills/prompt-optimizer/scripts/validate-report.sh
skills/prompt-optimizer/templates/weekly-report.md
tests/fixtures/sample-soul.md
tests/fixtures/sample-transcript.jsonl
tests/test-extract-transcripts.sh
tests/test-skill-integration.sh
tests/test-validate-report.sh
```

- [ ] **Step 3: Final commit if any remaining changes**

```bash
cd /Users/daniel/Documents/inspireHub/clawforage
git status
# If anything unstaged:
git add -A && git commit -m "chore: prompt-optimizer v0.1.0 complete"
```
