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

---

## The Two Failure Modes in Detail

### Gap A — Coverage gaps

A function has a coverage gap when:
- `parse_coverage.py` reports zero executed lines within its line range, **and**
- `mcp__fff__multi_grep` finds no reference to it in `tests/`, **and**
- It contains non-trivial logic (not just a `pass` stub, abstract method, or pure schema field)

### Gap B — Shallow / tautological tests

A test is shallow when it does one or more of:

| Anti-pattern | Example |
|---|---|
| **Vacuous assertion** | `assert result is not None` when the function can never return None |
| **Tautology** | `assert result == function_under_test(input)` — assertion re-calls the code |
| **Mock bypass** | Every dependency mocked out, nothing real executes, test passes trivially |
| **Side-effect ignored** | Function publishes to Kafka or writes to SQS; test never asserts the publish happened |
| **Error path absent** | Only the happy path is tested; no test for what happens when the vendor API 4xx/5xx, SQS throws, or schema validation fails |
| **Coverage-only file** | File named `test_*_coverage.py` that existed to hit a line-count target, not to specify behaviour |
| **Pass-through assertion** | `assert response.status == 200` on a mock response that was configured to return 200 — the test is asserting the mock, not the code |

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

Run the skill's parser script against the JSON output:

```bash
python /Users/cecil/.claude/skills/test-gap-scan/parse_coverage.py ingestion/.coverage.json
```

The script emits four sections:

| Section | Meaning |
|---------|---------|
| **GAP A** | Functions/methods with zero executed lines — never called by any test |
| **PARTIAL** | Module is partially tested — exact missing line numbers and branch pairs listed |
| **BRANCH GAPS** | All lines hit but some if/else branches never taken |
| **FULL** | Every statement and branch covered |

### 1c. Verify Gap A functions with fff search

The coverage check infers "never called" from line data. Before promoting any function to the
Gap A list in the report, confirm no test references it by searching the `tests/` directory.

For each flagged function, use `mcp__fff__multi_grep` with the function name and common
test-call patterns. Example for a function `HeartbeatLease._renew`:

```
mcp__fff__multi_grep(
  patterns=["_renew", "HeartbeatLease"],
  path="ingestion/tests"
)
```

**Interpret results:**
- **No hits** → confirmed Gap A — include in report
- **Hits in test files** → the function is referenced; coverage gap may be a nested-function
  or import-time artefact — mark as "unconfirmed" and note it in the report instead of Gap A
- **Hits only in source files** (not tests) → still Gap A, the grep just found the definition

Do this for every function flagged by `parse_coverage.py` before writing the report. Batch
multiple function names into one `mcp__fff__multi_grep` call per module to keep it fast.

### 1d. Interpret the output

For **confirmed Gap A functions**: note the function name, file, line range, and size —
a 25-line untested method is higher priority than a 2-line stub.

For **PARTIAL** modules: the script prints the exact missing line numbers, e.g.:
```
platform_ingestion/processor/catapult.py  (77% — 42 missing lines)
  missing lines   : 88-101, 134-156, 201-230
  missing branches: 45→48, 62→65
```
Read those specific lines in the source file to understand **what code paths are untested**.
A gap at lines 88-101 might be the error handler for 4xx responses; lines 201-230 might be
the Kafka publish path. The line numbers are what turn "partially tested" into a concrete
Gap B finding.

For **BRANCH GAPS**: read the branch pairs (`from_line→to_line`). The `from_line` is the
conditional; `to_line` is the branch destination that was never reached. Common pattern:
`45→48` means the `if` at line 45 always evaluated True — the `else` at 48 was never hit.

Do **not** file a Gap A for modules in the FULL or BRANCH GAPS sections, even if no
`test_<module>.py` exists by name — coverage is the authority, not filenames.

---

## Step 2 — Assess Test Quality (Gap B Detection)

Use the coverage output from Step 1 to focus this analysis. For each PARTIAL module,
read the source lines identified as missing, then read the corresponding test file(s)
to understand why those lines are not reached.

For FULL-covered modules, still scan the test file for shallow assertion patterns —
high line coverage does not mean the assertions are meaningful.

Do this for every test file — not just a sample. This is an audit, not a spot check.

For each test file, answer:

### 2a. Assertion strength

Scan for weak assertion patterns: `assert result is not None`, `assert len(result) > 0`, `assert True`, `assert response.status == 200` (when mock was configured to return 200). Also flag tautologies where the expected value is computed by calling the same function under test.

### 2b. Side effects verified

For any test of code that:
- Publishes a Kafka message → assert `producer.send` or `producer.produce` was called with the right topic/payload
- Sends to SQS → assert `sqs_client.send_message` was called with the right QueueUrl and body
- Writes to S3 → assert `s3_client.put_object` was called
- Increments a metric → assert the metrics mock was called with the right name/value

If the code does one of these things and the test has no such assertion, flag it as Gap B.

### 2c. Error paths

For each test class/file, check whether it tests failure scenarios:
- API returns 4xx or 5xx (vendor API errors)
- SQS `send_message` raises `ClientError`
- Schema validation fails (`ValidationError`, `AvroError`)
- Empty or malformed input
- Rate limiting / retry exhaustion

If a test file has **zero** tests for failure paths, flag it.

### 2d. Mock depth

Flag tests where every significant dependency is patched out, leaving no real logic running. Red flag: 3+ `@patch` decorators on a single test combined with only `assert True` or a trivially passing assertion.

### 2e. Coverage-named files

Files named `test_*_coverage.py` deserve extra scrutiny. Read each one and ask:
- Does each test assert a **specific outcome** or just that the code executed?
- Could these tests pass even if the logic was wrong?

---

## Step 3 — Identify High-Value Missing Scenarios

Beyond file-level gaps, look for missing **behavioural scenarios** across the stack.
These are scenarios that matter for correctness but are often skipped:

### SQS / messaging layer
- Message dropped when SQS `send_message` fails (is it retried? logged? DLQ'd?)
- DLQ routing triggers when primary queue fails
- Message deduplication (duplicate message ID arrives — what happens?)
- Oversized message (SQS 256 KB limit)

### Vendor API / poller
- Vendor API returns empty page (should poller stop or retry?)
- Vendor returns partial data (missing required field)
- Rate limit hit mid-pagination (does backoff apply? does it resume from checkpoint?)
- Poller with zero tenants configured

### Processor / Avro
- Avro schema mismatch (producer sends v2 field, consumer expects v1)
- Record with all optional fields absent
- Null vs. missing field distinction in Avro

### Webhook listener
- Webhook signature validation failure (Catapult HMAC)
- Payload larger than expected
- Concurrent webhook delivery (same org, overlapping events)
- Misconfigured tenant (org ID in payload has no matching config)

### Multi-tenancy
- Tenant A's data cannot reach Tenant B's queue (routing isolation)
- Tenant added/removed mid-flight

For each scenario: check whether a test covers it. If not, it's a Gap A or Gap B candidate.

---

## Step 4 — Produce the Gap Report

Output a structured report in this format:

```markdown
# Test Gap Report — ingestion/
Generated: YYYY-MM-DD

## Summary
- Modules scanned: N
- Modules with no tests (Gap A): N
- Test files with shallow/tautological tests (Gap B): N
- Missing behavioural scenarios flagged: N

---

## 🔴 Gap A — No Tests At All

| Module | Why it matters | Suggested test |
|--------|---------------|----------------|
| platform_ingestion/backfill/state_machine.py | Controls retry/skip logic for backfill jobs | Test state transitions: pending→running→done, pending→running→failed→retry |
| ... | ... | ... |

---

## 🟡 Gap B — Tests Exist But Are Shallow

### test_processor_reverse_etl_coverage.py
**Problems found:**
- [ ] `test_dynamo_local_schema_serializer` only asserts `is not None` — does not verify schema fields or Avro encoding
- [ ] No test for what happens when Postgres `reverse_etl` write fails mid-batch
- [ ] All Kafka interactions are mocked but `produce()` call args are never asserted

**Recommended additions:**
1. Assert `producer.send()` called with correct topic name and payload shape
2. Add `test_write_batch_partial_failure` — simulate Postgres error mid-batch, assert partial writes are rolled back / logged

### test_webhook_listener_coverage.py
...

---

## 🟡 Gap B — Missing Behavioural Scenarios

| Scenario | Risk if untested | Location to add test |
|----------|-----------------|---------------------|
| Webhook HMAC validation failure | Unauthenticated payloads accepted in prod | test_webhook_listener_base.py |
| Poller with zero tenants | Silent no-op vs. error — unclear | test_base_sqs_poller.py |
| ... | ... | ... |

---

## Recommended Next Steps

Prioritised by blast radius if wrong:

1. **[Critical]** Add HMAC validation test — authentication bypass has production impact
2. **[High]** Add DLQ routing test for SQS failure — currently no test proves messages aren't lost
3. **[Medium]** Strengthen `test_*_coverage.py` files — replace `is not None` assertions with schema/value assertions
4. **[Low]** Add poller zero-tenant test — defensive but low blast radius
```

---

## Step 5 — Optional: Create Linear Tickets

If Cecil asks to create tickets from the report:

For each 🔴 Gap A item:
```
mcp__linear-server__save_issue(
  title="test: add tests for {module}",
  description="Gap A identified in test-gap-scan. {why_it_matters}. Suggested test: {suggested_test}",
  teamId=...,
  labelIds=["testing"]
)
```

For each 🟡 Gap B item (group by file, one ticket per file):
```
mcp__linear-server__save_issue(
  title="test: strengthen tests in {test_file}",
  description="Gap B — shallow assertions identified. Problems:\n{problems}\n\nRecommended additions:\n{recommendations}",
  ...
)
```

Ask Cecil before creating tickets. Don't auto-create.

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
