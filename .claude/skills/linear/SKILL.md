---
name: linear-best-practices
description: >-
  Best practices for creating and managing Linear tickets. Use when creating issues,
  updating tickets, or any interaction with Linear via MCP. Covers defaults, description
  style, assignment, and when to ask for clarification.
---

# Linear Best Practices

## Authentication

Authenticate via the Linear MCP server (`mcp__linear-server`). If MCP tools are unavailable or auth fails, instruct the user to configure the Linear MCP server and restart their editor.

If the MCP server exposes an `mcp_auth` tool, call it before any other Linear operations.

## Defaults

- **Assignee**: Cecil Ash (`cash@teamworks.com`)
- **State**: Todo (for new tickets)

Always apply these defaults unless the user explicitly overrides them.

## Writing Descriptions

Keep descriptions **short and scannable**. Avoid walls of text.

**Do:**
- 2-4 sentences max for the objective
- Bullet lists for acceptance criteria
- Link to relevant code, MRs, or docs instead of duplicating content

**Don't:**
- Write multi-paragraph narratives
- Include implementation details that belong in code comments or MR descriptions
- Repeat information already in the title

**Example:**

```markdown
## Objective
Add retry logic to the S3 upload path for transient failures.

## Acceptance Criteria
- Retries up to 3 times with exponential backoff
- Logs each retry attempt at WARN level
- Raises after final failure with original exception
```

## Clarifying Intent

**Before creating a ticket, ask the user to clarify if any of these are ambiguous:**

- What problem this solves or why it's needed
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

For sub-tickets, include the `parentId`. For bugs, include reproduction steps. For features, include acceptance criteria.
