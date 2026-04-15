---
name: refactor
description: >-
  Refactor code to match project conventions and clean code principles.
  Use when asked to clean up, improve, or refactor existing code — identifies
  smells, improves structure, names, testability, debuggability, and maintainability
  without changing behavior.
model: claude-opus-4-6
effort: high
---

# Code Refactor

Improve code structure without changing behavior. Tests prove behavior is unchanged.

**The contract:** Refactoring = structure changes only. Behavior is frozen. If you need to change behavior, that is a feature — stop and use `Skill(adlc:test-driven-development)`.

**The safety net:** Tests are your proof that behavior didn't change. No tests = no safety net = do not refactor until you have them.

---

## Phase 1 — Scope and Read

### Define scope

If the target is vague ("clean up this module"), ask: which file(s)? Large structural changes (extract class, move module) belong in a ticket — this skill handles surgical, in-place improvements.

**Stop and create a Linear ticket if:**
- The smell requires moving code across more than 2 files
- The class is a god class requiring full extraction (>1 day effort)
- You find yourself wanting to redesign an interface

For everything else: proceed.

### Read the code

Read every file in scope — including the corresponding test files. Do not propose changes based on filenames or signatures alone.

### Check test coverage

Before scanning for smells, check whether the code under refactor has tests:

```bash
just test   # Must be green — red tests mean stop entirely
```

If the code has **no test coverage**:
1. Switch to `Skill(adlc:test-driven-development)` 
2. Write tests for the existing behavior (characterization tests)
3. Watch them pass — they document what the code does now
4. Return here once green

If coverage exists but is thin, note the gaps. You can refactor safely within covered behavior; flag uncovered paths for TDD follow-up.

---

## Phase 2 — Smell Scan

Work through this checklist. For each smell found, record: location (`file:line`), a one-line description, and severity.

**Severity:**
- **Major** — actively hurts correctness, testability, or debuggability (fix now)
- **Minor** — hurts readability or maintainability (fix now if small, ticket if large)
- **Defer** — valid smell but requires structural change beyond this skill's scope (create ticket)

### Size

- [ ] **Long function** — >20 lines of logic (not counting docstring/type hints)
  - Fix: Extract helper functions, each doing one thing
- [ ] **Large class** — >300 lines or >10 public methods
  - Severity: Defer if full extraction needed; Minor if one method can move out
- [ ] **Long parameter list** — function takes >3 parameters
  - Fix: Introduce `dataclass`/`TypedDict` parameter object; use keyword-only args (`*`)

### Naming

- [ ] **Vague names** — `data`, `result`, `temp`, `obj`, `val`, `x`, `process_stuff`
  - Fix: Name reveals intent — `athlete_records`, `webhook_secret`, `retry_count`
- [ ] **Misleading names** — name contradicts actual behavior
  - Fix: Rename to match behavior (check all call sites)
- [ ] **Unexplained abbreviations** — `cfg`, `mgr`, `proc`, `svc`
  - Fix: Spell it out unless domain-standard (`id`, `url`, `api`, `env`)

### Duplication

- [ ] **Duplicated logic** — same conditional, transformation, or pattern in 2+ places
  - Fix: Extract function, move to shared module
- [ ] **Magic numbers/strings** — unexplained literals inline
  - Fix: Named constant at module level or in a config dataclass
- [ ] **Copy-paste drift** — near-identical blocks that diverge subtly
  - Fix: Parameterize the difference; one function, different inputs

### Responsibility

- [ ] **Does multiple things** — function name needs "and" to describe it
  - Fix: Split into two functions, each with one job
- [ ] **Feature envy** — function operates mostly on another object's data
  - Fix: Move it to that object, or extract a collaborator
- [ ] **God class** — class coordinates everything, has no clear boundary
  - Severity: Defer — create a ticket for proper extraction
- [ ] **Shotgun surgery** — one business change touches many unrelated files
  - Severity: Defer — consolidation belongs in a design ticket

### Conditionals

- [ ] **Deep nesting** — `if/else` or `try/except` beyond 2 levels
  - Fix: Guard clauses (early returns), extracted helper, `match`/`case`
- [ ] **Negative conditions** — `if not is_invalid` instead of `if is_valid`
  - Fix: Invert the boolean and rename
- [ ] **Type-switching** — `if isinstance(x, A): ... elif isinstance(x, B):`
  - Fix: Polymorphism, `Protocol`, or dispatch dict
- [ ] **Scattered null guards** — `if x is None` repeated throughout caller code
  - Fix: Handle `None` at the boundary; return early at entry point

### Data

- [ ] **Primitive obsession** — passing bare strings where a domain type fits
  - Example: `"stg"` passed everywhere → introduce `Env` enum
  - Fix: Typed wrapper, `Enum`, or `dataclass`
- [ ] **Data clumps** — same 3+ variables travel together through multiple functions
  - Fix: Group into a `dataclass`
- [ ] **Mutable default args** — `def f(items=[])` or `def f(cfg={})`
  - Fix: `def f(items: list | None = None): items = items or []`

### Comments

- [ ] **Comment explains what** — comment restates what the code does
  - Fix: Delete it; rename the function/variable so it's self-evident
- [ ] **Dead code commented out** — `# result = old_logic()`
  - Fix: Delete it (git history preserves it)
- [ ] **Undocumented TODO** — `# TODO: fix this someday`
  - Fix: Create a Linear ticket, replace with `# TODO: DP-XXX` or delete

### Testability

- [ ] **Hard-wired dependencies** — function instantiates its own DB client, HTTP session, clock
  - Fix: Inject via constructor or parameter
- [ ] **Computation mixed with I/O** — same function calculates and writes
  - Fix: Separate pure logic from I/O; test logic independently
- [ ] **Non-determinism inside logic** — `datetime.now()`, `random.random()`, `uuid4()` inline
  - Fix: Inject via parameter or a clock/id factory passed at construction
- [ ] **Untestable private logic** — complex work buried in `_method` with no seam
  - Fix: Extract to module-level function; test it directly

### Debuggability

- [ ] **Silent failures** — `except Exception: pass` or bare `except Exception: return None`
  - Fix: `logger.error(f"...: {e}")` + re-raise or return a typed error sentinel
- [ ] **Context-free logs** — `logger.error("Failed")` with no what/where/why
  - Fix: Include entity identifiers — `logger.error(f"Failed to sync {table}: {e}")`
- [ ] **Wrong log level** — expected failures logged as `ERROR`, trace noise as `INFO`
  - Fix: `DEBUG` per-item trace, `INFO` cycle summaries, `WARNING` recoverable, `ERROR` unrecoverable
- [ ] **Opaque exception messages** — `raise ValueError("invalid")`
  - Fix: `raise ValueError(f"Invalid env: {env!r}")`

### Async (Python/aiohttp specific)

- [ ] **Missing `await`** — coroutine called without `await` (silent no-op, returns coroutine object)
  - Fix: Add `await`; enable `asyncio` debug mode to catch these
- [ ] **Blocking I/O in async context** — `time.sleep()`, `open()`, sync DB calls inside `async def`
  - Fix: `await asyncio.sleep()`, `aiofiles`, async DB driver
- [ ] **Async context manager skipped** — `session.get(url)` without `async with`
  - Fix: Always `async with session.get(...) as response:`
- [ ] **Fire-and-forget without error handling** — `asyncio.create_task(fn())` with no `.add_done_callback`
  - Fix: Capture the task, await it, or add a done callback that logs failures

---

## Phase 3 — Plan

Before touching any code, produce the **Refactor Report** (see Output Format below).

Get implicit or explicit sign-off before proceeding if:
- More than 3 files will change
- Any smell is marked Defer (confirm it should become a ticket, not be fixed now)
- The change requires updating tests

---

## Phase 4 — Execute (One Change at a Time)

**For each smell, in order (safest first):**

1. Confirm `just test` is green
2. Make **one** structural change
3. Run `just test` — must stay green
4. If green: commit or move to next smell
5. If red: revert the single file (`git checkout -- path/to/file.py`) and try a smaller step

**Safest-to-riskiest order:**

| Risk | Change |
|------|--------|
| Lowest | Rename variable/function/class |
| Low | Extract constant |
| Low | Delete dead code |
| Medium | Extract function (same file) |
| Medium | Reorder/restructure within file |
| Higher | Move function to another file (updates imports) |
| Highest | Extract class or introduce new abstraction |

Never make two changes simultaneously. Never refactor and add behavior in the same step.

---

## Phase 5 — Verify

```bash
just ci   # Must pass before declaring done
```

- [ ] All tests pass (same count as before)
- [ ] No new `# type: ignore` introduced
- [ ] No commented-out code added
- [ ] No behavior changed — only structure
- [ ] Every Major smell from Phase 2 is resolved
- [ ] Every Defer smell has a Linear ticket

---

## What NOT to Do

- Do not add features during a refactor — separate commits
- Do not change test assertions to make a refactor pass
- Do not delete or modify existing tests without explicit user approval per file
- Do not add docstrings or comments to code you didn't change
- Do not extract a one-use helper unless it measurably clarifies the caller
- Do not introduce abstractions for hypothetical future cases (YAGNI)
- Do not refactor when tests are red — fix the tests first or stop

---

## Output Format

**Always report before making any changes.** Get confirmation if scope is large.

```
## Refactor Report: [file or module]

### Coverage
[Tests found: yes/no. Gaps: describe any uncovered paths.]

### Smells Found

| # | Severity | Category | Location | Description |
|---|----------|----------|----------|-------------|
| 1 | Major | Naming | `file.py:42` | `data` parameter — reveals no intent |
| 2 | Minor | Conditionals | `file.py:88` | 3-level nesting in `process_event` |
| 3 | Defer | Responsibility | `client.py` | God class — 15 methods across 3 concerns |

### Proposed Changes (in execution order)
1. Rename `data` → `athlete_payload` at `file.py:42` and all callers
2. Extract guard clause in `process_event` at `file.py:88`

### Deferred (ticket needed)
- God class in `client.py` — suggest DP-XXX to extract `WebhookFilterer` and `WebhookLifecycle`

### Changes NOT Made
[Anything observed but intentionally skipped — with reason]
```
