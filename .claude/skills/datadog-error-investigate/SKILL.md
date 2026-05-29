---
name: datadog-error-investigate
description: >-
  Investigates a specific Datadog alert or error from the ingestion stack
  (catapult, dynamo, forcedeck, performance, smartspeed, SQS pollers,
  processors). Resolves the alert from Slack or a direct description, queries
  Datadog logs for the full picture, uses AWS MCP to verify root cause against
  live infrastructure (SQS, EKS, CloudWatch), and produces a triage report
  ending with a severity classification and proposed next steps.
when_to_use: >-
  Trigger when the user says "investigate this alert", "what happened with this
  error", "triage this failure", "look into this Datadog alert", "why did X
  fail", or pastes a Slack permalink from #alerts-data-platform-datadog. Also
  triggers with no input — runs against the latest alert in the channel.
model: sonnet
effort: medium
---

# Datadog Error Investigate

Given an alert description, Slack permalink, or nothing at all, produce a full
triage report for an error in the ingestion stack with a severity classification
and next steps.

## Required inputs (any one is enough)

Accept whichever of these the user provides — try them in order:

1. **Slack permalink** to `#alerts-data-platform-datadog` — e.g.
   `https://teamworkschat.slack.com/archives/<CHANNEL_ID>/p<ts>`. Resolve the
   alert details via the Slack flow below.
2. **Error description or service name** — e.g. "catapult processor is failing",
   "SQS poller throwing connection errors". Go straight to Datadog.
3. **No input** — read the most recent alert from `#alerts-data-platform-datadog`
   and run the full flow on it.

## Step 1 — Resolve the alert (when user has no description)

### Find the Slack channel ID

The channel ID for `#alerts-data-platform-datadog` is `C0APZDC6Y20`. Use
this directly — no lookup needed.

### Read the latest alert (no-input trigger)

```
mcp__claude_ai_Slack__slack_read_channel(
  channel_id = "C0APZDC6Y20",
  limit = 1,
  response_format = "concise"
)
```

The Datadog bot user is `Datadog`. If the most recent post is a human message,
skip back until you hit a bot post. The bot's `Text` field is often empty —
alert body lives in Slack `blocks`/`attachments` which MCP doesn't expose. Use
it only to get the `Message_ts` and derive a time window; pull the actual
error details from Datadog.

### Slack permalink → time window

From permalink `…/p1778595937961909` → strip `p`, insert `.` before last 6
digits → `1778595937.961909`. Use that as the anchor:

- `from` = `message_ts − 4 hours` (errors can incubate before the alert fires)
- `to`   = `message_ts + 30 minutes`

**Skip the Slack lookup** only when the user has already provided an explicit
absolute time window. Default fallback (if Slack returns nothing): `now-4h`.

### Extract alert context from Datadog

Once you have the time window, query for the originating error:

```
mcp__claude_ai_DataDog__search_datadog_logs(
  query   = "aws_account:322609035462 status:error",
  from    = <message_ts - 10 min>,
  to      = <message_ts + 2 min>,
  sort    = "-timestamp",
  extra_fields = ["service", "message", "status", "host"],
  max_tokens   = 4000
)
```

The top hit's service and error message anchors the rest of the investigation.
Confirm with the user before proceeding if the resolution is ambiguous:
_"Found alert for service `catapult-processor` — running investigation…"_

## Step 2 — Load Datadog skills

Load the relevant domain skill before querying:

```
mcp__claude_ai_DataDog__load_datadog_skill(skill_name="datadog/logs")
```

Also load `datadog/metrics` if the investigation involves throughput or lag.

## Step 3 — Full log investigation

### Volume baseline

```
mcp__claude_ai_DataDog__analyze_datadog_logs(
  filter    = "aws_account:322609035462 status:error service:<name>",
  from      = <window_from>,
  to        = <window_to>,
  sql_query = "SELECT service, count(*) as cnt FROM logs GROUP BY service ORDER BY cnt DESC LIMIT 20"
)
```

Hundreds of errors/hour from one service is almost always misclassification.

### Pattern clustering

```
mcp__claude_ai_DataDog__search_datadog_logs(
  query            = "aws_account:322609035462 status:error service:<name>",
  from             = <window_from>,
  to               = <window_to>,
  use_log_patterns = true
)
```

### Drill into real errors

```
mcp__claude_ai_DataDog__search_datadog_logs(
  query        = "aws_account:322609035462 status:error service:<name>",
  from         = <window_from>,
  to           = <window_to>,
  sort         = "timestamp",
  extra_fields = ["*"],
  max_tokens   = 15000
)
```

If the response spills to a file, read it with `Read` or `mcp__fff__grep` —
do not retry smaller.

**Attribute quirk**: in Datadog query language write `@field_name`, not
`@custom.field_name`, even if the raw JSON shows it nested under `custom`.

### Noise tells to filter out

| Pattern | Meaning |
|---|---|
| Starts with `INFO`, `DEBUG`, `WARN`, `W0` | Stderr tagged error by default DD parser — misclassification |
| Empty / whitespace | Blank stderr line |
| `~~~~^^^^` / single token `^` `)` | Multiline traceback fragment |
| `failed to send, dropping N traces` | DD agent connectivity — not an app error |
| `cannot scrape target` | vmagent scrape warn |
| `kube-system` / CSI / operator reconciliation INFO | Controller informational |

Real errors: first line of a Python/Java stack trace, HTTP 4xx/5xx from a
vendor, DB connection failure, SQS send failure, auth token invalid.

## Step 4 — Verify root cause with AWS MCP

Ground-truth the investigation against live infrastructure. Only run the checks
relevant to the suspected root cause. Always pass `profile = "datalake-stg"` or
`"datalake-prod"` explicitly — never change the user's active AWS config.

| Symptom | Check | Key signal |
|---|---|---|
| Poller / processor errors | `sqs get_queue_attributes` — `ApproximateNumberOfMessages`, `NotVisible`, `NumberOfMessagesDeleted` | High queue depth + low deletes = stalled consumer; high NotVisible = repeated failures |
| App crash / OOMKill | `mcp__aws-eks__list_k8s_resources` for pods, then `get_pod_logs tail_lines=100` | Pod in `CrashLoopBackOff`, `OOMKilled`, or `Error` |
| Throughput / timeout | `cloudwatch get_metric_statistics` — `AWS/SQS ApproximateAgeOfOldestMessage` | Rising age = consumer lag |
| Kafka publish errors | `kafka list_clusters` then describe the cluster | Broker health / under-replicated partitions |

Clusters: `datalake-stg` (staging), `datalake-latest` (prod).

## Step 5 — Generate Datadog deep-link

Always include a direct Datadog Logs Explorer link so the user can jump
straight to the evidence. Build the URL from the query and time window:

```
https://app.datadoghq.com/logs?query=<URL-encoded-query>&from_ts=<epoch_ms>&to_ts=<epoch_ms>&live=false
```

Encode the query string with:

```bash
python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "<query>"
```

Include this link under `## Evidence` in the report.

## Step 6 — Report

Lead with the Slack permalink if Slack lookup succeeded.

```
## Source alert
Slack: <permalink>  (<UTC timestamp>)

## What happened
<2-3 sentences: service, error type, time range, approximate count>

## Evidence
Datadog: <deep-link to logs>
AWS verification: <what the MCP checks confirmed or ruled out>

## Root cause assessment
<The most likely explanation, stated directly. If uncertain, say so and list
the top two hypotheses with the evidence for each.>

## Noise vs. real breakdown
| Service | Count | Classification | Reason |
|---|---|---|---|
| catapult-processor | 412 | Noise | INFO lines tagged error by DD parser |
| dynamo-poller | 7 | Real | DB connection timeout at 14:23 UTC |
```

## Step 7 — Classification and next steps
## Step 7 — Classification and next steps

Pick exactly one label:

| Label | Meaning |
|---|---|
| Ignore | Confirmed noise / misclassification. No app impact. |
| Wait and see | Transient blip with no current recurrence. Monitor for 24h. |
| Fix next work day | Real error but non-critical path or low rate. Ticket and schedule. |
| Fix immediately | Active failure, data loss risk, SLA breach, or customer impact. |

Then end every report with this section:

```
**Classification: <LABEL>**

## Proposed next steps

1. <Specific action — owner if known, e.g. "Open Linear ticket for Status Remapper on catapult-processor (DP team)">
2. <Second action if warranted>
3. <Optional: monitoring step — "Watch SQS ApproximateAgeOfOldestMessage for the next 2h">
```

Keep the next steps to 3 items max. Be specific — name the fix, the ticket
queue, the person, or the Datadog pipeline change. Don't write "investigate
further" as a step; do the investigation before reaching this section.

## Failure modes / gotchas

- **No Slack hits**: fall back to user's time window or `now-4h`; don't block on Slack.
- **Hundreds of errors/hour from one service**: almost always misclassification — confirm with volume analysis before calling it a real outage.
- **SQS / EKS MCP auth**: pass `--profile datalake-stg` (staging) or `datalake-prod` (prod) explicitly; never change the user's active AWS config.
- **Large log responses spilling to file**: read the file with `Read` or `mcp__fff__grep` — do not re-query smaller.
- **Multiple concurrent alerts**: triage the highest-volume / most critical-path service first; note the others at the end of the report.
- **Attribute prefix confusion**: in DD query language use `@field`, not `@custom.field` — the latter returns zero even if the raw JSON shows `custom.field`.
