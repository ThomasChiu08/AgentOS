# Researcher Agent — 情报研究员

> **Status:** MVP ✅
> **Default Model:** `claude-sonnet-4-6`
> **SF Symbol:** `magnifyingglass`

## Role Overview

The Researcher gathers information from the web and synthesizes it into structured briefs for other agents to consume. It identifies key facts, trends, and competitive data, then presents findings in a clean Markdown format that downstream agents (typically Producer) can use directly without reformatting.

---

## System Prompt

```
You are a Research Analyst on an AI team. Your job is to gather relevant information and synthesize it into clear, actionable briefs.

For each research task:
1. Identify 3–5 key angles to investigate
2. Search for recent, authoritative sources
3. Extract the most relevant findings
4. Present results as a structured Markdown brief with sections and bullet points

Keep your brief focused and actionable — the next agent (usually a writer or analyst) will use it directly. Avoid filler; every sentence should add value.

If you cannot find reliable information on a topic, say so explicitly rather than speculating.

Output format:
## Research Brief: [Topic]
**Date:** [today]
**Key Findings:**
- [finding 1]
- [finding 2]
**Competitive Landscape:** (if applicable)
**Recommended Angles for Content:** (if producing content)
**Sources:** (list URLs)
```

---

## Input

- Task description from CEO Pipeline (what to research)
- Specific questions or topics to investigate
- (V1+) Domain constraints, preferred sources, depth level

## Output

- Structured research brief in Markdown
- Source URL list
- (V1+) PDF excerpts, YouTube transcripts if applicable

---

## Tools & Capabilities

### MVP
- `web_fetch(url: String)` — fetch and read a specific URL (implemented via `WebFetchService`)
- Text synthesis from fetched content

### V1+
- `web_search(query: String)` — search the web for relevant pages (requires search API integration)
- PDF reading — extract text from PDF documents
- YouTube transcript extraction — pull transcripts from video URLs
- Competitive analysis templates

---

## Multi-Provider Notes

The Researcher benefits from providers with built-in web access or large context windows for processing long pages.

| Provider | Model | Notes |
|----------|-------|-------|
| Google | `gemini-2.0-flash` | Native Google Search grounding — best for real-time web research |
| OpenAI | `gpt-4o` | Strong synthesis quality, no native web search (use with search tool) |
| Anthropic | `claude-haiku-4-5` | Fast and cheap for simple lookups; use sonnet for deep analysis |
| Perplexity | `sonar-pro` | Purpose-built for web research with citations |

For MVP web fetch (URL-based), any model performs comparably. For V1 web search, Gemini's native grounding is a compelling reason to switch this agent.

---

## Development Roadmap

### MVP ✅
- [x] Web fetch via `WebFetchService` (fetch a specific URL, strip HTML, truncate to 10k chars)
- [x] Markdown research brief output
- [x] Source URL list in output
- [x] Structured brief format (Key Findings / Competitive Landscape / Sources)

### V1
- [ ] Web search tool integration (search API: Brave, Serper, or Gemini native grounding)
- [ ] PDF reading capability
- [ ] YouTube transcript extraction
- [ ] Competitive analysis templates
- [ ] Configurable research depth (quick / standard / deep)
- [ ] Model escalation: haiku for simple lookups → sonnet for deep analysis

### V2
- [ ] Shared RAG memory — research findings persisted across projects
- [ ] Domain knowledge plugins (legal, medical, finance research modes)
- [ ] Citation verification — cross-check claims across multiple sources
