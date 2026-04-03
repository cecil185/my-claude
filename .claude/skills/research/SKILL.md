---
name: research
description: >-
  Web research skill — answers questions with sourced, concise summaries.
  Use when asked to look something up, research a topic, compare options,
  or find current information. Returns a short answer with linked sources;
  user can ask follow-up for more depth.
model: claude-opus-4-6
---

# Research

Use the WebSearch and WebFetch tools to gather current information on the topic.

## Process

1. Search for the topic using WebSearch (5 targeted queries max).
2. Fetch the most relevant pages with WebFetch where needed to get specifics.
3. Synthesize findings into a short answer with sources linked inline.

## Output format

- **One short paragraph** (1–4 sentences) answering the question directly.
- Inline markdown links for each source: `[Source Name](url)`.
- End with a single blank line — no "let me know if you want more" filler.
- If findings conflict across sources, note it in one sentence.
- Do not add headers, bullet breakdowns, or commentary — just the answer and sources.

## Tone

Direct and factual. No preamble ("Great question!"), no trailing offers ("I can dig deeper if…"). The user will ask for more detail where they want it.
