---
name: write-shorter
description: >-
  Trims existing content — cuts repetition, removes filler, reduces to minimum
  viable length without losing meaning. Works on any existing draft: Slack
  message, Linear update, Notion doc, MR description, or other written content.
  Trigger when user says "make this shorter", "trim this", "too long", "cut this
  down", or "fewer words".
model: sonnet
effort: low
---

# write-shorter

Find the shortest version that preserves all meaning. Cut until removing anything else would lose something real.

## What to cut — in order of priority

1. **Repetition** — same idea stated twice in different words. Keep the sharper version, delete the other.
2. **Filler openers** — "As mentioned above", "Just wanted to", "I wanted to reach out", "In order to". Delete entirely.
3. **Hedges that add nothing** — "sort of", "kind of", "basically", "essentially", "generally speaking". Delete.
4. **Throat-clearing** — "This document covers...", "The purpose of this message is...", "I'm writing to...". Delete.
5. **Over-explanation** — context the reader already has or can infer. Cut.
6. **Weak endings** — "Let me know if you have any questions", "Thanks!", "Feel free to reach out". Delete unless explicitly requested.
7. **Padded bullets** — bullet points that could be one clause in a sentence. Collapse them.

## What NOT to cut

- Specifics: numbers, names, dates, ticket IDs — these earn their place
- The why behind a request or decision — one sentence of context is load-bearing
- Qualifiers that change meaning: "only", "not yet", "blocked" — these aren't hedges

## Output

Return the trimmed version only — no preamble, no "Here's a shorter version:", no explanation of what was cut.

If the content is already at minimum viable length, say so in one sentence rather than returning an unchanged version.

After trimming, show the word count reduction: `(N → M words)` on the line after the output.
