# Linear Project Sprint Reference

## Contents

- [Headless single-ticket execution](#headless-single-ticket-execution)
- [Resolving team and workflow state IDs](#resolving-team-and-workflow-state-ids)
- [Spawn code](#spawn-code)
- [Sprint results template](#sprint-results-template)
- [Error handling](#error-handling)

---

## Headless single-ticket execution

For a **single** ticket outside the interactive sprint (scripting, automation, or a one-off run), invoke Claude Code in print mode (`-p`), scope allowed tools, and capture structured output to a file. Substitute the ticket identifier, task wording, result path, and quality commands (`make` vs `just`, etc.) for the target repo.

```bash
claude -p "Execute ticket DP-660: Add structured logging config to all poller DAGs. Read the ticket from Linear, implement the changes, run make lint and make test, then commit with message referencing DP-660." \
  --allowedTools "Edit,Read,Bash,Glob,Grep,Agent" \
  --output-format json > dp660-result.json
```

**Non-interactive task wording** (use inside `-p "..."` or equivalent; replace `DP-XXX` with the real ticket id):

```
Execute ticket DP-XXX. Do not ask me any questions. Read the ticket, read the relevant code, make the changes, run linters and tests, commit, and push. If anything is ambiguous, state your assumption in the commit message and proceed.
```

---

## Resolving team and workflow state IDs

After authenticating, inspect what tools the Linear MCP exposes — look for
tools named `list_workflow_states`, `workflowStates`, `teams`, or similar.
Derive the team from the project itself (don't hardcode a name):

```python
# Get the project to find which team owns it
project = mcp__linear-server__[get_project_tool](id="<project-id>")
TEAM_ID = project.team.id   # use the team that owns this project

# Look up workflow states for that team
states = mcp__linear-server__[workflow_states_tool](teamId=TEAM_ID)
state_map = {s.name: s.id for s in states}

IN_PROGRESS_ID = state_map["In Progress"]
IN_REVIEW_ID   = state_map["In Review"]
PAUSED_ID      = state_map["Paused"]
TRIAGE_ID      = state_map["Triage"]
IDEA_ID        = state_map["Idea"]
```

Inject all five IDs plus TEAM_ID as template variables into every agent prompt.

---

## Spawn code

```python
# Create a team for this sprint
TeamCreate(name=f"sprint-{project_slug}")

# Add one task per ready ticket — include enough context for agents to act
for ticket in ready_tickets:
    TaskCreate(
        subject=f"{ticket.identifier}: {ticket.title}",
        description="\n".join([
            f"ID: {ticket.identifier}",
            f"URL: {ticket.url}",
            f"Labels: {', '.join(l.name for l in ticket.labels) or 'none'}",
            f"Description:\n{ticket.description or '(none)'}",
        ]),
        activeForm=f"Executing {ticket.identifier}"
    )

# Spawn agents — they each claim tasks from the shared list
max_agents = min(len(ready_tickets), 8)
for i in range(max_agents):
    Agent(
        name=f"sprint-agent-{i+1}",
        model="sonnet",
        mode="bypassPermissions",
        prompt=SPRINT_AGENT_PROMPT,  # verbatim from agent-prompt.md
        run_in_background=True,
    )
```

---

## Sprint results template

```markdown
## Sprint Results — <project name>

### Solved (MR created) — In Review
- [DP-1](url): Title — MR !123
- [DP-3](url): Title — MR !125

### Paused (needs input)
- [DP-2](url): Title — investigation notes added to ticket
- [DP-4](url): Title — blocked on missing credentials

### Needs Clarification — moved to Idea
- [DP-5](url): Title — no acceptance criteria; comment left asking for AC

### Skipped (blocked or sub-task)
- [DP-6](url): Title — blocked by DP-1 (still open)

Total: N solved, M paused, K needs-clarification, J skipped
```

---

## Error handling

| Situation | Action |
|-----------|--------|
| Linear MCP unavailable | Abort; instruct user to configure MCP and restart |
| `glab` not authenticated | Run `glab auth login` and retry |
| No Backlog tickets | Report and stop |
| Agent fails mid-ticket | Log failure, leave Linear comment → Paused, continue |
| `just ci` unavailable | Run `just test && just lint` manually |
| `just ci` failures | Fix or document as blocker in ticket comment → Paused |
| No acceptance criteria | Move ticket → Idea; leave comment asking for AC |
