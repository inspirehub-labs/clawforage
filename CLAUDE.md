# CLAUDE.md — ClawForage

## Project Overview

ClawForage is a suite of OpenClaw skills that maximize the value users get from their AI spend. Three skills, built incrementally:

1. **Prompt Optimizer** (Priority 1) — Analyzes conversation transcripts, suggests SOUL.md improvements and skill recommendations
2. **Knowledge Harvester** (Priority 2) — Cron-driven background briefings using licensed APIs, drops summaries into `memory/`
3. **Research Agent** (Priority 3) — Domain-specific continuous knowledge building with source management and knowledge graphs

## Repo Structure

```
clawforage/
├── CLAUDE.md              # This file
├── README.md              # Public-facing docs
├── package.json           # Project metadata
├── skills/                # OpenClaw skills (each dir = one skill)
│   ├── prompt-optimizer/  # Priority 1 — self-optimizing agent config
│   │   └── SKILL.md
│   ├── knowledge-harvester/ # Priority 2 — automated briefings
│   │   └── SKILL.md
│   └── research-agent/    # Priority 3 — domain research pipeline
│       └── SKILL.md
├── shared/                # Shared utilities across skills
│   ├── utils/
│   └── templates/
├── docs/
│   └── specs/             # Design documents and specs
└── tests/                 # Test scripts and fixtures
```

## Conventions

- **Skills are self-contained**: Each `SKILL.md` must work independently when installed in OpenClaw
- **Shared code via templates**: Skills reference shared Markdown templates, not code imports
- **Legal safety first**: Never store verbatim content. Summaries only. Licensed APIs only (NewsAPI, Google News RSS, Bing API).
- **Cost transparency**: Every skill documents its estimated token cost per run in SKILL.md frontmatter
- **User-triggered > autonomous**: Default to user control. Cron is opt-in, always configurable.

## OpenClaw Skill Format

Each skill directory contains:
- `SKILL.md` — YAML frontmatter + natural language instructions
- Supporting files referenced by SKILL.md (templates, configs)

Frontmatter fields: `name`, `description`, `version`, `author`, `tags`, `estimated_cost_per_run`, `cron` (optional)

## Development Workflow

1. Design spec in `docs/specs/YYYY-MM-DD-<topic>-design.md`
2. Build SKILL.md with instructions and test manually in OpenClaw
3. Write test scenarios in `tests/`
4. Publish to ClawHub when stable

## Brand

- Product name: **ClawForage**
- Publisher: InspireHub Labs
- Tagline: "Your AI never stops learning"
