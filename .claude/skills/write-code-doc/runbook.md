# Runbook — Examples

> **Word limit: minimum steps to complete the operation safely.** Every step must be verifiable.

---

## Structure

```
# <Action> — <System>

> Summary — when to run this, what it does, risk level. See [Rollback] if something goes wrong.

## Prerequisites
## Steps
## Validation
## Rollback
```

Validation and Rollback are mandatory if the operation touches production.

---

## Summary callout rules

- When to run it (trigger condition)
- What it does (one sentence)
- Risk level: low / medium / high
- Pointer to rollback section

### Example
```
> Run when a new vendor schema is added to the ingestion pipeline. Promotes bronze → silver → gold transformation layers in order. **Risk: medium** — a bad promotion blocks downstream DAGs. See [Rollback] to revert.
```

---

## Steps section rules

- Numbered list, imperative mood: "Run `just promote bronze`"
- Bold the trigger condition for conditional steps: **When**: ref/ directory has changes
- Explicit skip instructions: "Skip this step if no schema changes since last promotion"
- Checklists (`- [ ]`) for pre-checks, not prose

### Example
```
## Steps

- [ ] Confirm no active DAG runs in Airflow before starting

1. **When**: bronze layer has changes → Run `just promote bronze`
2. **When**: silver layer has changes → Run `just promote silver`
3. Skip gold if no downstream model changes since last run
```

---

## Validation section

One verifiable check per line. Tell the reader exactly what success looks like:

```
## Validation

- [ ] Calculated fields DAG completes successfully
- [ ] ams_event_generation DAG completes successfully
- [ ] All monitors and dashboards green in Datadog
```

---

## Never
- Prose paragraphs for steps (use numbered list)
- "You should..." or "It is recommended that..." — imperative only
- Skipping Rollback for production operations
