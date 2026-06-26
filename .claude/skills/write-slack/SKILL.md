---
name: write-slack
description: >-
  Draft or revise Slack messages — channel posts or DMs. Outputs a
  ready-to-send message. Trigger when user says "draft a slack message",
  "write a slack post about X", "clean up this message", "DM so-and-so about X",
  or "send a slack message".
model: sonnet
effort: low
when_to_use: >-
  Trigger for any Slack message — channel post or DM.
---

# write-slack

> **Word limits (first draft)**
> - Channel post: **30–80 words**
> - DM / DM: **20–50 words**

Always read and apply **[write-style](../write-style/SKILL.md)** first for Cecil's voice. Also read **[examples.md](./examples.md)** for real Slack message patterns before drafting. The rules below are Slack-specific additions.

If no message is provided, summarize the decision or topic from the recent conversation.

---

## Channel Post vs. DM

**Channel post** (30–80 words):
- May need slightly more context since the audience is broader
- Can use minimal formatting if the message is multi-part
- Invite feedback at the end if sharing a decision

**DM / DM** (20–60 words):
- Even more informal — fragments are fine
- No formatting needed
- Get to the ask in the first sentence

---

## Principles

- **Shortest possible** — aggressively cut bullets, headers, and context the reader doesn't strictly need
- **Match the register** — quick status update reads differently than an escalation to leadership
- **Signal competence quietly** — precise word choice beats jargon

## Format Guidelines

- Plain prose for short messages (1–3 sentences). No bullets needed.
- Use bullets or numbering only when it genuinely improves flow
- Bold sparingly — only for the single most important phrase in a long message
- No greetings ("Hey team,") unless context warrants it
- No sign-offs ("Thanks!", "Let me know!") unless explicitly requested

## Output

Return only the message, ready to copy-paste. No preamble, no "Here's a revised version:".
