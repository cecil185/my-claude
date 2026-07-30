---
name: test-gap-scan
description: >-
  Scans the ingestion codebase for two kinds of testing problems: (1) key modules or behaviours
  with no test coverage at all, and (2) tests that exist but test the wrong thing — asserting
  "it ran" instead of "it did the right thing". Produces a tiered gap report with concrete
  write-a-test recommendations. Trigger when user says "scan for test gaps", "test coverage
  audit", "find shallow tests", "where are we missing tests", "test quality scan", "what tests
  are we missing", or "audit our tests".
---

# Test Gap Scan

Audit the `ingestion/` codebase for missing and low-quality tests.
Two distinct failure modes are in scope:

**Gap A — no test exists:** key module or behaviour is completely untested.

**Gap B — test exists but tests the wrong thing:** assertions are tautological,
only the happy path is covered, or mocking is so aggressive the real code is never
called.

Full gap definitions, anti-pattern catalog, scenario checklist, report format, and
Linear ticket templates are in [reference.md](reference.md).

---

## Step 1 — Collect Line-Level Coverage Data

**Do not use filename matching.** Run the test suite with coverage instrumentation and
parse the output to get ground truth: exactly which lines were executed by any test.

### 1a. Run pytest with branch coverage

```bash
cd ingestion && uv run pytest \
  --cov=platform_ingestion \
  --cov-report=json:.coverage.json \
  --cov-branch \
  -m 'not integration' \
  -q --tb=no
```

`--cov-branch` captures branch coverage (if/else paths), not just line coverage.
This is important: a line can be executed while only one branch of an `if` is ever tested.

### 1b. Parse the coverage report

```bash
python /Users/cecil/.claude/skills/test-gap-scan/parse_coverage.py ingestion/.coverage.json
```

The script emits four sections — GAP A, PARTIAL, BRANCH GAPS, and FULL. See
[coverage output sections](reference.md#coverage-output-sections).

### 1c. Verify Gap A functions with fff search

Coverage infers "never called" from line data, which produces false positives for
nested functions and import-time artefacts. Before promoting any function to the Gap A
list, confirm no test references it — see
[verifying Gap A with fff search](reference.md#verifying-gap-a-with-fff-search).
Do this for every function `parse_coverage.py` flagged.

### 1d. Interpret the output

Follow [reading the sections](reference.md#reading-the-sections). The key move: for
every PARTIAL module, read the specific missing line numbers in the source file. That
is what turns "partially tested" into a concrete Gap B finding.

Coverage is the authority, not filenames — do not file a Gap A for a module in the
FULL or BRANCH GAPS sections just because no `test_<module>.py` exists by name.

---

## Step 2 — Assess Test Quality (Gap B Detection)

Use the coverage output from Step 1 to focus this analysis. For each PARTIAL module,
read the source lines identified as missing, then read the corresponding test file(s)
to understand why those lines are not reached.

For FULL-covered modules, still scan the test file for shallow assertion patterns —
high line coverage does not mean the assertions are meaningful.

Do this for every test file — not just a sample. This is an audit, not a spot check.

Run all five checks from
[Gap B assessment checks](reference.md#gap-b-assessment-checks) on each file:
assertion strength, side effects verified, error paths, mock depth, and extra scrutiny
on `test_*_coverage.py` files.

---

## Step 3 — Identify High-Value Missing Scenarios

Beyond file-level gaps, walk the
[high-value behavioural scenarios](reference.md#high-value-behavioural-scenarios)
checklist covering SQS/messaging, vendor API/poller, processor/Avro, webhook listener,
and multi-tenancy. For each scenario, check whether a test covers it. If not, it's a
Gap A or Gap B candidate.

---

## Step 4 — Produce the Gap Report

Output a structured report following the
[report template](reference.md#report-template) — summary counts, 🔴 Gap A table,
🟡 Gap B per-file findings, 🟡 missing scenarios table, and next steps prioritised by
blast radius if wrong.

---

## Step 5 — Optional: Create Linear Tickets

Ask Cecil before creating tickets. Don't auto-create. Use the
[Linear ticket templates](reference.md#linear-ticket-templates) — one ticket per Gap A
module, one per Gap B test file.

---

## Guardrails

- **Never delete or modify existing tests** — the audit is read-only. Recommendations go in the report; implementation is a separate task.
- **Don't conflate low coverage with bad tests** — a module can have high line coverage but still have tautological tests. Assess quality, not just presence.
- **Don't recommend tests for pure models/schemas** — Pydantic models, Avro schema definitions, and dataclasses with no logic don't need unit tests.
- **Flag, don't fix** — this skill produces a report. Fixing is done via `/adlc:execute` or a standalone coding task.
- **State confidence** — if a Gap B flag is uncertain (e.g., the mock depth might be intentional), say so in the report rather than asserting it's a problem.

---

## Checklist

- [ ] Ran `pytest --cov=platform_ingestion --cov-report=json --cov-branch` successfully
- [ ] Ran `parse_coverage.py` and read its full output
- [ ] For each Gap A function: ran `mcp__fff__multi_grep` against `tests/` to confirm no test references it
- [ ] Built confirmed Gap A list (coverage data + fff verification, not filename matching)
- [ ] For each PARTIAL module: read the missing line numbers in source to understand what's untested
- [ ] Read every test file for Gap B shallow-assertion patterns
- [ ] Checked for missing behavioural scenarios across SQS, poller, processor, webhook, multi-tenancy
- [ ] Produced structured report with 🔴/🟡/✅ tiers, citing specific line numbers for Gap B findings
- [ ] Offered to create Linear tickets (didn't auto-create)
