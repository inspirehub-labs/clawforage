# ClawForage — Feasibility Analysis & Priority Assessment

**Date:** 2026-03-12
**Status:** Approved (brainstorming complete)

## Context

Analysis of building a suite of OpenClaw skills focused on automated knowledge curation and agent self-optimization, targeting the OpenClaw 300K-star ecosystem as a distribution channel for InspireHub Labs.

## Three Products

### 1. Prompt & Workflow Optimizer (Priority 1)
- **What:** Weekly cron analyzing JSONL transcripts, suggesting SOUL.md improvements and skill recommendations
- **Feasibility:** High — zero external dependencies, operates on local data only
- **Legal risk:** None — purely local data
- **Build time:** 1-2 weeks
- **Cost to user:** < $1/month
- **Differentiation:** No competitors — nobody does self-optimizing agent configs

### 2. Knowledge Harvester (Priority 2)
- **What:** Daily cron fetching trending content via licensed APIs, summarizing into memory/ files
- **Feasibility:** High — standard RAG pipeline, OpenClaw's memory system handles indexing
- **Legal risk:** Low-Medium — mitigated by using licensed APIs + summaries only
- **Build time:** 2-3 weeks
- **Cost to user:** $6-15/month
- **Differentiation:** Medium — Letta's sleep-time compute is conceptually adjacent

### 3. Research Agent (Priority 3)
- **What:** Continuous domain research with knowledge graphs, source management, citation tracking
- **Feasibility:** High — extends Harvester + Cognee integration
- **Legal risk:** Low-Medium — same mitigations as Harvester
- **Build time:** 4-5 weeks
- **Cost to user:** $10-30/month
- **Differentiation:** High — personalized domain expertise is sticky

## Build Sequence

```
Week 1-2:   Prompt Optimizer MVP
Week 3:     Ship to ClawHub, collect feedback
Week 4-6:   Knowledge Harvester
Week 7:     Ship, iterate
Week 8-12:  Research Agent
```

## Key Design Decisions

1. **Summaries only, never verbatim** — legal safety
2. **Licensed APIs only** — NewsAPI, Google News RSS, ArXiv API
3. **User-triggered > autonomous** — cron is opt-in
4. **Cost transparency** — every skill documents cost per run
5. **Suggestions, not auto-apply** — Optimizer never modifies config without approval

## Risks

| Risk | Mitigation |
|------|-----------|
| OpenClaw foundation governance changes | Keep skills thin, avoid deep coupling to internals |
| Letta ships consumer-accessible sleep-time compute | Move fast, ship Optimizer first (no competitor) |
| Copyright claims on summarized content | Licensed APIs + 10-word verbatim limit + source attribution |
| Low adoption on ClawHub | Ship 2-3 simple utility skills first for reputation |

## Source

Based on analysis of: "The claw-token-killer concept: feasibility, market, and competitive reality" (research document, March 2026)
