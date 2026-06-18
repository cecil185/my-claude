---
name: grill-me
description: >
  Interviews the user relentlessly about a plan or design, walking each branch of the decision
  tree until reaching shared understanding. Trigger when user says "grill me", "stress-test my
  plan", "poke holes in this", "challenge my design", "ask me hard questions", or "I want to
  think through this".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

**Example:** User says "grill me on my plan to add a new vendor integration" → ask about webhook vs polling, auth strategy, error handling, schema evolution, backpressure, idempotency — one question at a time, with your recommended answer for each.
