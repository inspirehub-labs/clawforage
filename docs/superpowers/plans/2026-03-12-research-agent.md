# Research Agent Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an OpenClaw skill that performs deep domain-specific research — reusing the Harvester's fetch/dedup pipeline, adding entity extraction, cross-article relationship tracking, source quality management, and structured domain reports.

**Architecture:** The Research Agent is a SKILL.md-driven agent that orchestrates three new scripts: `extract-entities.sh` (pulls key entities from knowledge articles), `build-connections.sh` (finds relationships between entities across articles), and `generate-report.sh` (validates domain report format). It reuses the Harvester's `fetch-articles.sh` and `dedup-articles.sh` directly. Source whitelists are per-domain configs in `memory/clawforage/sources/`. No Cognee dependency in v0.1 — pure Markdown-based entity/relationship tracking (YAGNI).

**Tech Stack:** Bash, jq, grep, OpenClaw skill system, Markdown. Reuses Knowledge Harvester scripts.

---

## File Structure

```
skills/research-agent/
├── SKILL.md                          # Agent instructions (rewrite stub)
├── scripts/
│   ├── extract-entities.sh           # Extract entities from knowledge articles
│   ├── build-connections.sh          # Find cross-article entity relationships
│   └── validate-report.sh           # Validate domain report format
├── templates/
│   ├── domain-report.md             # Weekly domain report template
│   └── sources-example.md           # Example source whitelist
└── README.md                        # ClawHub listing
```

```
tests/
├── fixtures/
│   ├── sample-knowledge-dir/        # Dir with 3 knowledge articles for testing
│   │   ├── 2026-03-09-openai-agents.md
│   │   ├── 2026-03-10-crewai-funding.md
│   │   └── 2026-03-11-langchain-mcp.md
│   └── sample-sources.md            # Test source whitelist
├── test-extract-entities.sh
├── test-build-connections.sh
└── test-research-integration.sh
```
