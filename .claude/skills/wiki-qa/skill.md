---
name: wiki:qa
description: >-
  Answer complex questions by researching the local wiki knowledge base.
  Reads the index, finds relevant articles, synthesizes a thorough answer,
  and optionally saves the output as a new wiki file. Use when asking
  research questions against an existing wiki.
model: claude-opus-4-6
effort: high
---

# Wiki Q&A

Answer questions by synthesizing knowledge already compiled in the wiki. This is the primary "query" interface for the knowledge base.

## Process

1. **Read the index**: Read `wiki/INDEX.md` and `wiki/SUMMARY.md` to understand what's available.

2. **Identify relevant articles**: From the index, select the 5–15 most relevant articles for the question. Read them all.

3. **Check raw/ for gaps**: If the question touches something not well-covered in the wiki, scan `raw/INDEX.md` for relevant source docs and read those too.

4. **Synthesize the answer**: Compose a thorough answer that:
   - Directly answers the question in the first paragraph
   - Cites specific wiki articles with `[[WikiLink]]` syntax
   - Surfaces relevant tradeoffs, contradictions, or open questions
   - Suggests 2–3 follow-up questions worth exploring

5. **Choose output format** based on question type:
   - Factual lookup → plain markdown answer in terminal
   - Comparative analysis → markdown table + prose
   - Architecture question → Mermaid diagram + explanation
   - Tutorial/how-to → step-by-step markdown
   - Broad synthesis → full article (save to `wiki/qa/<slug>.md`)

6. **File the output** (unless told not to): Save the answer to `wiki/qa/<slug>.md` with frontmatter:
   ```markdown
   ---
   title: <question as title>
   date: <YYYY-MM-DD>
   type: qa
   sources: [wiki articles referenced]
   ---
   ```
   Then append a line to `wiki/INDEX.md` under a `## Q&A` section.

## Rules

- Never fabricate facts not in the wiki — if the wiki doesn't cover it, say so and suggest running `wiki:ingest` to fill the gap.
- Prefer synthesis over quoting — rephrase, don't copy-paste from articles.
- If sources conflict, surface the disagreement explicitly.
- Always end with: "**Gaps**: [what the wiki is missing on this topic]"

## Output

The answer in the chosen format, plus a one-line note on whether it was saved and where.
