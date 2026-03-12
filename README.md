<p align="center">
  <img src="https://img.shields.io/badge/OpenClaw-Skills-blue?style=for-the-badge" alt="OpenClaw Skills" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License" />
  <img src="https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge" alt="Active" />
</p>

# 🦀 ClawForage

### Your AI agent never stops learning.

ClawForage is a suite of [OpenClaw](https://github.com/openclaw) skills that make your AI agent **smarter every day** — by learning from your habits, building knowledge while you sleep, and becoming a domain expert in what matters to you.

---

## 🧩 The Suite

| Skill | What it does | Command |
|-------|-------------|---------|
| 🔧 **Prompt Optimizer** | Analyzes your conversations weekly, suggests `SOUL.md` improvements and skill recommendations | `/clawforage-prompt-optimizer` |
| 📰 **Knowledge Harvester** | Fetches trending articles overnight via Google News RSS, writes summaries into agent memory | `/clawforage-knowledge-harvester` |
| 🔬 **Research Agent** | Extracts entities, maps connections across articles, generates structured domain intelligence | `/clawforage-research-agent` |

---

## ⚡ Quick Start

```bash
# Install all skills from ClawHub
openclaw skill install clawforage

# Configure your domains of interest
mkdir -p memory/clawforage
cat > memory/clawforage/domains.md << 'EOF'
# My Domains
- AI agent frameworks
- startup news Asia
- renewable energy
EOF
```

That's it. The skills run automatically on schedule, or invoke any of them on-demand.

---

## 🔄 How They Work Together

```
  📰 Knowledge Harvester          🔬 Research Agent           🔧 Prompt Optimizer
  ─────────────────────          ──────────────────          ─────────────────────
  Daily @ 2am                    Mon + Thu @ 4am             Sunday @ 3am
  │                              │                           │
  ├─ Fetch trending articles     ├─ Extract entities         ├─ Analyze transcripts
  ├─ Summarize & deduplicate     ├─ Map connections          ├─ Find repeated patterns
  └─ Store in memory/knowledge/  ├─ Build timeline           ├─ Suggest SOUL.md changes
                │                └─ Generate domain report   └─ Recommend skills
                │                         │                          │
                └─────────────────────────┘                          │
                         Feeds into                        Optimizes everything
```

---

## 🛡️ Philosophy

| Principle | What it means |
|-----------|--------------|
| **Summaries, not copies** | We never store verbatim content — only AI-generated summaries with source attribution |
| **Licensed sources only** | All content sourced through public APIs (Google News RSS). No scraping. |
| **User control** | Every automated task is opt-in, configurable, and transparently scheduled |
| **Privacy first** | All data stays local. Domain interests are never shared externally |
| **No API keys needed** | Works out of the box with zero configuration for data sources |

---

## 📋 Requirements

- **OpenClaw** agent (with cron and memory support)
- `jq` — `brew install jq` or `apt install jq`
- `curl` — usually pre-installed
- `bash` (v4+)

---

## 📄 License

MIT

---

<p align="center">
  Built with 🧠 by <a href="https://inspireehub.ai">InspireHub Labs</a>
</p>
