# Query Templates, Noise Catalog, and Report Format

AWS account for all Datadog queries: `322609035462`.

## Contents

- [Slack lookup](#slack-lookup)
- [Datadog query templates](#datadog-query-templates)
- [Noise tells](#noise-tells)
- [AWS verification matrix](#aws-verification-matrix)
- [Datadog deep-link](#datadog-deep-link)
- [Report template](#report-template)

---

## Slack lookup

Channel ID for `#alerts-data-platform-datadog` is `C0APZDC6Y20` — use it directly,
no lookup needed.

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

**Permalink → time window.** From permalink `…/p1778595937961909` → strip `p`,
insert `.` before last 6 digits → `1778595937.961909`. Then:

- `from` = `message_ts − 4 hours` (errors can incubate before the alert fires)
- `to`   = `message_ts + 30 minutes`

---

## Datadog query templates

### Anchor the alert to a service

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

---

## Noise tells

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

---

## AWS verification matrix

Only run the checks relevant to the suspected root cause. Always pass
`profile = "datalake-stg"` or `"datalake-prod"` explicitly — never change the
user's active AWS config. Clusters: `datalake-stg` (staging), `datalake-latest` (prod).

| Symptom | Check | Key signal |
|---|---|---|
| Poller / processor errors | `sqs get_queue_attributes` — `ApproximateNumberOfMessages`, `NotVisible`, `NumberOfMessagesDeleted` | High queue depth + low deletes = stalled consumer; high NotVisible = repeated failures |
| App crash / OOMKill | `mcp__aws-eks__list_k8s_resources` for pods, then `get_pod_logs tail_lines=100` | Pod in `CrashLoopBackOff`, `OOMKilled`, or `Error` |
| Throughput / timeout | `cloudwatch get_metric_statistics` — `AWS/SQS ApproximateAgeOfOldestMessage` | Rising age = consumer lag |
| Kafka publish errors | `kafka list_clusters` then describe the cluster | Broker health / under-replicated partitions |

---

## Datadog deep-link

```
https://app.datadoghq.com/logs?query=<URL-encoded-query>&from_ts=<epoch_ms>&to_ts=<epoch_ms>&live=false
```

Encode the query string with:

```bash
python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "<query>"
```

---

## Report template

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

**Classification: <LABEL>**

## Proposed next steps

1. <Specific action — owner if known, e.g. "Open Linear ticket for Status Remapper on catapult-processor (DP team)">
2. <Second action if warranted>
3. <Optional: monitoring step — "Watch SQS ApproximateAgeOfOldestMessage for the next 2h">
```
