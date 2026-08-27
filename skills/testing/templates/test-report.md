# Test Report — <TICKET-ID>

| | |
|---|---|
| **Ticket** | [<TICKET-ID>](<url>) — <title> |
| **Spec** | [`spec.md`](./spec.md) |
| **Plan** | [`plan.md`](./plan.md) |
| **Cases** | [`test-cases.csv`](./test-cases.csv) — source of truth |
| **QA sheet** | [`qa-sheet.md`](./qa-sheet.md) |
| **Tested by** | <name> |
| **Environment** | <ustage> · build `<sha>` · <YYYY-MM-DD> |
| **Final Status** | **PASS · FAIL · BLOCKED · PARTIAL** |

---

## Implementation

<One paragraph: what was built, which files, which repos. Link the plan's steps.>

---

## Test Summary

Pipeline order: Manual → Unit → Integration → Playwright → Regression → Final Validation.

| # | Category | Status | Ran | Passed | Failed | Not run |
|---|---|---|---|---|---|---|
| 1 | Manual | PASS / FAIL / NOT_RUN | | | | |
| 2 | Unit | | | | | |
| 3 | Integration | | | | | |
| 3b | API (integration boundary) | | | | | |
| 4 | Playwright (UI/E2E) | | | | | |
| 5 | Regression | | | | | |

<If a category is NOT_RUN, say why here in one line — not in a footnote.>

---

## Integration Detail

**Environment:** ustage · Mongo ustage cluster · Redis local · externals mocked
**Symlink verified:** `.env.secrets → .env.secrets.ustage` ✅ (NOT prod)

### Boundaries exercised

| ID | Boundary | Result |
|---|---|---|
| INT-001 | pos-app → Serverless OMS | PASS (mocked — cannot roll back) |
| INT-002 | service → Mongo | PASS |

### Integration test cases

| ID | Title | Related | Result |
|---|---|---|---|
| INT-TC-001 | | FR-1, BR-2 | PASS |

### Database verification

| | |
|---|---|
| Records created | <n> |
| Records updated | <n> |
| Transaction / rollback | PASS / n/a |
| Constraints, unique indexes | PASS / n/a |
| Idempotency (duplicate request) | PASS / n/a |

### External integrations

| Dependency | Real or mocked | Why |
|---|---|---|
| Serverless OMS | **mocked** | writes an order that cleanup cannot reach |
| Freshdesk / Flowcall | **mocked** | creates a ticket a human would triage |
| Gupshup SMS | **mocked** | sends a real message to a real phone |

### Cleanup

| | |
|---|---|
| Strategy | tagged records + `afterEach` deleteMany |
| Tag used | `<TICKET-ID>-int-test` |
| Records removed | <n> |
| **Verified 0 remaining** | ✅ / ❌ — verified, not assumed |

> `ustage` is **shared** with other developers. Leftover test data is in someone else's
> environment, so cleanup is mandatory and must be checked, not presumed.

---

## Baseline Comparison

**Mandatory.** These repos have pre-existing failures; a bare count proves nothing.

| Check | Baseline (at HEAD) | With this change | Delta |
|---|---|---|---|
| repo suite — `<repo>` | <n> passed / <n> failed | <n> passed / <n> failed | |
| ticket-local tests | n/a | <n> passed / <n> failed | |
| typecheck | <n> errors | <n> errors | |
| lint (touched files) | <n> errors | <n> errors | |

<Name any pre-existing failure you did NOT cause, so nobody attributes it to this change.>

---

## Requirement Coverage

| Requirement | Covered by | Result |
|---|---|---|
| FR-1 | TC-001, TC-002 | PASS |
| BR-1 | TC-003 | PASS |
| BR-2 (boundary) | TC-004, TC-005, TC-006 | PASS |
| VR-1 | TC-007 | PASS |
| DR-1 | TC-008 | PASS |
| AC-1 | TC-001 | PASS |
| AC-7 | TC-020 | 🔲 blocked on OQ-1 |
| EC-1 | TC-010 | PASS |

<Every FR / BR / VR / DR / AC / EC from the spec appears. One with no TC is either untested or
out of scope — say which. A missing row reads as passed.>

**Not testable:**

| Requirement | Why | Required action |
|---|---|---|
| AC-<n> | <e.g. frontend has no test runner installed> | <what must change> |

---

## Test Cases

| ID | Scenario | Type | Level | Status | Evidence |
|---|---|---|---|---|---|
| TC-001 | | positive | unit | PASS | `tests/x.spec.ts › <test name>` |
| TC-002 | | negative | unit | PASS | |
| TC-003 | | edge | unit | FAIL | see Failures |

<Every row from test-cases.csv. Counts must match the CSV — if they do not, the CSV wins.>

```
Totals:  <n> cases · ✅ <n> · ❌ <n> · 🔲 <n> · ⚠️ <n> · ⊘ <n> · ⬜ <n>
         positive <n> · negative <n> · edge <n> · rule <n> · ui <n>
```

---

## Failures

### TC-<n> — <one-line summary>

```
<actual test output, pasted>
```

**Cause:** implementation bug / test bug / environment / dependency / flaky / **pre-existing**
**Action:** return to IMPLEMENT · return to SPEC · report ENVIRONMENT_BLOCKER · recorded as baseline

<One block per failure. `None.` if there are none.>

---

## Flaky Tests

| Test | Runs | Pass/fail pattern | Suspected cause | Impact |
|---|---|---|---|---|

<`None observed.` if none. A critical flaky test left unexplained blocks a PASS.>

---

## Blockers

| Blocker | Kind | Blocks | Owner |
|---|---|---|---|
| | ENVIRONMENT / DEPENDENCY / ACCESS / DATA | TC-<n>..<n> | |

<`None.` if none.>

---

## Risks

<What could still go wrong, with arithmetic or a mechanism — not categories. What you could not
test, and the one test that would settle it.>

---

## Evidence

**Real commands and their real output. Not a description of having run them.**

```bash
$ cd ~/TSC/tsc-pos-backend/pos-app && bun run test
<output>

$ cd ~/TSC/docs/<TICKET-ID>-<slug> && ./run-tests.sh
<output>

$ npx tsc --noEmit -p tsconfig.json
<output>

$ npx eslint <touched files>
<output>

$ python3 ~/TSC/tsc-pos-backend/.ai/bin/lib/sheet_tool.py verify test-cases.csv
<output — must exit 0>
```

---

## Sheet and QA Checkpoint Updates

| Artifact | Updated | Note |
|---|---|---|
| `test-cases.csv` | <n> rows marked | `sheet_tool.py verify` exit code: <0/1> |
| `qa-sheet.md` A–E | <n>/<n> ticked | <what is left, and why> |
| `qa-sheet.md` Environment | filled | |
| `qa-sheet.md` Defects found | <n> rows | |
| `qa-sheet.md` Not covered | <n> rows, all with `Accepted by` | |
| `qa-sheet.md` Verdict | <value> | must match Final Status below |

---

## Final Status

**<PASS · FAIL · BLOCKED · PARTIAL>**

<One paragraph justifying it against the Definition of Test Complete. If PARTIAL, name exactly
what is unverified and why that is acceptable to ship — or that it is not.>
