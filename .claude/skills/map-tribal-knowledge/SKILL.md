---
name: map-tribal-knowledge
description: Maps undocumented tribal knowledge in a codebase into concise, AI-queryable context files. Runs a multi-phase process (explore → analyse → generate → QA → validate) that extracts non-obvious design patterns, naming conventions, cross-module dependencies, and gotchas that exist only in engineers' heads. Trigger when user says "document the codebase", "create context files", "surface tribal knowledge", "help agents understand our pipelines", "map the codebase", or "what do new engineers need to know".
disable-model-invocation: true
---

# Map Tribal Knowledge

Transforms a codebase's implicit knowledge into explicit, AI-queryable context files. Each context file is a "compass, not an encyclopedia" — 25–35 lines (~1,000 tokens) that unlock everything else.

Skip phases only when explicitly justified. Quality gates exist because vague context files are worse than none.

---

## Phase 1 — Exploration

**Goal:** Understand the shape of the codebase before analysing any individual module.

### 1a. Inventory

Collect:
- All top-level directories and their rough purpose
- Primary languages and entry points
- Cross-repo dependencies (list repos touched by a single feature change)
- Existing documentation (READMEs, ADRs, wikis, runbooks)

```
Deliverable: a flat list of modules/directories to analyse, sorted by centrality
(heavily imported modules first — they carry the most tribal knowledge).
```

### 1b. Dependency graph

Build a cross-module dependency index:
- Which modules import which
- Which Airflow DAGs invoke which pipeline stages
- Which Terraform resources feed which application configs

This transforms later exploration from sequential file reads into single graph lookups.

```
Deliverable: a text or mermaid graph of the top-level data flow.
```

---

## Phase 2 — Module Analysis

For **every module or directory** in the inventory, answer the five standardised questions below. Do not skip a module because it "looks simple" — non-obvious patterns hide in plain sight.

### The Five Questions

For each module, answer:

1. **What does this module configure or do?**
   One sentence. Not "it processes data" — name the specific pipeline stage, resource type, or decision it encodes.

2. **What are common modification patterns?**
   What changes do engineers make here most often? What's the standard diff that touches this file?

3. **What non-obvious patterns cause build or runtime failures?**
   Name the tripwires. Examples: field naming conventions enforced by a downstream stage, append-only identifiers that break backward compat if removed, environment-specific overrides silently taking precedence.

4. **What cross-module dependencies exist that aren't obvious from imports?**
   Examples: a Helm value that must match a Terraform output, a DAG parameter that must align with a Kafka topic name, a processor that assumes a specific SQS message schema produced elsewhere.

5. **What tribal knowledge is buried in code comments, commit messages, or Slack history?**
   Surface it. If you see a `# DO NOT CHANGE` comment with no explanation, that's a flag — dig into git blame and summarise why.

```
Deliverable: a structured answer to all five questions per module.
Store raw answers as scratch notes — they feed Phase 3.
```

---

## Phase 3 — Context File Generation

Synthesise each module's five-question answers into a single context file.

### Format (strict)

```
# <Module Name>

## Quick Commands
<2–4 one-liner commands an engineer would run to inspect, test, or deploy this module.>

## Key Files
<3–5 file paths with a one-line description of each. Only the files that unlock the rest.>

## Non-Obvious Patterns
<Bullet list of gotchas, constraints, naming rules, ordering requirements, or implicit contracts.
Each bullet must be specific enough to prevent a real mistake.>

## Cross-References
<Links to related context files, Terraform outputs, DAG names, Helm values, or Linear tickets
that an engineer must understand before modifying this module.>
```

### Hard constraints

- **25–35 lines total.** If you exceed 35, cut — don't compress into run-on sentences.
- **No restating what the code already says.** Every line must carry information not derivable from reading the file header.
- **Specific over general.** "Field names must be lowercase snake_case" beats "follow naming conventions."
- Save each file as `context/<module-name>.md` relative to the repo root (or a docs subfolder if one exists).

---

## Phase 4 — Quality Review

Each context file gets three independent critic passes before it ships.

### Critic checklist (run per file)

Score each dimension 1–5:

| Dimension | What to assess |
|-----------|---------------|
| **Specificity** | Are patterns named concretely, or are they vague generalisations? |
| **Completeness** | Does it cover all five question areas, even if briefly? |
| **Density** | Is every line load-bearing, or is there filler? |
| **Actionability** | Could a new engineer use this to make a correct change without asking anyone? |
| **Accuracy** | Are all file paths, command names, and cross-references verifiable right now? |

**Target: average ≥ 4.0 / 5.0 across all dimensions.**

Files scoring below 4.0 get returned to Phase 3 with specific line-level feedback. Re-score after each revision pass. Stop at three passes — a file that still scores below 3.5 after three passes needs a human to fill the gap; flag it explicitly.

---

## Phase 5 — Validation

Before declaring the context map complete, verify it actually helps.

### Query test suite

Run at least five test queries — one per user persona below — against the generated context files. For each query, check: does reading the relevant context file(s) give a correct, complete answer without opening any source file?

| Persona | Sample query |
|---------|-------------|
| **New engineer** | "Where do I add a new field to the Catapult webhook processor?" |
| **On-call** | "Which pipeline stage is most likely responsible for a schema mismatch error in Kafka?" |
| **Infra engineer** | "What Terraform outputs does the SQS poller depend on?" |
| **AI agent** | "What are all the files I must touch to add a new vendor integration?" |
| **Senior reviewer** | "What backward-incompatibility risks exist in the identifier fields?" |

For any query that fails, identify which module's context file is missing or thin, then loop back to Phase 2 for that module.

### Coverage check

Verify:
- [ ] Every directory in the Phase 1 inventory has a context file
- [ ] Every cross-repo dependency identified in Phase 1b has at least one cross-reference in a context file
- [ ] No context file references a file path that no longer exists (run a quick existence check)

---

## Phase 6 — Index and Maintenance

### Master index

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

### Staleness signals

A context file is stale when:
- The referenced file paths no longer exist
- A module it cross-references has been renamed or split
- A commit message says "BREAKING CHANGE" in a module it covers

Add a staleness check to CI if the repo has a test suite:
- On each merge to main, grep context files for file paths and verify they exist
- Flag missing paths as a warning (not an error — context files are docs, not code)

### When to re-run this skill

- A new vendor integration is added
- A major pipeline stage is refactored
- An on-call incident reveals a gap ("I didn't know X affected Y")
- A new engineer joins and asks questions not answered by the existing context files

---

## Output Checklist

Before closing:

- [ ] `context/INDEX.md` exists with the data flow graph and module table
- [ ] Every module has a context file passing the Phase 4 quality gate (≥ 4.0)
- [ ] Phase 5 query tests all pass
- [ ] Stale path check has been run
- [ ] Any modules flagged for human review are listed in `INDEX.md` under a "Gaps" section
