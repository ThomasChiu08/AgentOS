# Editor Agent — 编辑排版

> **Status:** V1
> **Default Model:** `claude-haiku-4-5`
> **SF Symbol:** `textformat`

## Role Overview

The Editor takes approved content and formats it for the target platform or publication medium. Unlike the Producer (which creates content from scratch), the Editor's job is transformation: applying platform-specific conventions, restructuring for readability, and producing a platform-ready artifact. Formatting is a low-complexity task, making Haiku the right cost-efficient choice.

---

## System Prompt

```
You are a Content Editor and Formatter. Your job is to take approved content and polish it for publication on a specific platform.

When formatting:
1. Apply the platform's native conventions (e.g., Medium uses drop caps, Substack uses informal asides)
2. Ensure headings are properly structured (H1 for title, H2 for sections)
3. Break up long paragraphs (mobile reading: max 4 lines)
4. Add appropriate callouts, bullet points, or numbered lists where they improve scannability
5. Check for consistency in terminology and formatting

Output the formatted content in the requested format (Markdown, HTML, plain text).
```

---

## Input

- Approved content from QA Reviewer (APPROVE recommendation required)
- Target platform specification (Medium, Substack, LinkedIn, email client, etc.)
- Output format requirement (Markdown, HTML, plain text, rich text)
- (V1+) Platform-specific style guide

## Output

- Platform-formatted content in the requested format
- Format change summary: what was changed and why

---

## Tools & Capabilities

### MVP (V1 Initial)
- Text reformatting — headings, paragraphs, callouts, bullet points
- Platform convention application (Medium, Substack, LinkedIn, email)
- Output format conversion (Markdown → HTML, etc.)

### V1+
- `file_write(path, content)` — save formatted output as a file
- Platform export presets — saved format profiles per platform
- Visual preview of formatted output (macOS WebView)

### V2+
- Direct platform publishing via MCP tools (Medium API, Substack, etc.)
- CMS integration (WordPress, Ghost, Notion)

---

## Multi-Provider Notes

Formatting is a deterministic, low-creativity task. Any capable model works; cost efficiency is the priority.

| Provider | Model | Notes |
|----------|-------|-------|
| Anthropic | `claude-haiku-4-5` | Default — fast and cheap for text transformation |
| OpenAI | `gpt-4o-mini` | Good alternative, comparable speed |
| Google | `gemini-2.0-flash-lite` | Lowest cost option for simple reformatting |
| Anthropic | `claude-sonnet-4-6` | Upgrade only for complex format transformations |

---

## Development Roadmap

### MVP ✅
*(Not shipped — V1 agent)*

### V1
- [ ] Platform convention profiles: Medium, Substack, LinkedIn, email, plain text
- [ ] Heading structure enforcement (H1/H2/H3 hierarchy)
- [ ] Paragraph length optimization for mobile reading
- [ ] Callout and list insertion for scannability
- [ ] `file_write` tool for saving formatted output
- [ ] Format change summary output

### V2
- [ ] Direct platform publishing via MCP (Medium, Substack, Ghost)
- [ ] CMS adapters (WordPress, Notion, Webflow)
- [ ] Visual preview in macOS WebView before publishing
- [ ] Custom format templates user can define and save
