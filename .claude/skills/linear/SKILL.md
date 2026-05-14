---
name: linear-best-practices
description: >-
  Best practices for creating and managing Linear tickets.
  Use when creating issues, updating tickets, or any Linear MCP interaction.
model: sonnet
effort: low
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
