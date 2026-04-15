---
name: adlc-write-tests
description: >-
  Write failing acceptance and unit tests from a Linear issue's Specification and
  task breakdown BEFORE any implementation begins. Creates the feature-level RED phase.
  Run after /adlc:breakdown and before /adlc:execute to make the full ADLC workflow
  truly test-driven from the start.
when_to_use: >-
  After /adlc:breakdown (phases and tasks exist in Linear) and before /adlc:execute —
  when you want a top-down TDD approach where all tests exist and are confirmed failing
  before the first line of implementation is written.
version: 1.1.0
---

# Write Tests First (ADLC TDD Pre-Execution)

Write ALL failing tests for a feature or phase from its Specification and task breakdown
**before** any implementation begins. This creates a feature-level RED baseline that
`/adlc:execute` then makes GREEN.

**Core principle:** If you watch every test fail before implementing, you know every test
tests the right thing.

**Workflow position:**

```
/adlc:refine → /adlc:plan → /adlc:breakdown → /adlc-write-tests → /adlc:execute
```

**What this adds to the workflow:** The existing ADLC flow writes tests per-task during
execution. This skill moves test authorship *upstream* — acceptance and unit tests are
written from the Specification and task descriptions, confirmed failing, and committed
as the definition of done. Execution then fills in implementation to make them pass,
not to decide what to test.

---

## Usage

```bash
/adlc-write-tests ISSUE-ID              # Write tests for all pending phases of a feature
/adlc-write-tests ISSUE-ID --phase      # Write tests for this single phase sub-issue only
/adlc-write-tests ISSUE-ID --dry-run    # Show what tests would be written without writing
```

---

## The Process

### Step 1: Load Issue Context

**Load the target issue:**

```python
issue = mcp__linear-server__get_issue(id=issue_id)
```

**Determine scope:**

```python
sub_issues = mcp__linear-server__list_issues(parentId=issue.id)

if issue.parent:
    # This is a phase sub-issue
    if "--phase" in flags:
        # Explicit phase scope: write tests for this one phase only
        phases = [issue]
    else:
        # Phase passed without --phase: warn and treat as phase scope
        print("⚠️  Issue has a parent — treating as phase. Use --phase to be explicit.")
        phases = [issue]
    parent = mcp__linear-server__get_issue(id=issue.parent.id)

elif len(sub_issues) > 0:
    if "--phase" in flags:
        ERROR: "--phase flag requires a phase sub-issue ID, not a feature ID. Run without --phase to write tests for all phases."
        STOP
    # Feature scope: write tests for all pending phases
    phases = [s for s in sub_issues if s.state not in ("Done", "Completed", "In Review")]
    parent = issue

else:
    if "--phase" in flags:
        ERROR: "--phase flag requires a phase sub-issue ID. This issue has no parent."
        STOP
    # Standalone: treat as single scope
    phases = [issue]
    parent = issue
```

**Verify prerequisites:**

```python
if "## Specification" not in parent.description:
    ERROR: "No Specification found. Run /adlc:refine {parent.id} first."
    STOP

if len(phases) == 0:
    print("ℹ️  No pending phases found — all phases may already be complete or in review.")
    STOP
```

**Verify branch safety before proceeding:**

```bash
# Confirm we are NOT on main/master before writing any test files
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    ERROR: "On protected branch '$current_branch'. Checkout a feature branch first."
    STOP
fi
```

---

### Step 2: Discover Codebase Test Patterns

Before writing any tests, understand the repo's conventions so tests fit naturally.
Use `Skill(adlc:writing-tests)` as the reference for AAA structure, naming conventions,
test levels, and mocking guidelines. Here, discover the project-specific conventions:

**Find representative test files:**

```bash
rg --files -g "*.test.ts" -g "*.test.tsx" -g "*.spec.ts" -g "test_*.py" -g "*_test.go" | head -10
```

Read 1–2 of the most relevant test files to extract:
- Import style and path convention
- Assertion library in use
- Test file location (colocated vs `__tests__/` vs `tests/`)
- Common fixtures or factory helpers used

**Check available test commands:**

```bash
just --list 2>/dev/null | grep -E "test|spec" || echo "No justfile"
```

Record the run-single-file command — you will use it in Step 5.

---

### Step 3: Derive Tests From Specification and Breakdown

For each phase in scope, derive two categories of tests.

#### 3a. Acceptance Tests (from phase acceptance criteria)

Each acceptance criterion in the phase description becomes one test.

**Extract from the phase sub-issue description** — look for:
- An `## Acceptance Criteria` or `## Acceptance Tests` section
- `- [ ] Given/When/Then` items
- Sentences with `should`, `must`, `can`, `returns`, or `rejects`

**Map each criterion to a test:**

```
Criterion: "User can register with valid email and password"
→ Test name: "user registration with valid email and password creates account"
→ Test level: Integration (hits service/API layer)
→ Key assertion: result.id is defined, result.email matches input

Criterion: "Registration fails if email is already taken"
→ Test name: "user registration with duplicate email raises validation error"
→ Test level: Integration
→ Key assertion: raises/rejects with the duplicate-email error

Criterion: "Password must be at least 8 characters"
→ Test name: "user registration with short password raises validation error"
→ Test level: Unit (pure validation logic)
→ Key assertion: raises/rejects with the password-length error
```

If a phase has no acceptance criteria section, fall back to deriving tests from its
task descriptions only, and warn:

```
⚠️  Phase PHASE-ID has no acceptance criteria. Deriving from tasks only.
    Consider re-running /adlc:breakdown to add explicit acceptance criteria.
```

#### 3b. Unit Tests (from task descriptions)

Each task in the phase's checklist contributes 1–3 unit tests covering its public behavior.

**Per-task mapping:**

```
Task: "Implement UserService.register(email, password)"
→ Test 1: "register with valid inputs returns user with generated id"
→ Test 2: "register with invalid email raises ValidationError"
→ Test 3: "register with duplicate email raises ConflictError"

Task: "Add POST /api/users endpoint"
→ Test 1: "POST /api/users with valid body returns 201 with user id"
→ Test 2: "POST /api/users with missing email returns 400"

Task: "Add users table migration"
→ No unit test needed — covered by integration tests above
```

**Skip tasks that produce no directly testable unit:**
- Database migrations
- Configuration changes
- Dependency installs
- Pure UI styling (no behavior)

---

### Step 4: Write the Failing Tests

**Consult `Skill(adlc:writing-tests)`** for AAA structure, test naming, choosing the right
test level, and mocking guidelines. The following rules are specific to this skill's
context (writing tests that don't yet have an implementation):

**Organize by module, not by phase.** Group acceptance tests and unit tests for the same
module into one test file. Acceptance tests for a service and unit tests for that service
belong together.

**Write tests that fail because the implementation doesn't exist yet:**

Import the function or class from the path where it will live once implemented. The import
itself will fail (`ImportError`, `ModuleNotFoundError`, compile error) — this is acceptable
RED. The distinction:

- **Acceptable**: `import { registerUser } from '../services/user.service'` where the file
  doesn't exist yet → fails because the module is not yet implemented
- **Fix before committing**: `import { registerUser } from '../service/users'` where you
  have the path wrong → fix the path so it points to the correct future location

```typescript
// TypeScript example
import { registerUser } from '../services/user.service';  // will fail until implemented

test('user registration with valid email and password creates account', async () => {
  const result = await registerUser({ email: 'alice@test.com', password: 'secure123' });
  expect(result.id).toBeDefined();
  expect(result.email).toBe('alice@test.com');
});
```

```python
# Python example
from app.services.user_service import UserService  # will fail until implemented

def test_register_with_valid_inputs_returns_user_with_id(db_session):
    service = UserService(db_session)
    user = service.register(email='alice@test.com', password='secure123')
    assert user.id is not None
    assert user.email == 'alice@test.com'
```

**Never use `skip`, `xit`, `pytest.mark.skip`, or `t.Skip()`** — a skipped test does not
prove RED. The test must run and fail.

**Never write vacuous bodies:**

```typescript
// ❌ — proves nothing
test('register user', () => { expect(true).toBe(true); });

// ✅ — fails until registerUser is implemented
test('register with valid email creates account', async () => {
  const result = await registerUser({ email: 'alice@test.com', password: 'secure123' });
  expect(result.id).toBeDefined();
});
```

---

### Step 5: Verify RED — All Tests Must Fail

Run each test file written in Step 4:

```bash
just test path/to/test-file-1
just test path/to/test-file-2
```

**Expected state:** Every test fails. Zero tests pass. Zero tests are skipped.

For each test, confirm it fails for the expected reason — missing implementation or import,
not a syntax error or wrong path. See `Skill(adlc:test-driven-development)` for the full
RED verification protocol.

**If a test passes immediately:**
```
⚠️  Test passes without implementation: "[test name]"
  (a) The behavior is already implemented — verify the function exists
  (b) The test is vacuous (asserts nothing real) — fix the assertion
```
Investigate and fix before proceeding. Do not commit a passing test as a RED baseline.

**If a test errors due to a bad import path:**
Fix the import path so it points to where the module will live once implemented,
then re-run.

---

### Step 6: Commit the Failing Tests

**Stage test files only.** Do not stage any implementation files:

```bash
git add path/to/test-file-1
git add path/to/test-file-2
git status  # verify: only test files staged
```

**Commit:**

```bash
git commit -m "$(cat <<'EOF'
test(ISSUE-ID): write failing acceptance and unit tests [RED]

Pre-execution TDD baseline. All N tests confirmed failing before implementation.

Tests written:
- path/to/test-file-1 (acceptance: X tests)
- path/to/test-file-2 (unit: Y tests)

Acceptance criteria covered:
- [criterion 1]
- [criterion 2]
EOF
)"
```

---

### Step 7: Report and Hand Off

```markdown
## Tests Written: ISSUE-ID

**Phases covered:** N
**Tests written:** X total (Y acceptance, Z unit)
**All confirmed failing:** ✓

### Test Inventory

#### Phase 1: [Phase Title]
| File | Tests | Type |
|------|-------|------|
| src/services/user.service.test.ts | 3 | Unit + Acceptance |
| src/routes/user.routes.test.ts | 2 | Integration |

### RED Verification
All N tests run and fail (0 passing, 0 skipped).
Failure reason: missing implementation at import path.

### Commit
[SHA] — test(ISSUE-ID): write failing acceptance and unit tests [RED]

---

These tests are the acceptance contract for ISSUE-ID.
Run /adlc:execute ISSUE-ID to implement against them.
```

Offer to chain:

```
Run /adlc:execute ISSUE-ID now? [Y/n]
```

If yes: `Skill(adlc:execute)`

---

## Dry Run Mode

With `--dry-run`, print what would be written without creating any files:

```markdown
## Dry Run: Tests That Would Be Written — ISSUE-ID

### Phase 1: Register a user
**Acceptance tests:**
- [integration] src/services/user.service.test.ts
  - "user registration with valid email and password creates account"
  - "user registration with duplicate email raises validation error"

**Unit tests (from tasks):**
- Task: "Implement UserService.register()"
  - [unit] src/services/user.service.test.ts
    - "register with valid inputs returns user with generated id"
    - "register with duplicate email raises ConflictError"

Total: 4 tests across 1 file
```

---

## Error Cases

### Test File Already Exists

```
ℹ️  src/services/user.service.test.ts already exists (N tests).
Checking for overlap...
  - 2 existing tests already cover acceptance criteria → skip
  - 1 new test to add: "register with short password raises ValidationError"
Appending only.
```

Do not overwrite existing tests. Append new tests only.

### All Tests Pass (Already Implemented)

```
⚠️  All tests pass immediately — implementation may already exist.

Phase PHASE-ID: "Register a user" — 3/3 tests pass

Options:
1. Mark phase as Done in Linear and skip
2. Add tests for untested edge cases
3. Proceed to /adlc:execute (it will detect the phase is complete)
```

---

## Checklist

- [ ] Loaded issue and all pending phases from Linear
- [ ] Confirmed on a feature branch (not main/master)
- [ ] Discovered test patterns from existing files
- [ ] Extracted acceptance criteria from each phase description
- [ ] Derived unit tests from each task description
- [ ] Wrote test files following existing project conventions
- [ ] All tests run (no broken syntax, no wrong import paths)
- [ ] All tests FAIL (0 passing, 0 skipped)
- [ ] Each test fails because the implementation doesn't exist yet
- [ ] Only test files staged and committed
- [ ] Reported test inventory with file paths and counts
- [ ] Offered to chain to `/adlc:execute`

---

## Remember

- **Tests must fail, not skip** — skipped tests are not RED, they're invisible
- **Correct path, missing module** — import from where the module WILL live, not where it exists now
- **Acceptance tests from criteria, unit tests from tasks** — different sources, different levels
- **Append, don't overwrite** — existing tests already hold their own RED baseline
- **Dry run first on large features** — use `--dry-run` to review scope before writing
