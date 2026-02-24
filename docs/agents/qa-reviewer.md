# QA Reviewer Agent — 质量审查

> **Status:** MVP ✅
> **Default Model:** `claude-sonnet-4-6`
> **SF Symbol:** `checkmark.shield.fill`

## Role Overview

The QA Reviewer evaluates the Producer's output against the original task requirements and provides specific, actionable improvement feedback. Its role is critique and guidance — not rewriting. The QA Reviewer gives a numeric quality score and an APPROVE / REVISE / REJECT recommendation, enabling the pipeline to loop back to the Producer automatically (V1) or surface the review to the user for a decision.

---

## System Prompt

```
You are a Quality Assurance Reviewer on an AI team. Your job is to critically evaluate outputs and provide specific, actionable feedback.

When reviewing:
1. First, restate what the original task required (1 sentence)
2. List what the output does well (be specific, not generic)
3. List specific issues that need fixing (with examples from the text)
4. Provide a Quality Score: 1–10
5. Give a recommendation: APPROVE / REVISE / REJECT

Be direct and specific. "The introduction is weak" is not helpful. "The introduction opens with a cliche — rewrite to open with the key insight on line 3" is helpful.

Do not rewrite the content yourself — only critique and guide. The Producer will handle revisions.

Output format:
## QA Review
**Task Requirement:** [one sentence]
**Strengths:**
- [specific strength 1]
**Issues:**
- [specific issue 1, with example]
**Quality Score:** X/10
**Recommendation:** APPROVE / REVISE / REJECT
**Revision Notes:** (if REVISE or REJECT) [specific instructions for next iteration]
```

---

## Input

- Original task description (from CEO Pipeline)
- Producer's output (the artifact to review)
- (V1+) User-defined review criteria or rubric

## Output

- Structured QA Review report in Markdown (see format above)
- Quality Score: 1–10
- Recommendation: `APPROVE` / `REVISE` / `REJECT`
- Revision Notes: specific instructions if not APPROVE

---

## Tools & Capabilities

### MVP
- Text review — evaluates any text-based output
- Structured report format (Strengths / Issues / Score / Recommendation)
- Revision Notes for non-APPROVE outcomes

### V1+
- Review rubric templates: SEO review, code review, legal review, brand voice review
- Auto-revision loop: if score < 7, automatically send back to Producer with revision notes
- Human-in-the-loop: user can add custom review criteria before QA runs
- Model escalation: sonnet for standard review → opus for critical/high-stakes content

---

## Multi-Provider Notes

The QA Reviewer needs strong critical reasoning and the ability to give specific, grounded feedback.

| Provider | Model | Notes |
|----------|-------|-------|
| Anthropic | `claude-sonnet-4-6` | Excellent critical analysis, nuanced feedback |
| Anthropic | `claude-opus-4-6` | For critical reviews on high-stakes deliverables |
| OpenAI | `gpt-4o` | Strong reviewer, slightly more lenient scoring |
| Google | `gemini-2.0-pro` | Good alternative for content quality reviews |

Avoid Haiku for QA — quality of critique degrades significantly for low-tier models.

---

## Development Roadmap

### MVP ✅
- [x] Structured review against original task requirements
- [x] Strengths and Issues lists with specific examples
- [x] Quality Score (1–10)
- [x] APPROVE / REVISE / REJECT recommendation
- [x] Revision Notes for non-APPROVE outcomes

### V1
- [ ] Review rubric templates (SEO, code quality, brand voice, legal)
- [ ] Auto-revision loop: score < 7 → automatically re-queue to Producer
- [ ] Human-in-the-loop: user adds custom criteria before QA runs
- [ ] Review history: track score progression across revisions
- [ ] Model escalation: user-configurable threshold for opus upgrade

### V2
- [ ] Cross-agent review: QA can review Researcher's brief, not just Producer's output
- [ ] Comparative review: evaluate multiple Producer drafts side by side
- [ ] Learning rubrics: QA adapts review criteria based on user feedback history
