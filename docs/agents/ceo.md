# CEO Agent — 战略规划师

> **Status:** MVP ✅
> **Default Model:** `claude-opus-4-6`
> **SF Symbol:** `brain.head.profile`

## Role Overview

The CEO is the entry point of every AgentOS session. It interprets the user's natural language goal — even if ambiguous — and decomposes it into an ordered Pipeline of 3–6 specialized agent stages. A wrong decomposition cascades into wasted work across all downstream agents, which is why the CEO uses Opus: the highest reasoning tier available.

---

## System Prompt

```
You are the CEO of a high-performance AI team. Your job is to help the user accomplish their goals by orchestrating a team of specialized AI agents.

When the user describes a task:
1. Briefly acknowledge the goal
2. Propose a Pipeline of 3–6 stages. For each stage, specify:
   - Agent role (researcher | producer | reviewer | editor | ops | finance)
   - One-sentence description of what that agent will do
3. Ask for approval before executing

Format your Pipeline as a numbered list. Be concise — users are busy.

Example:
User: "Write a cold email campaign for my SaaS product"
CEO: "Here's my plan:
1. Researcher → research the target audience and competitor emails
2. Producer → write 3 email variations (welcome, follow-up, re-engagement)
3. QA Reviewer → check tone, personalization, CTAs
4. Editor → format for email sending tools (Mailchimp-ready)"

If the task is simple (single agent can handle it), propose just 1–2 stages. Don't over-engineer.
```

---

## Input

- User's natural language task description (from CEO Chat)
- (V1+) Previous project context from SwiftData
- (V1+) User preferences and saved Pipeline templates

## Output

- Structured Pipeline definition displayed as numbered Markdown list
- Pipeline JSON for internal use:

```json
{
  "title": "iOS Launch Article",
  "stages": [
    { "order": 1, "role": "researcher", "task": "Gather iOS app launch strategies for 2026" },
    { "order": 2, "role": "producer", "task": "Write 800-word Medium-style launch article" },
    { "order": 3, "role": "reviewer", "task": "Review for tone, accuracy, engagement" },
    { "order": 4, "role": "editor", "task": "Format for Medium with proper headings and callouts" }
  ]
}
```

---

## Tools & Capabilities

### MVP
- API call only — no external tools needed for decomposition
- Parses user message and produces structured Pipeline JSON
- Displays Pipeline as markdown in CEO Chat before execution

### V1+
- Pipeline templates library (save and reuse successful patterns)
- Cost estimation per stage before user approval
- Multi-turn planning conversation (CEO asks clarifying questions)
- Context injection from previous projects

---

## Multi-Provider Notes

The CEO's core task is reasoning and decomposition — language quality matters more than domain knowledge or speed. Best alternatives to `claude-opus-4-6`:

| Provider | Model | Notes |
|----------|-------|-------|
| OpenAI | `o3` | Strong structured reasoning, good for complex decompositions |
| Google | `gemini-2.0-pro` | Solid alternative, slightly less reliable on structured output |
| Anthropic | `claude-sonnet-4-6` | Acceptable fallback when cost is a concern |

Avoid Haiku for the CEO role — decomposition errors are expensive to recover from.

---

## Development Roadmap

### MVP ✅
- [x] Natural language to Pipeline JSON decomposition
- [x] Markdown Pipeline display in CEO Chat
- [x] User approval gate before execution
- [x] 4-agent roster (researcher, producer, reviewer, editor)

### V1
- [ ] Multi-turn planning: CEO asks clarifying questions before proposing Pipeline
- [ ] Pipeline templates: save and replay successful patterns
- [ ] Cost estimation: show estimated cost per stage before approval
- [ ] 7-agent roster (adds editor, ops, finance)
- [ ] Per-agent model configuration in Team UI

### V2
- [ ] Self-improving prompts: CEO learns from user feedback on Pipeline quality
- [ ] RAG context: inject relevant past project summaries as context
- [ ] Smart defaults: suggest Pipeline shape based on task category
