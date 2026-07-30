# Validation, Index, and Maintenance Reference

Details for Phases 5–6 of `map-tribal-knowledge`.

## Phase 5 — Query test suite

Run at least five test queries — one per persona. For each, check: does reading the relevant
context file(s) give a correct, complete answer without opening any source file?

| Persona | Sample query |
|---------|-------------|
| **New engineer** | "Where do I add a new field to the Catapult webhook processor?" |
| **On-call** | "Which pipeline stage is most likely responsible for a schema mismatch error in Kafka?" |
| **Infra engineer** | "What Terraform outputs does the SQS poller depend on?" |
| **AI agent** | "What are all the files I must touch to add a new vendor integration?" |
| **Senior reviewer** | "What backward-incompatibility risks exist in the identifier fields?" |

For any query that fails, identify which module's context file is missing or thin, then loop back
to Phase 2 for that module.

## Phase 6 — Master index

Create `context/INDEX.md`:

```markdown
# Codebase Context Index

## Data Flow
<Paste the Phase 1b dependency graph here.>

## Module Index
| Module | Context File | Last Updated | Key Gotcha |
|--------|-------------|--------------|-----------|
| <name> | context/<name>.md | <date> | <one-line gotcha> |
```

## Phase 6 — Staleness signals

A context file is stale when a referenced file path no longer exists, a cross-referenced module was
renamed or split, or a commit message says "BREAKING CHANGE" in a module it covers.

If the repo has a test suite, add a CI staleness check: on each merge to main, grep context files
for file paths and verify they exist. Flag missing paths as a warning, not an error — context files
are docs, not code.

## When to re-run this skill

- A new vendor integration is added
- A major pipeline stage is refactored
- An on-call incident reveals a gap ("I didn't know X affected Y")
- A new engineer joins and asks questions the existing context files don't answer
