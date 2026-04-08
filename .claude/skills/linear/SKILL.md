---
name: linear-best-practices
description: >-
  Best practices for creating and managing Linear tickets per Data & Gen AI process.
  Use when creating issues, updating tickets, or any Linear MCP interaction. Covers
  governance, intake routing, defaults, statuses, descriptions, assignment, support
  triage, and when to ask for clarification.
---

# Linear Best Practices

## Authentication

Authenticate via the Linear MCP server (`mcp__linear-server`). If MCP tools are unavailable or auth fails, instruct the user to configure the Linear MCP server and restart their editor.

If the MCP server exposes an `mcp_auth` tool, call it before any other Linear operations.

## Defaults

- **Team**: Data & Gen AI
- **Assignee**: Cecil Ash (`cash@teamworks.com`)
- **State**: **To Do** for normal engineer-facing work the user wants queued — unless the issue is **support/triage** or severity is unknown, then prefer **Triage**

Always apply these defaults unless the user explicitly overrides them.

## Issue Model (Company Requirements)

Every issue needs:

- **Clear title** — specific outcome, not “Fix table” / “Bug”.
- **Acceptance criteria** — observable “done” (bullets).

**Engineers write and refine their own issues** (even if someone else created the ticket, the assignee should tighten it before starting). Product owns *what/why* in the PRD; issues carry the *how* at a useful granularity.

## Writing Descriptions

Keep descriptions **short and scannable**. Avoid walls of text.

**Do:**

- 2-4 sentences max for the objective
- Bullet lists for acceptance criteria
- Link to relevant code, MRs, PRDs, or docs instead of duplicating content
- For **bugs**: reproduction steps, expected vs actual, scope/severity when known
- For **support-originated** work: note **Salesforce (or source) ticket link** when the user provides it

**Don’t:**

- Write multi-paragraph narratives
- Put full implementation specs here (MR / code comments)
- Repeat the title

**Example:**

```markdown
## Objective
Add retry logic to the S3 upload path for transient failures.

## Acceptance Criteria
- Retries up to 3 times with exponential backoff
- Logs each retry attempt at WARN level
- Raises after final failure with original exception
```

## Projects & Estimates (When Relevant)

- Issues usually sit under a **Project**; **link the project** in Linear when the MCP supports it and the user named one.
- **Projects** are ~**1–4 weeks**, **1–3 people**; if bigger, split. **T-shirt sizes (S/M/L/XL)** apply at **project** level; **L** and **XL** imply **milestones** (meaningful, verifiable). Individual issues **don’t** need point estimates unless the user asks.
- **Scope discipline:** new work **outside** the project’s original acceptance criteria → **new project** (or explicit EM/Product decision), not an ever-growing same-date bucket.

## Clarifying Intent

**Before creating a ticket, ask the user to clarify if any of these are ambiguous:**

- What problem this solves or why it’s needed
- Which system/component is affected
- Whether this is a feature, bug, or chore

Do not guess — a short clarifying question saves more time than a wrong ticket.

## Creating Issues

```
mcp__linear-server__save_issue(
  title="Clear, concise title",
  description="Short description (see style above)",
  teamName="Data & Gen AI",
  assigneeName="Cecil Ash"
)
```

- For **sub-tasks**, include **`parentId`** when known.
- For **bugs**, include **reproduction steps** and severity if known.
- For **features**, include **acceptance criteria** bullets.
- Set **state** to **Triage** vs **To Do** per intake rules above when the MCP allows.

## Support & Bug Week (Pointers)

Support issues should be **triaged** (repro, duplicates, severity), **linked to the external ticket**, worked **high before medium** severity, moved to **In Review** when the fix is ready and **customer/support needs to confirm**, then **Done** after confirmation. **Stale In Review** is a known gap — PM/EM may need to chase closure; mention if an issue has been waiting on customer confirmation a long time.
