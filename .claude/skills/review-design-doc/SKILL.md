---
name: review-design-doc
description: >
  Reviews a design document by first summarizing its goals and the reasoning behind it, then
  identifying 3–5 specific, actionable Notion comments to leave — either asking for clarification
  or suggesting an improvement. Trigger when user says "review this doc", "review this design",
  "give me feedback on this design", "what comments should I leave", "what should I comment",
  "give feedback on this spec", "look at this design doc", or shares a Notion/Google Doc URL
  and asks for review.
argument-hint: "[doc-url-or-content]"
---

## Steps

### 1. Obtain the document

If the user provided a Notion URL, fetch it with the Notion MCP (`notion-fetch`).
If they pasted raw text, work from that directly.

### 2. Summarize goals and the "why"

Before any critique, write a short summary (3–6 sentences) in this format:

```
**Goals:** What this document is trying to accomplish.
**Why / Motivation:** The problem or opportunity driving this work, as stated in the doc.
**Approach:** The high-level solution the doc proposes.
```

Ground every sentence in what the doc actually says — do not infer intent not present in the text.

### 3. Identify comment candidates

Read the full document and flag passages that fall into one of two categories:

| Category | When to use |
|----------|------------|
| **Clarification** | The doc is ambiguous, contradictory, or missing information a reader needs to act on it |
| **Suggestion** | A concrete improvement — stronger framing, missing edge case, alternative approach worth considering |

Look especially at:
- Problem statement / motivation section — is the "why" clear and compelling?
- Success criteria / metrics — are they measurable and specific?
- Design decisions with no rationale — why was this approach chosen over alternatives?
- Scope boundaries — what's explicitly out of scope and why?
- Open questions section (if present) — any that should be answered before execution?

### 4. Write 3–5 specific Notion comments

For each comment, output:

```
**Comment [N]**
Section/line: <exact section heading or quoted phrase from the doc>
Type: Clarification | Suggestion
Comment text: <the comment as you'd write it in Notion — first person, direct, 1–3 sentences>
```

Rules for comments:
- Reference a **specific quoted phrase or section heading** so the user knows exactly where to paste it
- Each comment must be actionable — the author can respond or make a change based on it
- Clarification comments should end with a question
- Suggestion comments should briefly say what to add or change and why
- Do not repeat the same point across multiple comments
- Prefer comments on load-bearing decisions over stylistic observations

### 5. Output structure

```
## Summary

**Goals:** …
**Why / Motivation:** …
**Approach:** …

---

## Suggested Notion Comments

**Comment 1**
Section/line: "…"
Type: …
Comment text: …

**Comment 2**
…
```

No preamble, no trailing summary. Output the two sections and stop.
