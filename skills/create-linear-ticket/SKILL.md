---
name: create-linear-ticket
description: >-
  Creates a single Linear ticket with specified project, assignee, status, and description.
---

# Create Linear Ticket

Create a single Linear ticket with all required metadata specified up front.

**Core principle:** Every ticket must be classified as feature, chore, or bug. Resolve all required fields before calling the MCP tool.

## Required Fields

All seven are required before calling the MCP tool:

1. **Title** — specific outcome, not vague ("Fix table" is bad; "Fix S3 upload returning 500 on retry" is good)
2. **Description** — use the appropriate template below
3. **Team** — Data & Gen AI
4. **Label** — exactly ONE of `feature`, `chore`, `bug`
5. **Assignee** — always Cecil Ash (`cash@teamworks.com`), no exceptions
6. **Project** — use the user's project if named; otherwise default to **Improve Production Resiliency** (`https://linear.app/teamworks/project/improve-production-resiliency-6b1052fc3cd7/overview`)
7. **State** — `Todo` for normal work; `Triage` for support/severity-unknown issues

## Ticket Type Classification

```
Is this changing user-facing or system behavior?
├─ YES → Is it fixing broken behavior?
│         ├─ YES → BUG
│         └─ NO  → FEATURE
└─ NO  → CHORE
```

## Description Templates

### Feature

```markdown
## Objective
[What we're building and why]

## Acceptance Criteria
- [ ] [Observable done condition 1]
- [ ] [Observable done condition 2]

## TDD Checklist
**RED:** Write failing tests for each behavior
**GREEN:** Implement minimal code to pass
**REFACTOR:** Clean up while keeping tests green

## Files to Touch
- [file paths]
```

### Chore

```markdown
## Objective
[Description of maintenance task and why it's needed]

## Approach
[How to accomplish this]

## Verification Checklist
- [ ] Changes implemented
- [ ] All existing tests still pass
- [ ] Lint/format checks pass
- [ ] No regressions introduced
```

### Bug

```markdown
## Bug Description
[What is broken and how it manifests]

## Expected Behavior
[What should happen]

## Actual Behavior
[What currently happens]

## Fix Checklist
- [ ] Reproduce bug consistently
- [ ] Write failing test that reproduces bug
- [ ] Implement minimal fix
- [ ] Verify all tests pass with no regressions
```

## Writing Descriptions

- 2-4 sentences max for the objective
- Bullet lists for acceptance criteria
- Link to relevant code, MRs, or docs instead of duplicating content
- For bugs: include reproduction steps and expected vs actual
- Never repeat the title; no multi-paragraph narratives

## Creating the Ticket

```python
mcp__linear-server__save_issue(
    title="[Clear, concise title]",
    description="[Use appropriate template above]",
    teamName="Data & Gen AI",
    assigneeName="Cecil Ash",
    projectName="Improve Production Resiliency",  # default; override if user names another
    stateName="Todo",               # or as specified
    labelNames=["feature"],         # REQUIRED: exactly one of feature/chore/bug
)
```

**For sub-tickets**, include `parentId` when the user provides a parent ticket.

## Validation Before Creating

- [ ] Title is specific (not vague)
- [ ] Exactly one type label: feature, chore, or bug
- [ ] Project is set (user-named, or default Improve Production Resiliency)
- [ ] Description uses the correct template for the type
- [ ] Assignee is Cecil Ash

## After Creating

Report back: ticket ID, title, URL, project, state, and label.
