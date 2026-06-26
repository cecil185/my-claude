---
name: write-code-doc
description: >-
  Write or improve code documentation — READMEs, inline comments, API docs,
  runbooks, docstrings, or architecture guides that live in a repo. Trigger
  when user says "write a README", "document this function", "add a docstring",
  "write an API doc", or "document this for the codebase".
when_to_use: >-
  Trigger for any documentation that lives in or alongside code — READMEs,
  inline comments, docstrings, API references, runbooks in a repo.
---

# write-code-doc

> **Word limits (first draft)**
> - Inline comment: **≤ 2 lines**
> - Docstring: **1-sentence summary** + params only if non-obvious
> - README: **≤ 400 words**
> - Runbook: **minimum steps to complete safely**
> - API doc: **minimum to make each endpoint actionable**

Read the file for the specific doc type being written:

| Type | File |
|---|---|
| MR title | [mr-title.md](./mr-title.md) |
| MR body | [mr-body.md](./mr-body.md) |
| Inline comment | [inline-comment.md](./inline-comment.md) |
| README | [readme.md](./readme.md) |
| Runbook | [runbook.md](./runbook.md) |
| API doc | [api-doc.md](./api-doc.md) |

**First draft targets:**
- Inline comment: ≤ 2 lines — if it needs more, the code probably needs renaming
- Docstring / function doc: 1 sentence summary + params if non-obvious
- README: ≤ 400 words
- API reference: minimum to make each endpoint actionable
- Runbook: minimum steps to complete the operation safely

---

## Core Rule

**Document only what code can't say.** If a fact is obvious from reading the code — function signatures, types, variable names, control flow — do not document it. Docs exist for: intent, tradeoffs, constraints, operational knowledge, and cross-cutting context.

---

## Clarify Before Writing

If not already clear, ask:
- What type? (README, inline comment, docstring, API doc, runbook, architecture guide)
- Who's the reader? (teammate, future self, external consumer, oncall engineer)

One question. If obvious from context, skip and write.

---

## Doc Type Rules

### Inline Comments
- Write the **why**, never the what: `// skip tables with zero commits — avoids no-op promotions`
- One line max. If you need two, consider whether the code should be renamed instead.
- No end-of-line comments on obvious code

### Docstrings / Function Docs
```
One sentence: what this does and when to use it.

Args:
  param_name: what it is, valid range or type if non-obvious

Returns:
  what comes back, including edge cases (None, empty list, etc.)

Raises:
  ErrorType: when this happens
```
Skip sections that are self-evident from the signature.

### README
```
# Project Name

> One sentence: what this does and who it's for.

## Local Setup
## Architecture  (one paragraph or ASCII diagram)
## Development Workflow
## Deployment
## Contact / On-call
```

### API Reference
```
# API Name

> Summary — what this API does, auth model, base URL.

## Authentication
## Endpoints  (method, path, params, response, example)
## Error Codes
## Examples
```

### Runbook (in-repo)
```
# <Action> — <System>

> Summary — when to run this, what it does, risk level.

## Prerequisites
## Steps
## Validation
## Rollback
```

---

## Style Rules

- **Imperative mood for steps** — "Run `make lint`" not "You should run `make lint`"
- **Code blocks for everything** — every command, env var, file path, config key, even single words
- **Numbered lists for ordered steps** — bullet lists for unordered options
- **Tables for:** config keys + types + defaults, error codes + causes, service maps
- **No repetition** — state a fact once. If it's in another doc, link to it
- **No padding** — cut "This document covers…", "As mentioned above…", "In conclusion…"
- **Short sentences** — if a sentence has two clauses joined by "and", consider splitting

---

## Output

Deliver as markdown. No preamble, no trailing commentary. The doc is the deliverable.

If the request is ambiguous (unclear audience, unclear scope), ask one clarifying question — then write.
