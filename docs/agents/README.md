# AgentOS — Agent Directory

**Last Updated:** 2026-02-24

This directory contains per-agent specifications for all 7 agents in AgentOS. Each agent has its own focused development document with system prompt, input/output contracts, tools, and roadmap.

---

## Quick Reference

| # | Agent | Status | Model | SF Symbol | Primary Output |
|---|-------|--------|-------|-----------|----------------|
| 1 | [CEO](./ceo.md) | MVP ✅ | claude-opus-4-6 | `brain.head.profile` | Pipeline definition |
| 2 | [Researcher](./researcher.md) | MVP ✅ | claude-sonnet-4-6 | `magnifyingglass` | Research brief |
| 3 | [Producer](./producer.md) | MVP ✅ | claude-sonnet-4-6 | `pencil.and.outline` | Primary deliverable |
| 4 | [QA Reviewer](./qa-reviewer.md) | MVP ✅ | claude-sonnet-4-6 | `checkmark.shield.fill` | Review report |
| 5 | [Editor](./editor.md) | V1 | claude-haiku-4-5 | `textformat` | Formatted content |
| 6 | [Operations](./operations.md) | V1 | claude-haiku-4-5 / sonnet | `bubble.left.and.bubble.right.fill` | Communications |
| 7 | [Finance](./finance.md) | V1 | claude-haiku-4-5 / sonnet | `dollarsign.circle.fill` | Cost/compliance report |

---

## Model Selection Rationale

AgentOS uses a tiered model strategy to balance reasoning quality with cost and latency.

### Tier 1 — Opus (Deepest Reasoning)
**Used by:** CEO

The CEO performs the hardest cognitive task: interpreting ambiguous user intent and decomposing it into a correct, ordered Pipeline. A wrong decomposition cascades into wasted API calls across all downstream agents. Opus's superior reasoning justifies the higher cost at this single entry-point stage.

### Tier 2 — Sonnet (Capable + Efficient)
**Used by:** Researcher, Producer, QA Reviewer

These agents handle substantive work — research synthesis, content creation, critical evaluation — that requires strong reasoning and writing quality but not Opus-level depth. Sonnet is the best cost/capability tradeoff for high-quality production tasks.

### Tier 3 — Haiku (Fast + Cheap)
**Used by:** Editor, Operations (simple tasks), Finance (cost summaries)

Formatting, social media drafts, and cost tabulation are low-complexity transformations. Haiku's speed (and 3× cost savings vs. Sonnet) makes it ideal for these utility tasks. Operations and Finance can escalate to Sonnet for complex work (long-form customer communications, compliance review).

---

## Multi-Provider Support

AgentOS abstracts AI providers via `AIProviderProtocol`. All 7 agents can run on any of the 10 supported providers. Default assignments above use Anthropic models, but users can configure alternatives:

| Role | Best Alternative Providers |
|------|---------------------------|
| CEO | `openai/o3` (strong reasoning), `google/gemini-2.0-pro` |
| Researcher | `google/gemini-2.0-flash` (native web search), `openai/gpt-4o` |
| Producer | `openai/gpt-4o`, `google/gemini-2.0-pro` |
| QA Reviewer | `openai/gpt-4o`, `anthropic/claude-opus-4-6` (for critical reviews) |
| Editor | `openai/gpt-4o-mini`, `google/gemini-2.0-flash-lite` |
| Operations | `openai/gpt-4o-mini`, `google/gemini-2.0-flash` |
| Finance | `openai/gpt-4o-mini`, `google/gemini-2.0-flash-lite` |

Provider configuration is planned for V1 Team Config UI.

---

## Version Roadmap

### MVP (Ships Now) — Agents 1–4
Linear 4-stage pipeline: CEO → Researcher → Producer → QA Reviewer.
Covers the most common solo creator workflow: research + write + review.

### V1 — Adds Agents 5–7
- Editor/Formatter enables platform-ready publishing
- Operations/CX enables customer communication workflows
- Finance/Compliance adds cost awareness and legal safety checks
- Graph pipeline unlocks non-linear agent combinations

### V2 — Full MCP Integration
- Agents gain MCP tool access (GitHub, Notion, Slack, email sending)
- Shared RAG memory across pipeline stages
- Plugin system for custom agent types
- Self-improving agent prompts via feedback loop

---

## Adding a New Agent

1. Create `docs/agents/{role}.md` following the template in any existing agent file
2. Add `AgentRole` enum case in `Core/Models/AgentRole.swift`
3. Add default `AgentConfig` in `AgentOrchestrator`
4. Add `AgentCardView` entry in the Team UI
5. Update this README table
