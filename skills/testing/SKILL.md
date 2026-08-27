---
name: testing
description: Execute and validate unit, integration, API, regression, and end-to-end tests for an approved implementation. Evidence-based — never claim a test passed unless it was executed and the result observed. Use after implementation and before code review/validation. Trigger: /testing
---

# Testing Skill

## Purpose

Validate that the implementation satisfies the approved specification, acceptance criteria,
business rules, edge cases, and existing system behavior.

Testing must be evidence-based.

**Never claim a test passed unless it was actually executed and the result was observed.**

## Where it fits

```
/ticket-research → research.md          TC-n sized here
/feature-docs    → test-cases.csv       every case enumerated here
/tsc-ticket      → implementation + ticket-local test files written here
/testing         → EXECUTE them, record evidence, write test-report.md   ← you are here
                   then code review / validation
```

Output: **one file**, `docs/<TICKET-ID>-<slug>/test-report.md`.

`/testing` executes and reports. It does **not** enumerate cases — `/feature-docs` owns that —
and it does **not** change implementation. If the implementation is wrong, it says so and hands
back.

**Relationship to `/tsc-ticket` phase 4.** Phase 4 is a three-command smoke check. `/testing` is
the full validation pass with traceability and a recorded report. When both apply, `/testing`
supersedes phase 4 — do not run a reduced version and call it done.

---

## Preconditions

Before testing:

* Research must be complete.
* Specification must be available.
* Implementation plan must be available.
* Implementation must be complete.
* Relevant code changes must be present.
* Required dependencies must be available.

Read:

```text
Research        docs/<TICKET-ID>-<slug>/research.md
Spec            docs/<TICKET-ID>-<slug>/spec.md
Plan            docs/<TICKET-ID>-<slug>/plan.md
Test cases      docs/<TICKET-ID>-<slug>/test-cases.csv     ← the row list you are closing
Changed files   git status / git diff in each touched repo
Existing tests  the repo's own suite for the touched area
```

If a required input is missing, **report the blocker before testing**. Do not start and discover
it halfway.

---

## Testing Objectives

Verify:

1. Functional requirements
2. Business rules
3. Validation rules
4. Decision rules
5. Acceptance criteria
6. Edge cases
7. Error handling
8. Regression behavior
9. Integration behavior
10. Non-functional requirements where applicable

---

## Test Strategy — the pipeline

```text
TEST
 │
 ├── 1. Manual Testing        acceptance criteria a human must judge
 │                            (before or alongside the rest, per feature)
 ├── 2. Unit Testing          individual logic
 │
 ├── 3. Integration Testing   component boundaries + real test DB
 │                            → references/integration-testing.md
 ├── 4. Playwright            real browser / user journey
 │                            → references/ui-playwright.md
 ├── 5. Regression Testing    existing functionality still works
 │
 └── 6. Final Validation      PASS / FAIL / BLOCKED / PARTIAL
```

**Regression runs after Playwright, not before.** You want the full existing-behaviour sweep as
the last thing before the verdict, once every new path has been exercised.

**API testing is not a separate stage** — it is an integration boundary, covered inside stage 3
(`references/integration-testing.md` §6). It keeps its own `Test Summary` row in the report.

**Manual testing is not optional and not last.** Some acceptance criteria — is the error message
comprehensible, does the layout survive a real screen, does the flow work at speed — cannot be
automated. Run them when the feature is testable, and record the Environment block, or the result
does not count.

Use the smallest level that can prove the case. Do not add an E2E test when a deterministic
unit/integration test suffices — pushing cases up the pyramid produces a slow suite nobody runs
and a sheet that stays `⬜`.

---

## Requirement-to-Test Traceability

Every testable requirement should map to one or more test cases.

```text
FR-001 → TC-001, TC-002
BR-001 → TC-003
VR-001 → TC-004
AC-001 → TC-005
EC-001 → TC-006
```

**Use the ids that already exist.** `FR-n`, `BR-n`, `VR-n`, `DR-n`, `AC-n`, `EC-n` were minted in
`research.md` and carried into `spec.md`; `TC-n` rows live in `test-cases.csv`. Never renumber and
never invent a parallel scheme — the whole point of the earlier phases is that these ids are
citable here.

The traceability table in the report is what proves coverage. A requirement with no `TC` is either
untested or out of scope, and the report must say which.

---

## Test Case Design

Every important test case should define:

```text
TC-ID
Requirement
Objective
Preconditions
Input
Steps
Expected Result
Actual Result
Status
Evidence
```

Example:

```text
TC-003

Requirement:      BR-001
Objective:        Verify discounts above 20% require approval.
Preconditions:    Employee has valid discount permission.
Input:            Discount = 25%
Expected Result:  Manager approval is required.
Actual Result:    <record actual observed result>
Status:           PASS
Evidence:         <test output / assertion / log>
```

`Actual Result` and `Evidence` are **recorded, not predicted**. If they are empty, the status is
`NOT_RUN`, not `PASS`.

---

## Required Test Categories

### 1. Unit Tests

Test:

* Pure business logic
* Validators
* Decision rules
* Utility functions
* Service methods

Focus on deterministic behavior.

### 2. Integration Tests

Test:

* Service-to-service behavior
* Database interactions
* Workflow execution
* Event handling
* External integration boundaries

Verify real integration contracts where practical.

**Full 23-section procedure in `references/integration-testing.md`.** It covers boundary
identification (`INT-n`), dependency classification (`DEP-n`), the `INT-TC-n` case format,
database verification, transactions and rollback, idempotency, queue/DLQ, webhooks, cleanup and
the definition of done.

Four things from it that are load-bearing here:

- **There is no dedicated test database.** `ustage` Mongo and DynamoDB are **shared with other
  developers**, and there is no PostgreSQL anywhere in this stack. That makes cleanup mandatory,
  not best practice — `afterEach`, tagged records, and verify the cleanup rather than assume it.
- **Never prod.** `ls -l ~/TSC/order-management-service/.env.secrets` before every run — that
  symlink currently points at production from an un-reverted migration dry-run.
- **Some boundaries cannot be rolled back** — the Serverless OMS, Freshdesk/Flowcall tickets, Fynd
  batches, WebEngage events, and Gupshup SMS to a real phone. **Mock those**; assert the payload
  you would have sent.
- **Prefer the integration test that writes nothing.** Composing several real units catches this
  codebase's highest-value defect class — two paths deriving the same quantity differently — with
  no database and no cleanup. Go live-service only when the thing you must prove lives in the
  wiring.

### 3. API Tests

Test:

* Request validation
* Authentication
* Authorization
* Success responses
* Error responses
* HTTP status codes
* Response schema
* Backward compatibility

### 4. Regression Tests

Identify existing behavior that could be affected by the change.

Before declaring success:

```text
New behavior passes
+
Existing behavior still passes
```

Prefer existing regression suites over creating duplicate tests.

### 5. E2E / UI Tests — Playwright

Use E2E tests when the feature crosses important system boundaries:

```text
UI → API → Workflow → Database → External integration
```

Cover critical user journeys and acceptance criteria.

**Full detail in `references/ui-playwright.md`. Read it before running UI tests** — the situation
is not what it looks like.

`tsc-pos-frontend/playwright/flows/` holds **20 real Playwright specs** covering auth, customer
login, add-to-cart, coupons, quotation, pre-order summary and cash / Razorpay / PayU / bank
payment in split and non-split variants. **They have never been runnable** — `@playwright/test` is
installed in no repo, there is no `playwright.config.*` anywhere, and there is no test script.

| Verified | |
|---|---|
| spec files | 20 — **13** contain `test()`, **7** are pure composable blocks |
| discoverable once wired | **12 tests in 12 files** |
| Chromium | already cached |
| repo changes needed | **none** — `NODE_PATH` resolves it |

Run them with the templates, same ticket-local pattern as jest:

```bash
cd ~/TSC/docs/<TICKET-ID>-<slug>
./run-ui-tests.sh                 # all flows · --headed · --ui · or a filter
```

**Two defects to know about:**

- **`whole-sanity-checkout.spec.ts` cannot load** — it imports with an explicit `.ts` extension,
  which Playwright's loader rejects. It is excluded by the template config, and since it is the
  whole-journey test, that exclusion is the largest coverage gap. Fixing it is four import lines.
- **Twelve of thirteen tests are literally named `test`**, so `--grep` is useless and a failure
  line does not say what broke. Rename as you touch them; never add another `test('test', …)`.

**These are integration tests.** They need the app on `localhost:5173`, a reachable backend, and a
real Cognito user in the **ustage** pool. Missing any of those is an **ENVIRONMENT_BLOCKER** — mark
those rows `🔲`, never `❌`. Payment flows hit provider sandboxes: never run them against a
prod-pointing stack.

**Do not push a case up to Playwright because it is easier to write there.** A boundary rule
tested through a browser is slower, flakier and proves less than three lines of jest. The
level-by-case table is in the reference.

---

## Positive Tests

Verify expected valid behavior: valid input · authorized user · eligible discount · successful
approval · successful checkout.

## Negative Tests

Verify invalid or unauthorized behavior: invalid input · missing permission · unauthorized user ·
invalid state · rejected approval · missing dependency · unavailable service.

**Negative cases should outnumber positive ones.** Every guard in the implementation — every
`throw`, early return and validation branch — is a negative case, and `Expected Result` is the
specific error, not "fails".

## Edge Case Tests

Every `EC-*` item that is relevant and testable should be covered, and mapped:

```text
EC-001 → TC-010
EC-002 → TC-011
EC-003 → TC-012
EC-004 → TC-013
```

---

## Business Rule Tests

Business rules must be tested explicitly.

```text
BR-001

IF discount > 20%
THEN approval_required = true
```

Test at minimum:

```text
19%       below
20%       exactly at the boundary
20.01%    one unit above
21%       above
```

**Boundary values must be tested.** Boundary inclusivity is the thing that gets decided by
accident in code and argued about in production — assert the operator the rule actually specifies.

---

## Validation Rule Tests

For every `VR-*`, test:

```text
Valid value
Invalid value
Missing value
Boundary value
Unexpected value
```

Example — `VR-001`, employee must have discount permission:

```text
Permission = true
Permission = false
Permission missing
Permission service unavailable
```

---

## Acceptance Criteria Validation

Every acceptance criterion must have a clear verification method.

```text
AC-001
Employee can select eligible discount.

Verification:  UI E2E test
Covered by:    TC-001
```

If an acceptance criterion cannot currently be tested:

```text
Mark:             NOT_TESTABLE
Explain:          why
Required action:  what must change
```

**Do not silently ignore it.** An `AC` with no row reads as passed.

---

## Test Data

Use an appropriate strategy: fixtures · factories · seed data · mocks · stubs · test containers.

**Do not use production data.** Avoid brittle hard-coded data when reusable fixtures already
exist.

---

## Mocking Policy

Mock only external or non-deterministic dependencies when appropriate.

Prefer real application logic for: business rules · validation · decision logic · internal
workflows.

**Do not over-mock the system to make tests pass.** A test that mocks the rule under test proves
nothing.

---

## Database Tests

When database behavior changes, verify:

* Migration succeeds
* Schema matches expectations
* Existing data remains valid
* Constraints work
* Rollback strategy where applicable
* Queries behave correctly

**Never modify production data while testing.**

---

## API Contract Tests

When an API changes, verify:

```text
Request · Authentication · Authorization · Validation
Response · Error contract · Backward compatibility
```

If an API contract changes intentionally, confirm the approved specification explicitly allows it.

---

## Integration Failure Tests

For external dependencies test:

```text
Timeout · 5xx · 4xx · Malformed response · Unavailable service
Retry behavior · Duplicate request · Idempotency
```

Only test behaviors that are relevant to the integration.

---

## Concurrency / Race Conditions

When the feature involves asynchronous or concurrent operations, consider:

```text
Duplicate requests · Concurrent updates · Webhook retries · Race conditions
Idempotency · Transaction boundaries · Event ordering
```

Create tests when the risk is material.

---

## Performance Tests

Run performance testing only when required by: specification · existing project standards ·
explicit acceptance criteria · known high-risk code paths.

**Measure actual behavior instead of making assumptions.**

---

## Security Tests

Where applicable verify: authentication · authorization · permission boundaries · input
validation · sensitive-data exposure · injection risks · access-control regressions.

**Never bypass security checks just to make a test pass.**

---

## Test Execution

Before execution:

```text
1. Identify relevant test commands.
2. Inspect package scripts.
3. Inspect existing CI configuration.
4. Inspect test configuration.
5. Determine the smallest required test set.
```

Then run:

```text
Targeted tests → Relevant regression tests → Full suite when appropriate
```

**Use the project's existing commands rather than inventing new ones.** The real commands for this
workspace, the ticket-local test runner, the mandatory baseline procedure, and the repos where a
category is impossible are all in `references/workspace-commands.md`. **Read it before running
anything** — a raw pass/fail count is meaningless in these repos without a baseline.

---

## Failure Handling

If a test fails:

```text
TEST FAILED
    ↓
Identify failure
    ↓
Determine whether:
  - implementation bug
  - test bug
  - environment issue
  - dependency issue
  - flaky test
  - PRE-EXISTING failure, unrelated to this change
    ↓
Investigate
```

**Do not modify the test merely to make it pass.**

| Cause | Action |
|---|---|
| Implementation is incorrect | Return to **IMPLEMENT** |
| Specification is incorrect or incomplete | Return to **SPEC** |
| Environment is broken | Report **ENVIRONMENT_BLOCKER** |
| Failure pre-dates the change | Record it as baseline, **do not claim it as yours or fix it silently** |

Never report a pre-existing failure as if you caused it, or your own as if it were pre-existing.

---

## Flaky Tests

If a test behaves inconsistently:

```text
Mark: FLAKY

Record:
- Test
- Number of runs
- Pass/fail pattern
- Suspected cause
- Impact
```

**Do not claim the feature is fully validated while a critical flaky test remains unexplained.**

---

## Close the loop — the sheet and the QA checkpoints

**Executing the tests is half the job.** The other half is that the sheet and the QA sheet end up
telling the truth. `/testing` updates **three** files, not one.

### 1. `test-cases.csv` — every row gets a status and evidence

Walk **every** row. No row may be left `⬜` without appearing in the report as `NOT_RUN` with a
reason.

| Status | Use when |
|---|---|
| `✅` | executed, passed, **Evidence names the file and test** |
| `❌` | executed, failed — must appear in the report's Failures section |
| `🔲` | needs live confirmation — cannot run in this environment yet |
| `⚠️` | known gap, accepted — needs a name in `qa-sheet.md` Not covered |
| `⊘` | not reachable in the product — **only** with a stated reason |
| `⬜` | not tested — must be explained in the report |

Mark rows **through the tool, not by hand** — it refuses a pass with no evidence, which is exactly
the mistake worth making impossible:

```bash
T=~/TSC/docs/<TICKET-ID>-<slug>
S=~/TSC/tsc-pos-backend/.ai/bin/lib/sheet_tool.py

python3 "$S" list   "$T/test-cases.csv"                      # rows still needing work
python3 "$S" mark   "$T/test-cases.csv" QA-001 --status pass \
        --evidence 'tests/premium-order-tag.spec.ts › tags above the threshold'
python3 "$S" verify "$T/test-cases.csv"                      # exits 1 on drift
python3 "$S" sync   "$T/test-cases.csv"                      # regenerate the xlsx view
```

`verify` is the gate: run it last and paste its output into the report. **If it exits 1, the sheet
disagrees with reality and the status is not `PASS`.**

`Evidence` cites the path relative to the ticket folder — `tests/x.spec.ts › the test name` — plus
the test name, because a reader needs to find the assertion, not just the file.

### 2. `qa-sheet.md` — tick the checkpoints

Every checkbox in sections **A–E** gets resolved. `⬜` left behind means "not checked", and that
is a finding, not a default.

| Section | What to fill |
|---|---|
| **A** Before any testing can start | tick each precondition, or say what is missing and which `TC` it blocks |
| **B** Questions that must be answered | fill the `Answer` column, or leave `⬜` with the `OQ`/`Q` id and owner |
| **C** Correctness checks against the code | tick each, **with the `file:line` you actually read** — these are read-checks, not runs |
| **D** Acceptance criteria | every `AC` gets a result. `🔲` + the blocking id if it cannot run |
| **E** Before opening the PR | tick each, and **E2/E3 record both baseline numbers** |
| Environment | the real environment, build sha, date, data, tester — makes the run reproducible |
| Defects found | one row per `❌`, with severity and a ticket id or an explicit "accepted, not raised" |
| Not covered | every `⚠️`/`⊘`/`NOT_TESTABLE`, each with a **person's name** in `Accepted by` |
| Sign-off | Developer · QA · Owner (the person named in `spec.md` §1) |
| **Verdict** (header) | `Passed` · `Passed with gaps` · `Blocked` · `In progress` — must match the report's Final Status |

**Rows in `qa-sheet.md` mirror the CSV. When they disagree, the CSV wins** — run
`sheet_tool.py verify` to find the drift rather than reconciling by eye.

### 3. `test-report.md` — the narrative and the evidence

The file below. It is the only one of the three that a human reads start to finish.

**Consistency is checked, not assumed.** Before finishing: the CSV counts, the `qa-sheet.md`
verdict, and the report's Final Status must agree. Three files saying three different things is
worse than one file saying nothing.

---

## Test Output

The final testing report goes to `docs/<TICKET-ID>-<slug>/test-report.md`. Template in
`templates/test-report.md`. Structure:

```text
# Test Report

## Ticket
## Implementation
## Test Summary            Unit / Integration / API / Regression / E2E — PASS / FAIL / NOT_RUN
## Baseline Comparison     before vs after, per repo
## Requirement Coverage    FR · BR · VR · DR · AC · EC
## Test Cases              TC-001 — PASS …
## Failures
## Blockers
## Risks
## Evidence                actual commands · actual results · logs
## Final Status            PASS / FAIL / BLOCKED / PARTIAL
```

`Evidence` holds **real commands and their real output**, pasted. Not a description of having run
them.

---

## Definition of Test Complete

Testing is complete only when:

```text
[ ] Relevant requirements have test coverage
[ ] Acceptance criteria have been verified
[ ] Relevant edge cases have been verified
[ ] Required unit tests pass
[ ] Required integration tests pass
[ ] Required API tests pass
[ ] Required regression tests pass
[ ] Required E2E tests pass
[ ] No unexplained critical failures remain
[ ] Test evidence is recorded
[ ] Baseline comparison recorded for lint / typecheck / suite
[ ] test-cases.csv statuses updated, no ✅ without Evidence
```

Final status `PASS` only when all required conditions are satisfied.

---

## Do Not

Never:

* Claim tests were run when they were not.
* Claim tests passed when output was not verified.
* Skip acceptance-criteria validation.
* Ignore relevant edge cases.
* Delete a failing test to obtain a green build.
* Modify production data during testing.
* Disable security checks to make tests pass.
* Hide failures.
* Treat a flaky test as a pass without investigation.
* Change implementation requirements merely to satisfy an existing test.
* Mark a `test-cases.csv` row `✅` with an empty `Evidence` column.
* Report a raw error count without its baseline.

---

## Exit Conditions

| Status | Means |
|---|---|
| **PASS** | All required testing completed successfully. |
| **FAIL** | Implementation or tests have unresolved failures. |
| **BLOCKED** | Testing cannot proceed — environment, dependency, access, data or infrastructure blocker. |
| **PARTIAL** | Some required testing completed; one or more non-blocking areas remain unverified. |

**Return the status explicitly.** `PARTIAL` is an honest and common answer — use it rather than
inflating to `PASS`.
