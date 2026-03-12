# 🔬 ClawForage Research Agent

Deep domain research that goes beyond daily briefings — entity extraction, cross-article connections, and structured intelligence reports.

## What It Does

Runs twice weekly (or on-demand) to analyze your harvested knowledge and produce domain research reports:

- **Entity extraction** — identifies companies, people, products, and technologies across articles
- **Cross-article connections** — finds shared entities, evolving stories, and emerging patterns
- **Domain reports** — synthesized intelligence with key developments, entity maps, and outlook
- **Source quality management** — tiered source whitelists per domain

## Install

```bash
openclaw skill install clawforage/research-agent
```

## Prerequisites

Requires the Knowledge Harvester to populate `memory/knowledge/` with articles first:
```bash
openclaw skill install clawforage/knowledge-harvester
```

## Setup

1. Run the Knowledge Harvester to build your knowledge base
2. Source whitelists are auto-created on first run, or create manually:
```bash
mkdir -p memory/clawforage/sources
# Edit memory/clawforage/sources/{domain-slug}.md with trusted sources
```

3. Run manually or let the cron trigger:
```
/clawforage-research-agent
```

## Requirements

- `jq` — `brew install jq` or `apt install jq`
- `bash` (v4+)
- `grep` with extended regex support

## Cost

~$0.10-0.30 per run. Uses mid-tier model for synthesis (benefits from stronger reasoning).

## Output

Domain reports saved to `memory/research/{domain}/report-{YYYY}-{WW}.md`. Reports include key developments, entity maps, cross-article connections, and forward-looking outlook.

## Part of ClawForage

Built by [InspireHub Labs](https://inspireehub.ai). See also:
- [Prompt Optimizer](../prompt-optimizer/) — weekly agent self-improvement
- [Knowledge Harvester](../knowledge-harvester/) — automated daily briefings
