---
name: datadog-error-investigate
description: >-
  Investigates a specific Datadog alert or error from the ingestion stack
  (catapult, dynamo, forcedeck, performance, smartspeed, SQS pollers,
  processors). Resolves the alert from Slack or a direct description, queries
  Datadog logs for the full picture, uses AWS MCP to verify root cause against
  live infrastructure (SQS, EKS, CloudWatch), and produces a triage report
  ending with a severity classification and proposed next steps.
  Trigger when the user says "investigate this alert", "what happened with this
  error", "triage this failure", "look into this Datadog alert", "why did X fail",
  or pastes a Slack permalink from #alerts-data-platform-datadog. Also triggers with
  no input — runs against the latest alert in the channel.
model: sonnet
effort: medium
---

# Datadog Error Investigate

Given an alert description, Slack permalink, or nothing at all, produce a full
triage report for an error in the ingestion stack with a severity classification
and next steps.

All query templates, the noise catalog, the AWS check matrix, and the report
format live in [reference.md](reference.md).

## Required inputs (any one is enough)

Accept whichever of these the user provides — try them in order:

1. **Slack permalink** to `#alerts-data-platform-datadog` — resolve the alert
   details via the Slack flow in reference.md.
2. **Error description or service name** — e.g. "catapult processor is failing",
   "SQS poller throwing connection errors". Go straight to Datadog.
3. **No input** — read the most recent alert from `#alerts-data-platform-datadog`
   and run the full flow on it.

## Step 1 — Resolve the alert (when user has no description)

Read the latest alert from Slack and derive a time window from its `Message_ts`,
per [Slack lookup](reference.md#slack-lookup).

**Skip the Slack lookup** only when the user has already provided an explicit
absolute time window. Default fallback (if Slack returns nothing): `now-4h`.

Then run the anchor query from
[Datadog query templates](reference.md#datadog-query-templates) — the top hit's
service and error message anchors the rest of the investigation. Confirm with the
user before proceeding if the resolution is ambiguous:
_"Found alert for service `catapult-processor` — running investigation…"_

## Step 2 — Load Datadog skills

```
mcp__claude_ai_DataDog__load_datadog_skill(skill_name="datadog/logs")
```

Also load `datadog/metrics` if the investigation involves throughput or lag.

## Step 3 — Full log investigation

Run all three queries from
[Datadog query templates](reference.md#datadog-query-templates), in order:

1. **Volume baseline** — establish per-service error counts for the window
2. **Pattern clustering** — collapse the errors into distinct patterns
3. **Drill into real errors** — pull full fields on the ones that survive triage

Classify each pattern against the [noise tells](reference.md#noise-tells) table
before treating it as a real error.

## Step 4 — Verify root cause with AWS MCP

Ground-truth the investigation against live infrastructure using the
[AWS verification matrix](reference.md#aws-verification-matrix). Run only the
checks relevant to the suspected root cause.

## Step 5 — Report

Build a Datadog Logs Explorer
[deep-link](reference.md#datadog-deep-link) from the query and time window, then
fill in the [report template](reference.md#report-template). Lead with the Slack
permalink if the Slack lookup succeeded.

## Step 6 — Classification and next steps

Pick exactly one label:

| Label | Meaning |
|---|---|
| Ignore | Confirmed noise / misclassification. No app impact. |
| Wait and see | Transient blip with no current recurrence. Monitor for 24h. |
| Fix next work day | Real error but non-critical path or low rate. Ticket and schedule. |
| Fix immediately | Active failure, data loss risk, SLA breach, or customer impact. |

Every report ends with the classification line and a `## Proposed next steps`
section. Keep next steps to 3 items max. Be specific — name the fix, the ticket
queue, the person, or the Datadog pipeline change. Don't write "investigate
further" as a step; do the investigation before reaching this section.

## Failure modes / gotchas

- **No Slack hits**: fall back to user's time window or `now-4h`; don't block on Slack.
- **Hundreds of errors/hour from one service**: almost always misclassification — confirm with volume analysis before calling it a real outage.
- **SQS / EKS MCP auth**: pass `--profile datalake-stg` (staging) or `datalake-prod` (prod) explicitly; never change the user's active AWS config.
- **Large log responses spilling to file**: read the file with `Read` or `mcp__fff__grep` — do not re-query smaller.
- **Multiple concurrent alerts**: triage the highest-volume / most critical-path service first; note the others at the end of the report.
- **Attribute prefix confusion**: in DD query language use `@field`, not `@custom.field` — the latter returns zero even if the raw JSON shows `custom.field`.
