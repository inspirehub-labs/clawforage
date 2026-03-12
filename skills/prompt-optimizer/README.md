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

Or run manually anytime:
```
/clawforage-prompt-optimizer
```

## Cost

~$0.05–0.15 per run (depends on transcript volume). Uses your default model.

## Output

Weekly reports saved to `memory/optimization/week-{N}.md`. Never modifies your SOUL.md — only suggests changes for your approval.

## Part of ClawForage

Built by [InspireHub Labs](https://inspireehub.ai). See also:
- [Knowledge Harvester](../knowledge-harvester/) — automated daily briefings
- [Research Agent](../research-agent/) — domain-specific deep research
