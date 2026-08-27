# `test-cases.md` + `test-cases.csv` — the format

Two files, same rows, different readers.

```
test-cases.md    every scenario, grouped by requirement, with its test function name
test-cases.csv   the same rows as columns — SOURCE OF TRUTH for status and evidence
```

**The CSV wins on any disagreement.** It is git-diffable, so a status change is a
reviewable line; and `sheet_tool.py` can read it, so `✅ with no evidence` is catchable. The
markdown file is the readable index — it carries the grouping and the test function names,
which a flat CSV cannot express.

Do not invent a third variant. A markdown table that looks like a QA sheet but no tool can
read lets statuses drift silently.

## Enumeration — call `qa-cases`

The `qa-cases` skill (`~/.claude/skills/qa-cases/`) owns the derivation method. Invoke it
rather than reproducing it. The short version of what it derives from, in order:

1. **Acceptance criteria → positive cases.** One per `AC` minimum. Variants multiply rows
2. **Every guard in the code → a negative case.** Open the implementation, find each
   `throw`, early return and validation branch. `Expected` is the specific error, not
   "fails". Usually the largest group, and the one hand-written sheets miss most
3. **The spec's Edge Cases table → edge rows**, plus the standard families every time:
   `empty · exactly one · many · boundary · one unit either side · zero · negative · null ·
   rounding · concurrency · retry · partial completion · records predating the feature`
4. **Business rules → rule cases.** A rule that prohibits something needs a case that
   **constructs the prohibited state** and asserts the refusal. Asserting the happy path
   does not enforce a prohibition
5. **Domain combinations.** Cross the domains against each other, not just themselves. Every
   reachable cell is a row; mark one `⊘` only if you can say *why* it is unreachable
6. **UI → automated and manual, separately.** Automated: primary flow, the four data states
   (loading, empty, error, populated), keyboard-only completion. Manual: whether the error
   message is comprehensible, whether the layout survives a real screen

Then generate the Excel view — never hand-edit it:

```bash
python3 ~/.claude/skills/qa-cases/scripts/to-xlsx.py docs/<TICKET-ID>-<slug>/test-cases.csv
```

---

## `test-cases.csv` — schema, verbatim

```
ID,Section,Scenario,Type,Level,Expected,Status,Evidence,Notes
```

| Column | Rules |
|---|---|
| `ID` | `QA-001` upward, zero-padded. **Never renumber** — ids get cited in commits and reviews |
| `Section` | matches a `test-cases.md` group: `1 Positive`, `2 Negative`, `3 Edge`… |
| `Scenario` | one concrete situation. Quote it if it contains a comma |
| `Type` | `positive` · `negative` · `edge` · `rule` · `ui` |
| `Level` | the **cheapest** level that can prove it: `unit` · `integration` · `e2e` · `manual` |
| `Expected` | the observable result. For a negative case, the **error code**, not "fails" |
| `Status` | starts `⬜` for every row. Nothing is pre-marked |
| `Evidence` | test file and name, or the manual walkthrough date. **`✅` with this empty is not allowed** |
| `Notes` | the `AC-n` / `FR-n` / `BR-n` this closes, or the `Q-n` blocking it |

Status values: `⬜` not tested · `✅` pass · `🔲` needs live confirmation · `❌` fail ·
`⚠️` known gap accepted · `⊘` not reachable in the product.

Do not add columns or status values — the xlsx dropdown and `sheet_tool.py verify` key off
these exactly.

## `test-cases.md` — the scenario and function file

The readable layer. Same rows, grouped, plus the thing the CSV has no column for: **the name
of the test function that proves each row.** That is what makes this file worth having — it
is the map from requirement to executable test.

### Header

A table with `Ticket`, `Spec` link, `Plan` link, `CSV` link, `Total`, and the type/level
breakdown. Then the coverage summary:

```
43 scenarios · positive 12 · negative 18 · edge 9 · rule 3 · ui 1
unit 28 · integration 11 · e2e 1 · manual 3
37 testable today · 6 blocked on Q-1
```

### Groups

One `##` per section, in this order — negative before edge, because it is the section that
finds bugs and it should not be at the bottom where it gets skimmed:

```
1. Positive          2. Negative          3. Edge
4. Business Rules    5. UI                6. Not Covered
```

### Rows

Each scenario, in a table per group:

| ID | Scenario | Expected | Level | Test function | Covers |
|---|---|---|---|---|---|
| QA-001 | payable exactly at threshold | order marked premium | unit | `premium-order-tag.spec.ts › tags at exactly the threshold` | AC-4, BR-2 |
| QA-014 | payable is `null` | rejects with `INVALID_ORDER_VALUE` | unit | `premium-order-tag.spec.ts › rejects a null value` | BR-1 |

`Test function` is the real `describe › it` path, or the manual procedure name. Before the
test exists, write the name it *will* have — that name is a design decision and writing it
early catches scenarios that are really two scenarios.

`Covers` cites spec ids. A row covering nothing is either a missing requirement or a case
you invented; both need resolving before this file is done.

### Group 6 — Not Covered

Every scenario deliberately excluded, with `Why` and the id blocking it. Silence reads as
coverage, so this group is never empty by default — if it truly is, write `Nothing
excluded.`

---

## Rules that apply to both files

**Never a case without an expected result.** A row reading "test the edge cases" is not a
case; it is a note that this step was not done.

**Negative rows are mandatory**, and there should be more of them than positive ones. Cover
the boundary, one unit inside it, `0`, `null`, negative, and the invariant that must always
hold. A negative row asserts the **refusal**, not the absence of a crash.

**Cheapest level that can prove it.** Threshold arithmetic is `unit`, not `e2e`. Pushing
cases up produces a slow suite nobody runs and a sheet that stays `⬜`.

**Do not write tests in this step.** Enumeration and execution are separate, so the list is
not shaped by what was convenient to test.

**Say what you could not enumerate.** If part of the spec is too vague to derive cases from,
that goes in `Not Covered` and in the report — not into a vague row.

## Before handing it over

- Every `AC` in the spec has at least one row
- Every boundary in `BR` has a row sitting exactly on it, and one either side
- Every guard in the implementation has a negative row naming its error
- `negative` count ≥ `positive` count, or you can say why not
- Every row has an `Expected` you could assert
- Every row starts `⬜` with empty `Evidence`
- Markdown row count == CSV row count
- `Not Covered` is populated or explicitly empty
