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

~$0.02-0.05 per run (10 articles). Uses cheapest available model for summarization.

## Legal Safety

- Uses Google News RSS (public, free, no scraping)
- Stores summaries only — never reproduces source content
- Always attributes source with URL
- User controls which domains to track

## Part of ClawForage

Built by [InspireHub Labs](https://inspireehub.ai). See also:
- [Prompt Optimizer](../prompt-optimizer/) — weekly agent self-improvement
- [Research Agent](../research-agent/) — deep domain research
