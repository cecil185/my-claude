---
name: write-learn
description: >-
  Capture real writing examples from Cecil to refine the skill for that context.
  Walks through one context at a time, extracts patterns, and updates the
  relevant write-*/examples.md.
---

# write-learn

This skill captures real examples of Cecil's writing and extracts patterns to update the `examples.md` in the relevant write-* skill folder.

| Context | File to update |
|---|---|
| Slack channel post / DM | `../write-slack/examples.md` |
| Linear project update | `../write-linear/examples.md` |
| Notion doc | `../write-notion-doc/examples.md` |
| Code doc — MR title | `../write-code-doc/mr-title.md` |
| Code doc — MR body | `../write-code-doc/mr-body.md` |
| Code doc — Inline comment | `../write-code-doc/inline-comment.md` |
| Code doc — README | `../write-code-doc/readme.md` |
| Code doc — Runbook | `../write-code-doc/runbook.md` |
| Code doc — API doc | `../write-code-doc/api-doc.md` |

---

## Process

### 1. Pick a context
If not specified, ask which context to calibrate:
- Slack channel post
- Slack DM / Group DM
- Linear project update
- Notion doc
- Code doc / README

### 2. Collect examples
Ask for 2–3 real examples Cecil has written in that context. Paste directly — no need to clean them up.

Ask after each: "Anything specific about this one you want to preserve or avoid in future drafts?"

### 3. Extract patterns
From the examples, identify:
- Sentence length and structure
- Vocabulary choices (what words appear / what's conspicuously absent)
- How much context is given vs. assumed
- Formatting habits (bullets vs. prose, headers, etc.)
- Tone markers (dry, direct, warm, terse)
- What's notable about the opening and closing

### 4. Propose updates
Summarize the patterns as additions or corrections to the relevant `examples.md`. Show the proposed changes before writing.

Ask: "Does this look right? Anything to adjust?"

### 5. Update the file
On confirmation, edit the relevant `examples.md` (see table above) — add the new example with a short "What to note:" annotation, remove or correct any example it contradicts, and update the Pattern Summary at the bottom if the new example shifts a pattern.

---

## Notes

- Don't overfit to one example — look for patterns across 2–3
- If an example contradicts the current guide, flag it: "This feels more X than your guide suggests — want to update the guide or treat this as a one-off?"
- Keep new examples concise in examples.md — include the raw text, then a short "What to note:" line. Full pastes belong in the example block, not repeated in prose.
