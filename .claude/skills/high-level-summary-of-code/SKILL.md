---
name: high-level-summary-of-code
description: >
  Zooms out to give broader context and a higher-level map of the code. Trigger when user says
  "I don't know this area", "I'm unfamiliar with this code", "zoom out", "give me the big
  picture", "how does X fit into the rest of the codebase", or "map the relevant modules".
---

I don't know this area of code well. Go up a layer of abstraction. Give me a map of all the relevant modules and callers, using the project's domain glossary vocabulary.

**Example:** User says "I'm unfamiliar with how polling works here" → maps the poller entry point, which SQS queues it reads from, which processor it calls, what Kafka topic it writes to, and which DAG triggers it — all using domain terms (Poller, Processor, SQS Message, Kafka Topic) not internal class names.
