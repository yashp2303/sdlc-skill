# The QA artifacts — `test-cases.csv`, `test-cases.xlsx`, `qa-sheet.md`

Three artifacts, not one, because they have different readers and different lifecycles.

```
docs/<TICKET-ID>-<slug>/
├── test-cases.csv     SOURCE OF TRUTH — git-diffable, driven by sheet_tool.py
├── test-cases.xlsx    generated VIEW for Excel — regenerate, never hand-edit
└── qa-sheet.md        human sign-off — sections, environment, defects, not-covered
```

**Reuse the existing toolchain — do not hand-roll a variant.** The `qa-cases` skill
(`~/.claude/skills/qa-cases/`) already owns the CSV schema and the xlsx converter, and
`tsc-pos-backend/.ai/bin/lib/sheet_tool.py` already reads and mutates it (`list`, `mark`,
`verify`, `sync`). A markdown table that looks like a QA sheet but no tool can read is
strictly worse than the CSV: statuses drift, nothing verifies, and `✅ with no evidence`
stops being catchable.

So: **invoke `qa-cases` for the enumeration and the CSV**, then write `qa-sheet.md` as the
readable sign-off layer over it.

## Division of labour

| Step | Owner | Produces |
|---|---|---|
| enumerate every case from the approved spec + plan | `qa-cases` skill | `test-cases.csv` |
| generate the Excel view | `qa-cases` script | `test-cases.xlsx` |
| human sign-off sheet, environment, defects, not-covered | this skill | `qa-sheet.md` |
| coverage table + blocked count only | this skill | `plan.md` §8 |

```bash
# after the CSV exists
python3 ~/.claude/skills/qa-cases/scripts/to-xlsx.py docs/<TICKET-ID>-<slug>/test-cases.csv
```

## `test-cases.csv` — the schema, verbatim from `qa-cases`

```
ID · Section · Scenario · Type · Level · Expected · Status · Evidence · Notes
```

| Column | Rules |
|---|---|
| `ID` | `QA-001` upward. **Never renumber** — ids get cited in commits and reviews |
| `Type` | `positive` · `negative` · `edge` · `rule` · `ui` |
| `Level` | the **cheapest** level that can prove it: `unit` · `integration` · `e2e` · `manual` |
| `Expected` | the observable result. For a negative case, the **error code**, not "fails" |
| `Status` | starts `⬜` for every row. Nothing is pre-marked |
| `Evidence` | the test file and name, or the walkthrough date. **`✅` with this empty is not allowed** |

Status: `⬜` not tested · `✅` pass · `🔲` needs live confirmation · `❌` fail ·
`⚠️` known gap accepted · `⊘` not reachable in the product

Do not invent columns or status values — `sheet_tool.py verify` and the xlsx dropdown both
key off these exactly.

## `qa-sheet.md` — the human layer

A readable, sectioned view of the same rows, plus the things a CSV cannot carry: the
environment a manual run happened in, the defects found, and what was deliberately not
covered and who accepted that.

Rows here mirror the CSV. When they disagree, **the CSV wins** — run
`sheet_tool.py verify` to find the drift rather than reconciling by eye.

### Header

```markdown
# QA Sheet — <Feature>

| | |
|---|---|
| **Ticket** | [TICKET-ID](url) — <title> |
| **Spec** | [`spec.md`](./spec.md) — acceptance criteria this sheet verifies |
| **Plan** | [`plan.md`](./plan.md) — where each behaviour is implemented |
| **Cases** | [`test-cases.csv`](./test-cases.csv) — source of truth · `test-cases.xlsx` view |
| **Last reviewed** | YYYY-MM-DD |
| **Method** | static read + <n> unit + <n> integration + <n> e2e + manual walkthrough |
| **Suite at review** | <n> suites / <n> tests passing |

**Status:** ⬜ not tested · ✅ pass, evidence named · 🔲 needs live confirmation ·
❌ fail — defect · ⚠️ known gap, accepted · ⊘ not reachable in the product
```

`Suite at review` anchors the sheet to a known-good build, so a later ❌ can be told apart
from a pre-existing failure.

### Coverage table

```markdown
| Level | Total | ✅ | 🔲 | ❌ | ⬜ |
|---|---|---|---|---|---|
| unit | 18 | 0 | 0 | 0 | 18 |
| integration | 14 | 0 | 0 | 0 | 14 |
| e2e | 0 | | | | |
| manual | 11 | 0 | 0 | 0 | 11 |
| **all** | **43** | **0** | **0** | **0** | **43** |
```

Keep the `e2e` row even at zero — an explicit zero says "considered, none needed"; an
absent row says nothing. Backend-only tickets legitimately have no e2e rows.

### Sections

Numbered 1–8. Sections 5 and 6 are dropped entirely when the ticket touches no UI —
say so in one line rather than leaving empty tables.

### 1. Positive — the intended paths

One row per AC in spec §5, plus the transitions. Cite the AC in the row.

| ID | Scenario | Expected | Level | Status | Evidence |
|---|---|---|---|---|---|
| QA-001 | New order, post-discount ₹2,25,000 | `premium_order` sent | unit | ⬜ | AC-1 |

### 2. Negative — every way the behaviour is withheld or refused

**Mandatory.** One row per guard in the code. A negative row asserts the **refusal**, not
the absence of a crash.

Always present, because these are where the defects are and the rows people omit:

| Must include | Why |
|---|---|
| exactly the boundary | `>` vs `>=` — one row kills one bug class |
| one unit inside the boundary | rounding |
| `0` | no crash *and* no behaviour |
| `null` / `undefined` | no throw |
| `NaN` | no throw, no accidental truthiness |
| negative | refunds, reversals |
| the invariant that must always hold | e.g. "the existing tag is never dropped" |

### 3. Edge cases

One row per numbered case in plan §3, plus the standing families from the repo template:
`empty` · `exactly one` · `many` · `boundary` · `zero / negative amount` ·
`currency rounding` · `concurrent` · `retried delivery` · `partial completion` ·
`pre-existing records`.

Add a **Family** column so a reader can see which families went unconsidered.

A case with no correct answer yet is `🔲`, with its Evidence citing the open question.

### 4. Business rules

One row per rule in scope, by id, from `.ai/rules/` where the repo has it. Each asserts
the rule is **enforced** — which for a prohibition means constructing the prohibited state
and checking it is refused.

Include rules that do **not** apply, with why. A rule silently dropped from scope is how a
regression enters.

### 5. UI — automated (e2e)

Drop the section when there is no UI change. When there is:
primary flow completes · loading state · empty state · error state says what to do ·
keyboard-only completion.

### 6. UI — manual walkthrough

Rows automation cannot judge. Needs an environment block:

```markdown
**Environment:** <URL> · <browser> · <viewport> · role logged in as <ROLE>

| ID | Steps taken | Observed | Status | Date |
|---|---|---|---|---|
```

> A manual row must **never** be marked ✅ from reading the code. If the app could not be
> run, the rows stay ⬜ and the reason is stated here.

### 7. Regression — must be unaffected

The AC that says "everything else behaves exactly as before". Enumerate what "everything
else" means concretely — the other fields on the same payload, the adjacent flows, the
existing value the change sits beside. "No regressions" is not a row.

### 8. Cannot be tested until answered

```markdown
| ID | Blocked on | Consequence |
|---|---|---|
| QA-018, QA-033 | **Q1** — does <service> replace or merge? | If merge with no removal endpoint, these are ❌ by design, not by defect |

Everything else — 37 of 43 — is testable today.
```

**Close with the count.** A sheet presenting 43 green-able rows when 6 depend on an
unanswered question misleads in the direction that costs most.

### Two closing tables

```markdown
## Defects found

| Sheet row | Defect | Severity | Action |
|---|---|---|---|
| QA-0NN | | | `/bug <description>` |

## Not covered, and why

| Area | Reason | Accepted by |
|---|---|---|
```

`Not covered` needs a name in `Accepted by`. Uncovered scope with nobody's name against it
is an omission, not a decision.

`⊘ not reachable` is a claim about the product — verify each one. A wrong `⊘` dismisses a
real bug class.

## Id allocation — applies to both files

Contiguous from QA-001, in section order — matching `qa-cases`. Do **not** adopt the repo
markdown template's banded scheme (010, 020, 040, 060, 080): it reads tidily but breaks the
moment a section needs an eleventh row, and it does not match the CSV.

Ids are permanent. A row that becomes irrelevant is struck through with a reason, never
renumbered, because commits and test names cite them.

## Keeping it current

The sheet is updated as tests are written, not at the end. Mark rows through the tool, not
by hand — it refuses a pass with no evidence:

```bash
sheet_tool.py list  docs/<TICKET-ID>-<slug>/test-cases.csv --level unit --status ⬜
sheet_tool.py mark  docs/<TICKET-ID>-<slug>/test-cases.csv --id QA-001 --status ✅ \
                    --evidence src/orders/lib/premium-order-tag.spec.ts
sheet_tool.py verify docs/<TICKET-ID>-<slug>/test-cases.csv   # exit 1 on drift
sheet_tool.py sync   docs/<TICKET-ID>-<slug>/test-cases.csv   # regenerate the xlsx
```

`sheet_tool.py` lives at `tsc-pos-backend/.ai/bin/lib/sheet_tool.py`. Each `✅` names its
evidence in the same commit that makes it pass.
