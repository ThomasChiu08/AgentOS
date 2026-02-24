# Producer Agent — 交付生产

> **Status:** MVP ✅
> **Default Model:** `claude-sonnet-4-6`
> **SF Symbol:** `pencil.and.outline`

## Role Overview

The Producer creates the primary deliverable — an article, code snippet, report, script, email campaign, or any other content artifact. It receives context from earlier pipeline stages (typically a research brief from the Researcher) and produces polished output ready for QA review, targeting "publishable with minor edits" quality on the first pass.

---

## System Prompt

```
You are a Senior Producer on an AI team — a versatile creator capable of writing articles, generating code, drafting reports, and producing any other content deliverable.

When given a production task:
1. Read the provided context carefully (research briefs, requirements)
2. Produce the deliverable at the highest quality you can
3. Follow any format specifications exactly (word count, sections, tone)
4. End with a brief note on key decisions you made

Quality bar: Your output should be polished enough to use with minor edits — not a rough draft that needs rewriting.

If you're writing long-form content, use clear headers and short paragraphs. If you're writing code, include brief comments for non-obvious logic. If you're writing emails, ensure there's a clear CTA.
```

---

## Input

- Task description from CEO Pipeline (what to produce)
- Research brief from Researcher (if applicable)
- Format requirements: length, tone, target platform
- (V1+) User-provided style guide or reference document

## Output

- Primary deliverable (article, code, report, script, email, etc.)
- Brief producer note explaining key decisions made
- (V1+) Multiple draft variations for user to choose from

---

## Tools & Capabilities

### MVP
- Text generation — articles, reports, emails, scripts, code
- Context synthesis from upstream stage outputs
- Producer note summarizing decisions

### V1+
- `file_write(path, content)` — save output directly to disk as a file
- Multi-draft generation — produce 3 variations, present for user choice
- Reference document injection — user uploads a style guide or example
- Code execution — run generated code to verify it works before output

---

## Multi-Provider Notes

The Producer is the most versatile agent — output quality depends heavily on the task type.

| Provider | Model | Best For |
|----------|-------|---------|
| Anthropic | `claude-sonnet-4-6` | Long-form writing, nuanced tone, structured reports |
| Anthropic | `claude-opus-4-6` | Premium mode: high-stakes deliverables, complex code |
| OpenAI | `gpt-4o` | Code generation, technical writing |
| Google | `gemini-2.0-pro` | Creative writing, multimodal input (image → description) |
| OpenAI | `gpt-4o-mini` | Short-form content, cost-sensitive workflows |

For V1, consider allowing users to select "Premium Producer" (opus) for important deliverables.

---

## Development Roadmap

### MVP ✅
- [x] Long-form content generation (articles, reports, emails)
- [x] Code snippet generation
- [x] Context synthesis from research brief
- [x] Producer decision note appended to output
- [x] Format spec adherence (word count, sections, tone)

### V1
- [ ] `file_write` tool — save output as `.md`, `.txt`, `.swift`, etc.
- [ ] Multi-draft mode — generate 3 variations with trade-off notes
- [ ] Style guide injection — user uploads a reference document
- [ ] Code execution sandbox — run and verify code before returning output
- [ ] Premium Producer mode (opus) — user-selectable for high-stakes work
- [ ] Revision loop — if QA score < 7, automatically revise

### V2
- [ ] Multimodal input — accept images/diagrams as context
- [ ] Template library — plug-in format templates per content type
- [ ] Brand voice persistence — learn user's style over time via RAG memory
