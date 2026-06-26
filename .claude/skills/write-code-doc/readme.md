# README — Examples

> **Word limit: ≤ 400 words.** Summary callout is mandatory. Get the reader running in under 5 minutes.

---

## Structure

```
# Project Name

> One sentence: what this does and who it's for.

## Local Setup
## Architecture  (one paragraph or ASCII diagram)
## Development Workflow
## Deployment
## Contact / On-call
```

Drop sections that don't apply. Never add others without good reason.

---

## Summary callout rules

- One sentence: what it does + who uses it
- Link to the section they most likely need: "See [Local Setup] to run it."
- Not "This README covers..." — start with the thing itself

### Example
```
> Ingestion pipeline for AMS vendor data — polls external APIs, processes events via SQS, and writes to the Onehouse lakehouse. See [Local Setup] to run locally or [Deployment] to promote to prod.
```

---

## Architecture section

Prefer ASCII over prose for system flows:

```
Webhooks/Pollers --> SQS --> Processors --> Kafka --> Onehouse
```

One paragraph max if ASCII doesn't fit. Link to the full design doc rather than inlining it.

---

## Development Workflow section

Imperative mood for every step:

```
Run `just test` before pushing.
Use `just lint` to catch formatting issues.
```

Not: "You should run `just test` before pushing."

---

## Never
- "This document covers..." opener
- Background the reader already has (what a poller is, what SQS is)
- Trailing "Questions? Reach out!" filler — put an actual name or channel
