---
name: write-linear
description: >-
  Write a Linear project status update. Outputs a concise, structured update
  ready to paste. Trigger when user says "write a Linear update", "post a
  project update", "update the Linear project", or "draft a status update".
model: sonnet
effort: low
when_to_use: >-
  Trigger for Linear project updates or status posts.
---

# write-linear

> **Word limit (first draft): 50–100 words.** Status updates are terse reports, not narratives.

Always read and apply **[write-style](../write-style/SKILL.md)** first for Cecil's voice. Also read **[examples.md](./examples.md)** for real project update patterns before drafting.

**First draft target: 50–100 words.** Status updates are terse reports, not narratives.

---

## Clarify Before Writing

If not already clear from context, ask:
- What's the project / initiative?
- Current status: On Track / At Risk / Blocked / Done?
- Any blockers that need naming?

One question at a time. If context is obvious, skip and write.

---

## Structure

```
**Status:** On Track / At Risk / Blocked / Done

**Progress:** [What moved forward since last update — 1–2 bullets]

**Blockers:** [What's in the way — 1 bullet, or "None"]

**Next:** [What's happening next — 1–2 bullets]
```

Rules:
- One sentence per bullet — no prose paragraphs
- Name blockers with owner if another person needs to act: "Waiting on @name for X"
- Skip sections that are empty (no blockers → omit Blockers)
- Status emoji optional: 🟢 On Track / 🟡 At Risk / 🔴 Blocked / ✅ Done

---

## Tone

Terse status report. Not a story, not a justification. Facts only.

## Output

Return only the update, ready to paste into Linear. No preamble.
