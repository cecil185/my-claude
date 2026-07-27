# Smell Catalog

Work through this checklist during Phase 2. For each smell found, record: location
(`file:line`), a one-line description, and severity.

**Severity:**
- **Major** — actively hurts correctness, testability, or debuggability (fix now)
- **Minor** — hurts readability or maintainability (fix now if small, ticket if large)
- **Defer** — valid smell but requires structural change beyond this skill's scope (create ticket)

## Contents

- [Size](#size)
- [Naming](#naming)
- [Duplication](#duplication)
- [Responsibility](#responsibility)
- [Conditionals](#conditionals)
- [Data](#data)
- [Comments](#comments)
- [Testability](#testability)
- [Debuggability](#debuggability)
- [Async (Python/aiohttp)](#async-pythonaiohttp)

---

## Size

- [ ] **Long function** — >20 lines of logic (not counting docstring/type hints)
  - Fix: Extract helper functions, each doing one thing
- [ ] **Large class** — >300 lines or >10 public methods
  - Severity: Defer if full extraction needed; Minor if one method can move out
- [ ] **Long parameter list** — function takes >3 parameters
  - Fix: Introduce `dataclass`/`TypedDict` parameter object; use keyword-only args (`*`)

## Naming

- [ ] **Vague names** — `data`, `result`, `temp`, `obj`, `val`, `x`, `process_stuff`
  - Fix: Name reveals intent — `athlete_records`, `webhook_secret`, `retry_count`
- [ ] **Misleading names** — name contradicts actual behavior
  - Fix: Rename to match behavior (check all call sites)
- [ ] **Unexplained abbreviations** — `cfg`, `mgr`, `proc`, `svc`
  - Fix: Spell it out unless domain-standard (`id`, `url`, `api`, `env`)

## Duplication

- [ ] **Duplicated logic** — same conditional, transformation, or pattern in 2+ places
  - Fix: Extract function, move to shared module
- [ ] **Magic numbers/strings** — unexplained literals inline
  - Fix: Named constant at module level or in a config dataclass
- [ ] **Copy-paste drift** — near-identical blocks that diverge subtly
  - Fix: Parameterize the difference; one function, different inputs

## Responsibility

- [ ] **Does multiple things** — function name needs "and" to describe it
  - Fix: Split into two functions, each with one job
- [ ] **Feature envy** — function operates mostly on another object's data
  - Fix: Move it to that object, or extract a collaborator
- [ ] **God class** — class coordinates everything, has no clear boundary
  - Severity: Defer — create a ticket for proper extraction
- [ ] **Shotgun surgery** — one business change touches many unrelated files
  - Severity: Defer — consolidation belongs in a design ticket

## Conditionals

- [ ] **Deep nesting** — `if/else` or `try/except` beyond 2 levels
  - Fix: Guard clauses (early returns), extracted helper, `match`/`case`
- [ ] **Negative conditions** — `if not is_invalid` instead of `if is_valid`
  - Fix: Invert the boolean and rename
- [ ] **Type-switching** — `if isinstance(x, A): ... elif isinstance(x, B):`
  - Fix: Polymorphism, `Protocol`, or dispatch dict
- [ ] **Scattered null guards** — `if x is None` repeated throughout caller code
  - Fix: Handle `None` at the boundary; return early at entry point

## Data

- [ ] **Primitive obsession** — passing bare strings where a domain type fits
  - Example: `"stg"` passed everywhere → introduce `Env` enum
  - Fix: Typed wrapper, `Enum`, or `dataclass`
- [ ] **Data clumps** — same 3+ variables travel together through multiple functions
  - Fix: Group into a `dataclass`
- [ ] **Mutable default args** — `def f(items=[])` or `def f(cfg={})`
  - Fix: `def f(items: list | None = None): items = items or []`

## Comments

- [ ] **Comment explains what** — comment restates what the code does
  - Fix: Delete it; rename the function/variable so it's self-evident
- [ ] **Dead code commented out** — `# result = old_logic()`
  - Fix: Delete it (git history preserves it)
- [ ] **Undocumented TODO** — `# TODO: fix this someday`
  - Fix: Create a Linear ticket, replace with `# TODO: DP-XXX` or delete

## Testability

- [ ] **Hard-wired dependencies** — function instantiates its own DB client, HTTP session, clock
  - Fix: Inject via constructor or parameter
- [ ] **Computation mixed with I/O** — same function calculates and writes
  - Fix: Separate pure logic from I/O; test logic independently
- [ ] **Non-determinism inside logic** — `datetime.now()`, `random.random()`, `uuid4()` inline
  - Fix: Inject via parameter or a clock/id factory passed at construction
- [ ] **Untestable private logic** — complex work buried in `_method` with no seam
  - Fix: Extract to module-level function; test it directly

## Debuggability

- [ ] **Silent failures** — `except Exception: pass` or bare `except Exception: return None`
  - Fix: `logger.error(f"...: {e}")` + re-raise or return a typed error sentinel
- [ ] **Context-free logs** — `logger.error("Failed")` with no what/where/why
  - Fix: Include entity identifiers — `logger.error(f"Failed to sync {table}: {e}")`
- [ ] **Wrong log level** — expected failures logged as `ERROR`, trace noise as `INFO`
  - Fix: `DEBUG` per-item trace, `INFO` cycle summaries, `WARNING` recoverable, `ERROR` unrecoverable
- [ ] **Opaque exception messages** — `raise ValueError("invalid")`
  - Fix: `raise ValueError(f"Invalid env: {env!r}")`

## Async (Python/aiohttp)

- [ ] **Missing `await`** — coroutine called without `await` (silent no-op, returns coroutine object)
  - Fix: Add `await`; enable `asyncio` debug mode to catch these
- [ ] **Blocking I/O in async context** — `time.sleep()`, `open()`, sync DB calls inside `async def`
  - Fix: `await asyncio.sleep()`, `aiofiles`, async DB driver
- [ ] **Async context manager skipped** — `session.get(url)` without `async with`
  - Fix: Always `async with session.get(...) as response:`
- [ ] **Fire-and-forget without error handling** — `asyncio.create_task(fn())` with no `.add_done_callback`
  - Fix: Capture the task, await it, or add a done callback that logs failures
