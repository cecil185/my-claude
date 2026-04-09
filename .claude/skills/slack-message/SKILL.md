---
name: slack-message
description: >-
  Revise or draft Slack messages. Use when asked to write, improve, polish,
  or send a Slack message — e.g. "draft a slack message about X", "clean up
  this message", "how should I word this in Slack?". Outputs a ready-to-send
  message, not commentary about one.
model: sonnet
effort: low
---

# Slack Message
If no message is provide, then summarize the decision or question in discussed in previous few chat messages.

Revise or draft the message directly. Return a polished, ready-to-send Slack
message — not a commentary on it.

## Principles

- **Concise over comprehensive** — cut anything the reader doesn't need. If a
  sentence can be removed without losing meaning, remove it.
- **Signal competence quietly** — precise word choice and clean structure do
  more than technical jargon. Never use complexity to sound smart.
- **Infer and complete** — if the draft is missing context (recipient, outcome,
  ask), infer the most natural interpretation and fill it in. Don't ask
  follow-up questions unless the message is genuinely ambiguous in a way that
  changes its meaning.
- **Match the register** — a quick status update in a team channel reads
  differently than an escalation to leadership. Adapt tone accordingly.
- **One clear ask** — every message should have one thing it wants the reader
  to do or know. Identify it and make sure it lands.

## Format Guidelines

- Use plain prose for short messages (1–3 sentences). No bullets needed.
- Use bullets or numbering only when it improves flow of message
- Bold sparingly — only for the single most important phrase if the message
  is long enough to need a visual anchor.
- No greetings ("Hey team,") unless the original included one and the context
  warrants it.
- No sign-offs ("Thanks!", "Let me know!") unless explicitly requested.
- Threads and channel posts can differ in length — a thread reply can be
  tighter than a channel announcement.

## Output

Return only the revised message, ready to copy-paste. No preamble, no
"Here's a revised version:", no explanation unless the user asks for one.

If there are meaningfully different ways to frame the message (e.g., direct
ask vs. soft update), offer two short variants labeled **Option A** and
**Option B** — but only when the choice materially affects how it lands, not
as a default.
