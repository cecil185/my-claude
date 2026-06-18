---
name: datadog-error-triage
description: >-
  Triages `status:error` logs in Datadog over a time window — separates
  misclassified noise (INFO/warn on stderr, multiline traceback fragments,
  blank-line tokens) from real errors, and produces a short report with
  pipeline-fix recommendations. Trigger when user says "look at error logs",
  "triage Datadog errors", "sort through the noise", "find real errors in Datadog",
  "audit log status accuracy", "what errors are real", "check status:error logs",
  or "clean up Datadog noise".
model: sonnet
effort: medium
---

# Datadog Error Triage

Turn a wall of `status:error` logs into a short report: what is noise, what is real, what to fix.

## Inputs

Args are always inline — don't ask, just run. Parse:
- **DD filter string** — use verbatim. Default: `status:error aws_account:322609035462 -service:intelligence-data-api`
- **Time window** — default `now-4h`
- **Natural-language question** — answer it at the end of the report after the structured analysis

## Step 1 — Volume by service

```
analyze_datadog_logs:
  filter: status:error <user-scope>
  from: now-Nh
  sql_query: SELECT service, count(*) as cnt FROM logs GROUP BY service ORDER BY cnt DESC LIMIT 50
```

Hundreds of errors/hour from a single service is almost always misclassification — real rates that high would be a full outage.

## Step 2 — Cluster patterns per service

```
search_datadog_logs:
  query: status:error <user-scope>
  from: now-Nh
  use_log_patterns: true
  pattern_group_by: ["service"]
```

Common misclassification tells:

| Tell | Meaning |
|---|---|
| Starts with `INFO`, `DEBUG`, `WARN`, `W0429`, or has `level=info` | Stderr tagged error by default DD parser |
| Empty or whitespace | Blank stderr line |
| Fragment: `~~~~^^^^`, `File "...", line N`, single token `^` `)` | Multiline traceback split per line |
| `failed to send, dropping N traces` | DD agent connectivity |
| `cannot scrape target ... node-exporter` | vmagent scrape warn |
| `kube-system` / CSI / operator reconciliation INFO | Controller informational |

Real errors: stack trace first line, HTTP 4xx/5xx, auth failure, DB OperationalError.

## Step 3 — Drill into suspected real errors

```
search_datadog_logs:
  query: status:error <user-scope> service:<name>
  from: now-Nh
  max_tokens: 2500
```

Classify each:
- **Expected business errors** (vendor 404 for missing resource) — routine, flag if rate spikes
- **Real failures** (connection drops, auth token invalid) — needs a ticket
- **Infrastructure noise** (DD agent trace intake) — platform team

## Step 4 — Report

### A. Misclassified (noise to fix)
Table: service | count | pattern | proposed fix

Pipeline fix is almost always one of:
- **Status Remapper** — read `level`/`severity` from parsed JSON instead of defaulting stderr → error
- **Multi-line aggregator** — so Python tracebacks ship as one entry
- **Exclusion filter** — for known-noisy patterns; prefer fixing the status over dropping data

### B. Real errors found
One line each: `service — what happened — count — link`

### C. Recommended follow-ups
Tickets to file, owners to ping. Max 5 items.

## Notes

- Cluster and summarize — don't enumerate every log.
- Use `analyze_datadog_logs` for counts, `use_log_patterns: true` for clustering. Raw `search_datadog_logs` only once you've confirmed a service is worth drilling into.
- If a pattern exceeds ~5k logs in 4h, treat as misclassified until proven otherwise.
