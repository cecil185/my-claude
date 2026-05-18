---
name: standup
description: >-
  Generate a daily standup Slack message from Linear ticket status changes and
  merged GitLab MRs in the last 24 hours. Use when the user asks for a standup,
  daily update, or status summary.
model: sonnet
effort: low
---

# Daily Standup Generator

Produce a standup Slack message in two sections: **Yesterday** and **Today**.

---

## Step 1 — Fetch Linear tickets updated recently

First, check today's day of the week. If today is **Monday**, use a 72-hour lookback (`-P3D`) to cover the weekend and include Friday's activity. Otherwise, use a 24-hour lookback (`-P1D`).

Call `mcp__linear-server__list_issues` with:
- `assignee: "me"`
- `updatedAt: "-P3D"` (Monday) or `"-P1D"` (all other days)
- `limit: 250`

From the results, identify **actual status changes** by checking `startedAt`, `completedAt`, and `canceledAt` timestamps — if they fall within the lookback window, that ticket had a status change. Ignore tickets where only `updatedAt` changed (those are likely description/label edits).

---

## Step 2 — Fetch all currently active tickets

Run these two calls in parallel:
- `mcp__linear-server__list_issues` with `assignee: "me"`, `state: "In Progress"`
- `mcp__linear-server__list_issues` with `assignee: "me"`, `state: "In Review"`

These form the **Today** section.

---

## Step 3 — Find merged GitLab MRs for Yesterday's Done tickets

For each ticket that moved to **Done** yesterday, call `mcp__GitLab__search` with:
- `scope: "merge_requests"`
- `search: "<TICKET-ID>"` (e.g. `"DP-812"`)
- `state: "merged"`

Filter results to only those where `merged_at` is within the lookback window (72 hours on Monday, 24 hours otherwise). Extract the `title` and which repo it merged into (parse from `references.full`).

Run these searches in parallel across all Done tickets.

---

## Step 4 — Format the Slack message

Use this structure exactly:

```
**Yesterday**
- <TICKET-ID> moved to Done: <short title>
  - Merged: `<MR title>` → `<repo short name>`   ← only if MRs found
- <TICKET-ID> moved to In Review: <short title>

**Today**
- <TICKET-ID> Done: <short title>      ← completed today
- <TICKET-ID> In Progress: <short title>
- <TICKET-ID> In Review: <short title>
```

### Formatting rules

- **Yesterday** includes: tickets whose `completedAt` or `startedAt` (→ In Review / In Progress) fell within the lookback window. On Mondays, label this section `*Since Friday*` instead of `*Yesterday*`. Group merged MRs under their ticket as sub-bullets.
- **Today** includes: all currently In Progress and In Review tickets, plus any tickets completed today (same day, not yesterday).
- Keep titles short — strip boilerplate like "Phase N:", "feat:", "fix:" prefixes where they add no meaning.
- Repo short name: extract the last segment of `references.full` (e.g. `ingestion-dags!38` → `ingestion-dags`).
- Do not include ticket IDs that appear in both Yesterday and Today — Yesterday takes priority.
- Output plain Slack-compatible markdown (bold with `*`, not `**`). Use `*Yesterday*` and `*Today*` as headers.

---

## Example output

```
*Yesterday*
- DP-812 Done: Core incremental read via `hudi_table_changes()`
  - Merged: `feat(DP-812): incremental reads via TBLPROPERTY checkpoint` → `ingestion`
  - Merged: `add incremental default for calculated fields DAG` → `ingestion-dags`
- DP-825 In Review: Fix `ingestion.lead_time_seconds` never firing (KafkaTimeoutError)
- DP-813 In Review: Phase 2 no-op detection — skip tables with zero new commits

*Today*
- DP-833 Done: Bump ingestion-terraform CI pipeline ref to 4.1.0
- DP-771 In Progress: Phase 3 data freshness metric (SQS → Postgres)
- DP-768 In Progress: Create Datadog dashboard
- DP-733 In Progress: SPIKE — automated data quality and validation checks
- DP-640 In Review: Rate limiting on incoming webhook listener requests
- DP-727 In Review: Change Snyk failure threshold from high to medium
```
