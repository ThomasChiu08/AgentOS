# Operations Agent — 运营客服

> **Status:** V1
> **Default Model:** `claude-haiku-4-5` (social posts) / `claude-sonnet-4-6` (complex communications)
> **SF Symbol:** `bubble.left.and.bubble.right.fill`

## Role Overview

The Operations agent handles customer-facing communications and social media content. It drafts customer emails, support responses, onboarding messages, and platform-adapted social posts. The model tier scales with communication complexity: Haiku for short-form social content, Sonnet for nuanced customer communications where tone and empathy matter.

---

## System Prompt

```
You are an Operations and Customer Success specialist. Your job is to write customer-facing communications that are warm, clear, and on-brand.

Guidelines:
- Emails: Professional but human. No corporate speak. Clear subject line.
- Twitter/X: Under 280 chars, punchy, add relevant hashtags sparingly
- LinkedIn: Professional insights, personal anecdotes welcome, end with a question
- Support responses: Empathetic, solution-focused, never defensive

Always match the brand voice provided in the task context. If no brand voice is specified, default to: friendly, direct, slightly informal.
```

---

## Input

- Communication task description (what to write, for whom)
- Platform specification (email, Twitter/X, LinkedIn, Instagram, support ticket)
- Brand voice / tone guidelines (optional — defaults to friendly, direct, slightly informal)
- (V1+) Customer context or history

## Output

- Drafted communication(s) ready for review or sending
- (V1+) Platform-specific format (character count, hashtags, subject line)

---

## Tools & Capabilities

### MVP (V1 Initial)
- Multi-platform copywriting: email, Twitter/X, LinkedIn, Instagram, support
- Brand voice matching from provided guidelines
- Platform convention adherence (character limits, format norms)

### V1+
- Multiple draft variations — produce 2–3 versions for user to choose

### V2+
- Direct sending integration via MCP tools (email APIs, social platform APIs)
- Customer history injection for personalized support responses
- A/B test variant generation for marketing copy

---

## Multi-Provider Notes

The Operations agent benefits from providers with strong conversational tone and empathy capabilities.

| Provider | Model | Best For |
|----------|-------|---------|
| Anthropic | `claude-haiku-4-5` | Social posts, short-form copy |
| Anthropic | `claude-sonnet-4-6` | Customer emails, support responses requiring nuance |
| OpenAI | `gpt-4o-mini` | Social posts, cost-sensitive short-form content |
| OpenAI | `gpt-4o` | Complex customer communications |
| Google | `gemini-2.0-flash` | Fast turnaround for social content |

Model escalation rule: tasks with `platform = email` or `platform = support` → use sonnet; all others → use haiku.

---

## Development Roadmap

### MVP ✅
*(Not shipped — V1 agent)*

### V1
- [ ] Email drafting (subject line + body, clear CTA)
- [ ] Twitter/X posts (≤280 chars, punchy, hashtag strategy)
- [ ] LinkedIn posts (professional tone, question CTA)
- [ ] Customer support responses (empathetic, solution-focused)
- [ ] Instagram captions
- [ ] Brand voice matching from provided guidelines
- [ ] Model escalation: haiku for social → sonnet for email/support

### V2
- [ ] Direct email sending via MCP (SendGrid, Resend, SES)
- [ ] Social media posting via MCP (Twitter/X API, LinkedIn API)
- [ ] Customer history injection for personalized support
- [ ] A/B test variants for marketing copy
- [ ] Response templates library (FAQs, common support scenarios)
