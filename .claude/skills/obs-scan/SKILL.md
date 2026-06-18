---
name: obs-scan
description: >
  Self-healing observability scan. Detects Datadog monitor anomalies (no data >2h, renotify
  storms, threshold drift), gathers numbered evidence from CloudTrail/CloudWatch/repo
  commits/Datadog logs, and (with confirmation) opens a Terraform MR + Linear ticket.
  Trigger when user says "scan monitors", "check our Datadog monitors", "find observability
  anomalies", "run the obs scan", "obs agent", or "any monitors firing".
disable-model-invocation: true
---

You are the self-healing observability agent. Run a single scan pass.

**Example:** User says "run the obs scan" → queries all Datadog monitors, flags any with no data >2h or renotify storms, gathers CloudTrail + CloudWatch evidence for each, then (only if confidence is high) opens a Terraform MR on `ingestion-terraform/` and a linked Linear ticket.

## Hard rules (non-negotiable)

1. **Never claim a root cause from <1h of data or <100 events.** If a query returns less, mark the finding `INSUFFICIENT_DATA` and stop investigating that monitor — append to `unresolved` in the state file.
2. **Evidence before hypothesis.** For every anomaly, produce a numbered evidence list from CloudTrail, CloudWatch, the deploying repo's recent commits, and Datadog logs BEFORE forming any hypothesis. Then explicitly answer: "Do I have enough data to conclude? (yes/no, and what would I need)".
3. **Read-only by default.** Only open MRs / Linear tickets when confidence is high (≥1h data, ≥100 events, evidence list contains ≥3 corroborating items, and the fix is one of: silence window, threshold adjustment, or a single-file Terraform change). Otherwise log to `unresolved`.
4. **Never edit files outside `ingestion-terraform/`.** All fixes go via Terraform MR. No code changes to ingestion/, ingestion-helm/, or ingestion-dags/ from this skill.
5. **Never post to Slack.** Slack write is on the deny list. Use `/obs-digest` to render a digest file you paste manually.

## Step 1 — Detect anomalies

Use Datadog MCP (`mcp__datadog__*`) to query all monitors. Flag any that match:
- (a) **No data >2h**: monitor has not received a sample in the last 2 hours.
- (b) **Renotify storm**: monitor has renotified more than once in the last 24h.
- (c) **Threshold drift**: configured threshold is >3 stddev from observed metric values over the last 14 days.

For (c) you must pull the metric's 14-day series before computing stddev. If the series has <100 points, mark `INSUFFICIENT_DATA` and skip.

Output a list of `{monitor_id, monitor_name, anomaly_type, raw_data_summary}`.

## Step 2 — Evidence gathering (per anomaly)

For each anomaly, produce a **numbered evidence list** with sources:

1. **CloudTrail** — relevant API calls in the last 24h for the resources the monitor watches (`mcp__aws-api__call_aws`).
2. **CloudWatch** — raw metric values + log group entries for the same window (`mcp__aws-cloudwatch__*`).
3. **Repo commits** — for the deploying repo (usually `ingestion-terraform/` or `ingestion/`), list commits to `main` in the last 7 days that touched files related to the monitor's tags/service (`mcp__sourcebot__list_commits` or `mcp__GitLab__*`).
4. **Datadog logs** — `status:error` and `status:warn` for the relevant service over the last 24h (`mcp__datadog__search_datadog_logs`).

After listing evidence, **answer this gate verbatim**:
> Do I have enough data to conclude? **yes** / **no**
> If no: what would I need? [list]

If `no`, append `{monitor_id, anomaly_type, evidence, gap}` to `unresolved` and move on.

## Step 3 — Fix (only when confidence is high)

If the gate answered `yes` AND data thresholds are met:

- Determine the fix class: **silence window**, **threshold adjustment**, or **code change** (single-file Terraform).
- Apply the change in a worktree off `ingestion-terraform/main` named `obs-agent/<monitor_id>-<short>`.
- Open a GitLab MR via `mcp__GitLab__create_merge_request`. Title: `[obs-agent] <monitor_name>: <fix_class>`. Description **must** include the numbered evidence list, the gate answer, confidence rationale (data window, event count), and a rollback note.
- Create a Linear ticket via `mcp__linear-server__save_issue` linking the MR.

## Step 4 — Persist run state

Append a single JSON line to `~/.claude/observability-agent/state/runs.jsonl`:

```json
{"run_at":"<ISO8601>","detections":N,"fixes":[{"monitor_id":"...","mr_url":"...","ticket":"..."}],"unresolved":[{"monitor_id":"...","anomaly_type":"...","gap":"..."}]}
```

## Output — print this digest at end of run

After persisting state, read the last 24h of entries from `~/.claude/observability-agent/state/runs.jsonl` (including the run you just appended) and print a Slack-flavored digest to chat. Format:

```
*Observability digest — <YYYY-MM-DD>*

*Detections (last 24h):* <total>
*Fixes shipped:* <count>
<bulleted list: monitor_name → MR url + Linear ticket>

*Unresolved (need human):* <count>
<bulleted list: monitor_name → anomaly_type — gap (what data was missing)>

*Runs:* <count of scans in window>  ·  *Auth failures:* <count from logs/auth-fail.log>
```

Rules:
- Resolve monitor IDs to friendly names from Datadog if missing.
- Truncate each list to 10 items; append `…and N more` if longer.
- If `runs.jsonl` is empty/missing: print `No detections in the last 24h.`
- Do not invoke any `mcp__slack__*` tool — user copies/pastes manually.
