---
name: linear
description: >
  Applies best practices when creating or updating Linear tickets: correct team, assignee,
  project, state, and description format. Trigger when user says "create a Linear ticket",
  "add a ticket", "log this in Linear", "update the Linear issue", or when using any
  Linear MCP tool.
model: sonnet
effort: low
disable-model-invocation: true
---

# Linear Best Practices

## Defaults

- **Team**: Data & Gen AI
- **Assignee**: Cecil Ash (`cash@teamworks.com`)
- **Project**: required — if not specified, **ask before creating**
- **State**: **To Do** normally; **Triage** for support/unknown severity

## Issue Requirements

- **Clear title** — specific outcome, not "Fix table" / "Bug"
- **Acceptance criteria** — observable "done" bullets
- For **bugs**: reproduction steps, expected vs actual, severity
- For **support work**: link the external (e.g. Salesforce) ticket

## Description Style

Short and scannable. 2-4 sentences objective + bullet acceptance criteria. Link out rather than duplicate. No multi-paragraph narratives, no implementation specs, no title repetition.


## Creating Issues

```
mcp__linear-server__save_issue(
  title="...",
  description="...",
  teamName="Data & Gen AI",
  assigneeName="Cecil Ash",
  parentId=...  # for sub-tasks
)
```

**Example:** User says "create a ticket for adding retry logic to the S3 poller" →
```
mcp__linear-server__save_issue(
  title="Add retry logic to S3 poller on transient failures",
  description="The S3 poller currently fails hard on transient errors. Add exponential backoff with 3 retries.\n\n**AC:**\n- Retries 3x with backoff on 5xx/timeout\n- Logs each retry attempt at WARN level\n- Alerts after all retries exhausted",
  teamName="Data & Gen AI",
  assigneeName="Cecil Ash"
)
```
