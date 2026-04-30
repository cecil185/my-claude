---
name: datadog-error-triage
description: >-
  Triage `status:error` logs in Datadog over a time window — separate
  misclassified noise (INFO/warn on stderr, multiline traceback fragments,
  blank-line tokens) from real errors, and produce a short report with
  pipeline-fix recommendations. Use when asked to look at error logs, sort
  through Datadog noise, find real errors, or audit log status accuracy.
model: sonnet
effort: medium
---

# Datadog Error Triage

Goal: turn a wall of `status:error` logs into a short report — what is noise,
what is real, what to fix in the Datadog log pipeline so the noise stops.

## When to use

- "Search Datadog for status:error in [account/env] for the past N hours"
- "There's a lot of error noise in Datadog, help me sort through it"
- "Are we seeing any real errors right now?"
- After an incident, before declaring the alert noisy/genuine

## Inputs to confirm

Before running, make sure you have:
- **Scope filter** (one of): `aws_account:<id>`, `service:<name>`, or some other narrowing tag. Account-wide is fine, but a fully unfiltered query is not.
Default filters if not specified should be: status:error aws_account:322609035462 -service:intelligence-data-api 
- **Time window** (default `now-4h`)

If the user gave a specific filter, use it verbatim. Don't add or drop tags.

## Step 1 — Volume by service

Run this first. It tells you where to focus.

```
analyze_datadog_logs:
  filter: status:error <user-scope>
  from: now-Nh
  sql_query: SELECT service, count(*) as cnt FROM logs GROUP BY service ORDER BY cnt DESC LIMIT 50
```

Anything emitting more than a few hundred errors/hour is almost always
misclassified — real error rates that high would be a full outage.

## Step 2 — Cluster patterns per service

```
search_datadog_logs:
  query: status:error <user-scope>
  from: now-Nh
  use_log_patterns: true
  pattern_group_by: ["service"]
```

For each pattern, ask: does the message text actually look like an error?
Common tells of MISCLASSIFICATION:

| Tell | Meaning |
|---|---|
| Message starts with `INFO`, `DEBUG`, `WARN`, `W0429`, or has `level=info` | Stderr stream tagged as error by default DD parser |
| Message is empty or just whitespace | Blank stderr line tagged as error |
| Message is a fragment: `~~~~^^^^`, `File "...", line N`, single token like `^`, `)`, `main()` | Multiline traceback split on newline; only the first line is a real error |
| Dd-trace `failed to send, dropping N traces` | Datadog agent connectivity, not app error |
| `cannot scrape target ... node-exporter` (vmagent) | Scrape warn, not app error |
| `kube-system` / CSI / operator reconciliation INFO logs | Controller informational, not error |

Real errors usually look like: a stack trace's *first* line, an HTTP error
("404 Client Error", "5xx"), an app-level error message, an auth failure, a
DB OperationalError.

## Step 3 — Drill into suspected real errors

For each service with non-noise patterns, fetch raw logs:

```
search_datadog_logs:
  query: status:error <user-scope> service:<name>
  from: now-Nh
  max_tokens: 2500
```

Read carefully. Distinguish:
- **Expected business errors** (vendor 404 for missing resource) — usually
  routine, but worth flagging if rate spikes
- **Real failures** (DB connection drops, OperationalError, auth token
  invalid) — needs a follow-up ticket
- **Infrastructure noise** (DD agent can't reach trace intake) — platform
  team

## Step 4 — Report

Output a short report with three sections:

### A. Misclassified (noise to fix)
Table: service | count | pattern | proposed pipeline fix

Pipeline fix is almost always one of:
- **Datadog Logs Pipeline → Status Remapper** to read `level` / `severity`
  out of the parsed JSON (or via grok extracting `INFO|WARN|ERROR` from the
  message text) instead of defaulting to stderr=error.
- **Multi-line aggregator** processor in the pipeline so Python tracebacks
  ship as a single log entry rather than per-line fragments.
- **Exclusion filter** for known-noisy patterns (e.g. dd-trace flush
  failures) at the pipeline level — but prefer fixing the status, not
  dropping data.

Note: this skill cannot modify DD pipelines via MCP. Surface the recommended
fix; the user applies it in the Datadog UI under Logs → Pipelines.

### B. Real errors found
Bullet list, one line each: `service — what happened — count — link`.
Include the Datadog Logs Explorer URL from the search response so the user
can click through.

### C. Recommended follow-ups
Tickets to file, owners to ping. Keep it under 5 items.

## Notes

- Don't try to enumerate every error — cluster, summarize, and link.
- Prefer `analyze_datadog_logs` for counts and `use_log_patterns: true` for
  message clustering. Raw `search_datadog_logs` is for drilling into one
  service after you know it's real.
- Time window: default 4h. Shorter (1h) if user is reacting to an alert,
  longer (24h) if doing a hygiene audit.
- If a single pattern is over ~5k logs in 4h, treat it as misclassified
  until proven otherwise.
