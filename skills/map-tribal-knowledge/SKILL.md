---
name: map-tribal-knowledge
description: Maps undocumented tribal knowledge in a codebase into concise, AI-queryable context files. Runs a multi-phase process (explore → analyse → generate → QA → validate) that extracts non-obvious design patterns, naming conventions, cross-module dependencies, and gotchas that exist only in engineers' heads. Trigger when user says "document the codebase", "create context files", "surface tribal knowledge", "help agents understand our pipelines", "map the codebase", or "what do new engineers need to know".
disable-model-invocation: true
---

# Map Tribal Knowledge

Turn a codebase's implicit knowledge into explicit, AI-queryable context files. Each context file
is a "compass, not an encyclopedia" — 25–35 lines (~1,000 tokens) that unlock everything else.

Skip phases only when explicitly justified. The quality gates exist because vague context files are
worse than none.

---

## Phase 1 — Exploration

Understand the shape of the codebase before analysing any individual module.

**1a. Inventory.** Collect top-level directories and their rough purpose, primary languages and
entry points, cross-repo dependencies (which repos a single feature change touches), and existing
docs (READMEs, ADRs, wikis, runbooks).

> **Deliverable:** a flat list of modules/directories to analyse, sorted by centrality — heavily
> imported modules first, since they carry the most tribal knowledge.

**1b. Dependency graph.** Index which modules import which, which Airflow DAGs invoke which
pipeline stages, and which Terraform resources feed which application configs. This turns later
exploration from sequential file reads into single graph lookups.

> **Deliverable:** a text or mermaid graph of the top-level data flow.

---

## Phase 2 — Module analysis

For **every** module in the inventory, answer these five questions. Do not skip a module because it
"looks simple" — non-obvious patterns hide in plain sight.

1. **What does this module configure or do?** One sentence. Not "it processes data" — name the
   specific pipeline stage, resource type, or decision it encodes.
2. **What are common modification patterns?** What changes do engineers make here most often; what's
   the standard diff that touches this file?
3. **What non-obvious patterns cause build or runtime failures?** Name the tripwires — e.g. field
   naming conventions enforced by a downstream stage, append-only identifiers that break backward
   compat if removed, environment-specific overrides silently taking precedence.
4. **What cross-module dependencies aren't obvious from imports?** E.g. a Helm value that must match
   a Terraform output, a DAG parameter that must align with a Kafka topic name, a processor that
   assumes an SQS message schema produced elsewhere.
5. **What tribal knowledge is buried in comments, commit messages, or Slack history?** A
   `# DO NOT CHANGE` comment with no explanation is a flag — dig into git blame and summarise why.

> **Deliverable:** structured answers per module, kept as scratch notes that feed Phase 3.

---

## Phase 3 — Context file generation

Synthesise each module's answers into one context file at `context/<module-name>.md`, relative to
the repo root (or a docs subfolder if one exists).

### Format (strict)

```
# <Module Name>

## Quick Commands
<2–4 one-liners an engineer would run to inspect, test, or deploy this module.>

## Key Files
<3–5 file paths, one line each. Only the files that unlock the rest.>

## Non-Obvious Patterns
<Gotchas, constraints, naming rules, ordering requirements, implicit contracts.
Each bullet must be specific enough to prevent a real mistake.>

## Cross-References
<Related context files, Terraform outputs, DAG names, Helm values, or Linear tickets
an engineer must understand before modifying this module.>
```

### Hard constraints

- **25–35 lines total.** Over 35 → cut, don't compress into run-on sentences.
- **No restating what the code says.** Every line carries information not derivable from the file header.
- **Specific over general.** "Field names must be lowercase snake_case" beats "follow naming conventions."

---

## Phase 4 — Quality review

Score each file 1–5 on: **Specificity** (concrete patterns vs. vague generalisations),
**Completeness** (covers all five question areas, even briefly), **Density** (every line
load-bearing), **Actionability** (a new engineer could make a correct change without asking anyone),
**Accuracy** (all paths, commands, and cross-references verifiable right now).

**Target: average ≥ 4.0.** Below 4.0 → return to Phase 3 with line-level feedback and re-score.
Stop at three passes; a file still below 3.5 needs a human — flag it explicitly.

---

## Phase 5 — Validation

Run the persona query test suite in [reference.md](reference.md) — at least five queries, each
answerable from the context files alone. Then verify coverage:

- [ ] Every directory in the Phase 1 inventory has a context file
- [ ] Every Phase 1b cross-repo dependency is cross-referenced in at least one context file
- [ ] No context file references a path that no longer exists

---

## Phase 6 — Index and maintenance

Create `context/INDEX.md` and set up staleness checks — templates, staleness signals, and re-run
triggers are in [reference.md](reference.md).

---

## Output checklist

- [ ] `context/INDEX.md` exists with the data flow graph and module table
- [ ] Every module has a context file passing the Phase 4 gate (≥ 4.0)
- [ ] Phase 5 query tests all pass
- [ ] Stale path check has been run
- [ ] Modules flagged for human review are listed in `INDEX.md` under a "Gaps" section
