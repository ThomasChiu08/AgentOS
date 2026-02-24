# Finance Agent — 财务合规

> **Status:** V1
> **Default Model:** `claude-haiku-4-5` (cost summaries) / `claude-sonnet-4-6` (compliance review)
> **SF Symbol:** `dollarsign.circle.fill`

## Role Overview

The Finance agent serves two distinct functions: (1) cost analysis — summarizing token usage and API spend across pipeline stages, and (2) compliance review — scanning content for potentially false claims, privacy-sensitive data, or legally risky language. Cost tabulation is a lightweight, structured task (Haiku). Compliance review requires careful reasoning about nuanced language (Sonnet). Note: this agent flags for human review; it does not make legal determinations.

---

## System Prompt

```
You are a Finance and Compliance Analyst. Your job is to analyze costs and review content for compliance risks.

For cost analysis:
- Summarize token usage and costs per stage
- Identify opportunities to reduce cost (cheaper models, shorter prompts)
- Flag if costs exceeded budget

For compliance review:
- Flag potentially false or unsubstantiated claims
- Identify privacy-sensitive data that should be redacted
- Note any legally sensitive language (warranties, guarantees, medical/legal/financial advice)
- This is not legal advice — flag for human review, not auto-reject

Output: structured report with findings and recommendations.
```

---

## Input

**Cost Analysis Mode:**
- Stage cost data from Pipeline (token counts, model names, timestamps)
- Budget threshold (optional — triggers over-budget flag)

**Compliance Review Mode:**
- Content to review (text of any artifact)
- Compliance domain (general / privacy / marketing / medical / legal / financial)

## Output

**Cost Analysis:**
- Per-stage cost breakdown table
- Total pipeline cost
- Cost optimization recommendations
- Over-budget flag if applicable

**Compliance Review:**
- Compliance flag report: flagged passages with risk category and severity
- Recommended action per flag (redact / rewrite / legal review)
- Overall compliance risk level (low / medium / high)

---

## Tools & Capabilities

### MVP (V1 Initial)
- Read access to pipeline cost data (token counts × model pricing)
- Content compliance scanning (text analysis only)

### V1+
- Structured cost report with optimization recommendations
- Compliance templates per domain (marketing, SaaS, content creator)
- Budget alerts: notify user if projected pipeline cost exceeds threshold

### V2+
- Real-time cost tracking during pipeline execution
- Integration with accounting tools via MCP (Stripe, QuickBooks cost tagging)
- Automated PII redaction before content export

---

## Multi-Provider Notes

The Finance agent's two modes have very different model requirements.

| Mode | Provider | Model | Notes |
|------|----------|-------|-------|
| Cost Analysis | Anthropic | `claude-haiku-4-5` | Structured math; any capable model works |
| Cost Analysis | OpenAI | `gpt-4o-mini` | Good alternative, cheap |
| Compliance Review | Anthropic | `claude-sonnet-4-6` | Strong at nuanced language analysis |
| Compliance Review | OpenAI | `gpt-4o` | Reliable for compliance flagging |
| Compliance Review | Anthropic | `claude-opus-4-6` | For high-stakes legal/medical/financial content |

Model selection rule: `mode = cost_analysis` → haiku; `mode = compliance_review` → sonnet (escalate to opus for sensitive domains).

---

## Development Roadmap

### MVP ✅
*(Not shipped — V1 agent)*

### V1
- [ ] Per-stage cost breakdown (tokens × model pricing table)
- [ ] Total pipeline cost summary
- [ ] Cost optimization recommendations
- [ ] Over-budget flag with configurable threshold
- [ ] Compliance scanning for false/unsubstantiated claims
- [ ] Privacy-sensitive data flagging (PII detection)
- [ ] Legally sensitive language flagging (guarantees, medical/financial advice)
- [ ] Model escalation: haiku for cost → sonnet for compliance

### V2
- [ ] Real-time cost tracking during pipeline execution (not just post-hoc)
- [ ] Automated PII redaction before artifact export
- [ ] Budget management: per-project cost caps
- [ ] Compliance templates: GDPR, CCPA, FTC advertising guidelines
- [ ] Accounting integration via MCP (Stripe, expense tracking)
