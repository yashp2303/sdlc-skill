---
name: feature-docs
description: Turn a feature requirement into the five-file docs pack — spec.md, plan.md, test-cases.md, test-cases.csv, qa-sheet.md — in the house format, in a per-ticket folder under docs/. Use when a feature requirement, ticket, or change request arrives and the specification, plan, test scenarios, or QA sheet need writing. Trigger: /feature-docs
---

# feature-docs

You give the feature requirement. This writes **five files, always five**, in one folder,
in the house format:

```
docs/<TICKET-ID>-<slug>/
├── spec.md            what changes and why          — business-facing
├── plan.md            where the code goes           — engineer-facing
├── test-cases.md      every scenario, named         — QA-facing
├── test-cases.csv     the same rows, tool-driven    — SOURCE OF TRUTH
└── qa-sheet.md        sign-off checkpoints          — reviewer-facing
```

Five readers, five documents. They are not five views of one document — each carries what
the others must not, and the tables below say which.

## Run it

```
/feature-docs <TICKET-ID> <the requirement, pasted or described>
```

If no ticket id is given, ask for one — the folder name needs it and so does the commit
message. Everything else can be derived or defaulted.

## Where the folder goes

| Situation | Location |
|---|---|
| TSC workspace (default) | `/Users/devx/TSC/docs/<TICKET-ID>-<slug>/` |
| a single repo, work confined to it | `<repo>/docs/<TICKET-ID>-<slug>/` |

`<slug>` is lowercase, hyphenated, 2–4 words, from the feature not the ticket title:
`TWP-5704-premium-order-tagging`, not `TWP-5704-tag-orders-above-2-lakh-in-oms`.

Reference example on disk: `/Users/devx/TSC/docs/TWP-5704-premium-order-tagging/`.

## Order of writing, and why it is this order

```
1 spec.md         requirements FR-n, rules BR-n, criteria AC-n get their numbers here
2 plan.md         cites those numbers; never restates them
3 test-cases.md   one scenario per AC minimum, plus the derived families
4 test-cases.csv  the same rows, machine-readable
5 qa-sheet.md     the checkpoint layer over the CSV
```

Numbering flows one way. `AC-4` is minted in the spec, referenced by the plan, tested by
`TC-4.x`, tracked as `QA-0nn`. **Never renumber** — those ids get quoted in commits,
reviews and Jira comments, and a renumber silently invalidates every citation.

## What goes where — the boundary that keeps them useful

| File | Contains | Contains **no** |
|---|---|---|
| `spec.md` | business problem, scope, actors, FR/BR/AC, edge cases, open questions | file paths, function signatures, estimates, technology choices |
| `plan.md` | current state, approach, steps, files to change, risks, commit message | restated requirements (cite `FR-2`, don't re-explain it) |
| `test-cases.md` | every scenario grouped by requirement, with its test function name | implementation detail, status tracking |
| `test-cases.csv` | the same rows as columns — status and evidence live here | prose |
| `qa-sheet.md` | environment, defects, not-covered with an accepter's name | new scenarios not in the CSV |

**No technology in the spec.** "The order is tagged when its payable value is at or above
the threshold" belongs in `spec.md`. "`note_attributes` gets `premium_order: true` in
`create-oms-order.ts`" belongs in `plan.md`. Mixing them means the spec cannot be reviewed
by the person who owns the requirement.

## Formats

Each file has a reference with the section-by-section rules and a fillable template:

| File | Rules | Template |
|---|---|---|
| `spec.md` | `references/spec-format.md` | `templates/spec.md` |
| `plan.md` | `references/plan-format.md` | `templates/plan.md` |
| `test-cases.md` + `.csv` | `references/test-cases-format.md` | `templates/test-cases.md` · `templates/test-cases.csv` |
| `qa-sheet.md` | `references/qa-sheet-format.md` | `templates/qa-sheet.md` |

Read the reference for a file before writing that file. The templates are skeletons to
copy and fill, not examples to imitate loosely.

### spec.md — the section list

```
1. Document Information      Title · Version · Date · Status · Owner
2. Executive Summary
3. Business Problem
4. Business Goal
5. Scope                     5.1 In Scope · 5.2 Out of Scope · 5.3 Future Scope
6. Actors / Users
7. Functional Requirements   FR-n
8. Business Rules            BR-n
9. User Flows
10. Acceptance Criteria      AC-n, Given / When / Then
11. Edge Cases
12. Non-Functional Requirements
13. Dependencies & Assumptions
14. Open Questions           Q-n, each with a default
15. Revision History
```

Sections 1–6 are fixed house format. **Sections 7–15 are the working default** — if you
want a different tail, edit the list in `references/spec-format.md` and this skill follows
it from then on. Do not vary it per document.

### plan.md — the section list

```
Objective
Requirements
Current State
Proposed Approach
Implementation Steps
Files to Change
Testing Plan
Risks / Considerations
Acceptance Criteria
Commit Message          ← last, always
```

Flat headings, no numbering, in exactly this order. The commit message is a real
copy-pasteable block, not a description of one.

## The rule the whole pack rests on

**Every claim about the existing system is verified by reading it, and says where.**

`Current State` in the plan is not "orders are currently created without tags" — it is
``create-oms-order.ts:644`` — `tags` is a hardcoded string, not an array``. Same for every
"today the system…" sentence in the spec's Business Problem.

Before writing, grep for every entity, status, field, module, route and role the
requirement names. **If one does not exist, that mismatch is the most important finding in
the pack** and it goes at the top of the Business Problem — not into an assumption. A
requirement saying "when the order is completed" when no `completed` status exists has
already told you what is actually wrong.

Where a fact cannot be verified — an external service, a system outside the workspace —
say so explicitly and turn it into a numbered open question. Never guess and never smooth
it over.

## Every open question needs a default

`Q-3 | Does the external system merge or replace tags? | Default: assume merge, and gate
removal behind Q-3` — chosen so that being wrong changes one function, not the design.

A question with no default blocks the estimate. A pack full of undefaulted questions is a
list of things you did not decide.

## Test cases — reuse the toolchain, do not invent one

`test-cases.csv` uses the schema the `qa-cases` skill owns, verbatim:

```
ID · Section · Scenario · Type · Level · Expected · Status · Evidence · Notes
```

`Type`: `positive` · `negative` · `edge` · `rule` · `ui`
`Level`: `unit` · `integration` · `e2e` · `manual` — the cheapest that can prove it
`Status`: `⬜` not tested · `✅` pass · `🔲` needs live confirmation · `❌` fail ·
`⚠️` accepted gap · `⊘` not reachable

Every row starts `⬜`. A `✅` with an empty `Evidence` is not allowed.

### Coverage is exhaustive, not representative

**Generate every case, not a sample.** The CSV is the definition of done for QA, so a scenario
that is missing here does not get tested. Work all seven sources in order — each yields cases the
others miss, and skipping one is the usual reason a bug ships:

| # | Source | Yields | Rule |
|---|---|---|---|
| 1 | every `AC-n` in the spec | **positive** | one per criterion minimum. A criterion with three variants is three rows |
| 2 | every `SC-n` scenario | **positive** | the end-to-end path, at the cheapest level that proves it |
| 3 | **every guard in the code** | **negative** | open the implementation; each `throw`, early return and validation branch is a row, and `Expected` is its **specific error code** |
| 4 | every `VR-n` validation rule | **negative** | the rejection, named |
| 5 | every `BR-n` business rule | **rule** | plus a case that **constructs the prohibited state** and asserts the refusal — asserting the happy path does not enforce a prohibition |
| 6 | every `EC-n` edge case, **and the standard families every time** | **edge** | see below |
| 7 | UI, split automated vs manual | **ui** | primary flow · the four data states (loading, empty, error, populated) · keyboard-only completion. Manual: is the error message comprehensible, does the layout survive a real screen |

**The standard edge families are mandatory.** Walk them for every quantity, collection and
boundary in scope, and write `n/a` with a reason rather than omitting:

```
empty · exactly one · many · exact boundary · one unit below · one unit above
zero · negative · null · non-numeric · rounding · currency precision
concurrent access · retried delivery · partial completion · timeout mid-flow
records created before this feature existed
```

That last one is the most-missed and the most expensive: existing data does not satisfy new
invariants.

**Cross the domains against each other**, not just against themselves — the cases nobody thinks
of live in the cells:

```
              Return  Exchange  GiftCard  Cashback  TaxIncl  SplitPayment
Coupon           ·        ·         ·         ·        ·          ·
EmployeeDisc     ·        ·         ·         ·        ·          ·
CreditNote       ·        ·         ·         ·        ·          ·
```

Every reachable cell is a row. Mark one `⊘` only if you can say **why** it is unreachable — a
wrong `⊘` silently dismisses a whole bug class.

**Negative rows must outnumber positive ones**, or you must be able to say why not. A codebase
with more happy paths than guards is unusual; a test sheet with more happy paths than guards is
just incomplete.

### If `research.md` exists, start from it — then expand

`docs/<TICKET-ID>-<slug>/research.md` §19 already lists `TC-n` cases sized during investigation.
Carry every one across, keeping its `TC-n` in `Notes` so the trail holds. **Then expand** — §19
sizes the QA effort, it does not enumerate the suite. If your CSV has the same count as §19, you
have transcribed rather than derived.

**Invoke the `qa-cases` skill for the enumeration** — it owns the derivation method and
`scripts/to-xlsx.py`. Generate the Excel view, never hand-edit it:

```bash
python3 ~/.claude/skills/qa-cases/scripts/to-xlsx.py docs/<TICKET-ID>-<slug>/test-cases.csv
```

**Negative rows are mandatory.** Boundary, one unit inside it, `0`, `null`, negative, and
the invariant that must always hold. A negative row asserts the **refusal**, not the
absence of a crash.

## Finish by reporting

```
docs/TWP-5704-premium-order-tagging/
  spec.md          15 sections · FR 8 · BR 3 · AC 11 · Q 4 open
  plan.md          6 files to change · estimate 32h (45h+ if Q1 resolves to merge)
  test-cases.md    43 scenarios
  test-cases.csv   43 rows · ⬜ 43
  qa-sheet.md      5 checkpoint sections · 6 rows not testable today

  positive 12 · negative 18 · edge 9 · rule 3 · ui 1

  Verified against `prod` on YYYY-MM-DD. Three findings change the shape of the work.
  Blocked: Q1 (external tag semantics) gates the removal path entirely.
```

Then stop. **This skill writes the pack; it does not implement it.** For implementation,
verification and reporting across the TSC repos, hand over to `/tsc-ticket` phase 3.

## Relationship to the other skills

| Skill | Its job | Overlap |
|---|---|---|
| `feature-docs` (this) | the five-file pack in this house format | — |
| `tsc-ticket` | full lifecycle: investigate → document → implement → verify → report | its phase 2 writes 4 files in a **different** spec/plan shape |
| `qa-cases` | derivation method + CSV schema + xlsx converter | this skill calls it for steps 3–4 |

`tsc-ticket` phase 2 produces `spec.md` as *What changes / Why / Verified facts* and
`plan.md` as *TL;DR / Call sites / Implementation / Estimate*. **This skill's formats
override those when the user asks for the docs pack.** Do not blend the two shapes in one
document — pick the format the user invoked and write it whole.

## Two failure modes

**A spec that reads like the requirement, reformatted.** If nothing in it says
`file:line`, no verification happened. Go back to the code before writing another section.

**A plan with a single-number estimate.** Real estimates branch on the open questions:
"32 hours if the external system replaces tags, 45+ if it merges." One number hides the
unknown that will actually decide the cost.
