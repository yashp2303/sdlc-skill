# `plan.md` — the format

Engineer-facing. The reader is going to implement this. They have the spec open in another
tab, so **do not restate requirements** — cite `FR-3` and spend the space on where the code
goes and what it costs.

## The section list

Flat headings, no numbering, exactly this order. `Commit Message` is always last.

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
Commit Message
```

Above the first heading: a header table with `Ticket`, `Spec` (relative link),
`Status`, `Date`, `Estimate`. Status names the blocker if there is one —
`Blocked on Q-1`, not `In Progress`.

---

## Objective

Two or three sentences: what this plan delivers, and the one thing that makes it harder or
easier than it looks.

That second part is the section's real job — **correct the reader's instinct about
difficulty**, and only when their instinct is actually wrong:

> Two call sites, forty lines. The work is not the tagging — it is that the two paths
> compute order value differently, so a shared helper has to take the value as an argument
> rather than derive it.

If intuition is already right, one sentence and move on. Do not manufacture a twist.

## Requirements

A table mapping spec ids to what this plan does about each:

| Spec | Behaviour | Where it lands |
|---|---|---|
| FR-1 | tag at creation | Step 2 — `create-oms-order.ts` |
| FR-3 | tag on edit confirm | Step 3 — `order-edit/confirm.ts` |
| BR-2 | inclusive boundary | Step 1 — the shared helper |

Every `Must` from the spec appears. If one has no row, either the plan is incomplete or the
requirement is out of scope — say which, here, explicitly.

Nothing else. Do not re-explain what `FR-1` means; the spec did that.

## Current State

**What the code does today, with `file:line` for every claim.** This is the section that
makes the plan trustworthy, and the one that is most often written from memory.

```
`create-oms-order.ts:644` — `tags` is a hardcoded string `"pos_order"`, not an array.
                            Adding a second tag means changing the type, not the value.
`order-edit/confirm.ts:212` — sends no tags at all. The edit path is a separate builder.
`serverless-oms/tags.ts:88` — the existing update endpoint **merges**; there is no unset.
```

Include, always:

- **Every write site** for the field or behaviour in question — there may be one, three, or
  none, and "none" changes the plan completely
- **Every read site.** One writer and zero readers is a different feature from one writer
  and five consumers
- **The nearest existing implementation.** Most features are extensions. Name it, or you
  will specify a second parallel version of something that exists
- **Where the numbers come from**, on *each* path. Two paths computing the same quantity
  differently is the most common trap in this stack and is invisible unless you check both
- **What is out of reach** — external services, anything outside the workspace. Say so and
  point at the open question. Never infer their behaviour

Put the grep that found the call sites in the document. It lets the next person re-run it
and see whether the answer changed.

## Proposed Approach

The shape of the solution in a paragraph or two, and **the one design decision** with the
alternative you rejected and why.

> One helper, two call sites. The helper takes the comparison value as an argument rather
> than computing it, because the two paths derive that value differently — deriving inside
> the helper would silently pick one path's definition for both.

Shared logic goes in one place. Two implementations of one rule drift the moment the rule
changes. If the plan puts the same decision in two files, it is wrong and this is where
that gets caught.

## Implementation Steps

Numbered, ordered **by risk and dependency** — the thing that unblocks the most, or that
would invalidate the rest if wrong, goes first. Not file order.

Each step:

```
Step 2 — Tag on creation                                       (FR-1, AC-1..AC-4)
  File: src/orders/create-oms-order.ts:644
  Change the hardcoded tag string to an array and append the helper's result.

  <real code — the actual lines, not a description of them>

  Done when: a ₹2,00,000 order carries the premium tag and a ₹1,99,999 one does not.
```

**Write real code, not pseudocode.** Pseudocode defers exactly the decisions that turn out
to be the work. If the real code cannot be written yet, that is a finding — say what blocks
it.

Every step names the `FR`/`AC` ids it satisfies and has a `Done when` line that is
checkable without judgement.

## Files to Change

A table, exhaustive, no surprises later:

| File | Change | Lines | New? |
|---|---|---|---|
| `src/orders/lib/premium-order-tag.ts` | the shared helper | ~40 | new |
| `src/orders/create-oms-order.ts` | append tag at 644 | ~6 | edit |
| `src/orders/lib/premium-order-tag.spec.ts` | unit tests | ~120 | new |

Include test files and migrations. A plan that lists three source files and no tests has
under-estimated itself.

Note the traps: files that are not formatter-clean (run the formatter on **new files
only**), existing typos in schemas or filenames that must be preserved because renaming
them is breaking.

## Testing Plan

What proves it, at the cheapest level that can:

| Level | What it covers | Where |
|---|---|---|
| unit | the threshold decision, every boundary in `BR` | `premium-order-tag.spec.ts` |
| integration | the tag reaching the outbound payload on both paths | `create-oms-order.spec.ts` |
| manual | confirming behaviour in the external system | staging walkthrough |

Point at `test-cases.md` and `test-cases.csv` for the enumeration — do not duplicate the
rows here. This section is the strategy; those files are the list.

Close with the honest count: `43 cases, 37 testable today, 6 blocked on Q-1`.

## Risks / Considerations

Each risk gets **arithmetic or a mechanism**, not a category.

> **Reconciliation drift.** Existing orders were created before the tag existed, so any
> report filtering on it under-counts by the full back catalogue — roughly 2,400 orders.
> Mitigation: the report filters on order date as well, or a one-off backfill runs first.
> Not mitigating is a valid choice, but it has to be a choice.

"There is a risk of data inconsistency" is not a risk, it is a word. Name what breaks, how
big it is, and what you would do.

Include what you could **not** verify, and the one test that would settle it.

## Acceptance Criteria

The spec's `AC-n` list, each mapped to the step that satisfies it and how it is proven:

| AC | Satisfied by | Proven by |
|---|---|---|
| AC-1 | Step 2 | `premium-order-tag.spec.ts` — boundary at threshold |
| AC-7 | Step 4 | manual, staging — blocked on Q-1 |

Every `AC` from the spec appears. One with no step is either missed or out of scope, and
this table is where that becomes visible before the code is written.

## Commit Message

A real, copy-pasteable block. Conventional Commits, ticket id in the subject, body
explaining **why** — the diff already shows what.

```
feat(orders): tag premium orders above threshold on create and edit [TWP-5704]

Orders at or above the premium threshold are now marked at creation and on
edit confirm, so fulfilment can route them to insured shipping without a
manual read.

The threshold comparison uses the post-discount payable value, passed into the
shared helper by each caller — the create and edit paths derive that value
differently, so deriving it inside the helper would apply one path's definition
to both.

Removal is not implemented: the external tag endpoint merges and cannot unset
(Q-1).

Refs: FR-1, FR-3, BR-1..BR-3, AC-1..AC-11
```

Rules:

- Subject: `type(scope): imperative summary [TICKET-ID]`, under 72 characters
- Body: why, and the one non-obvious decision. Wrap at 72
- Note what is deliberately **not** in the commit, with its question id
- `Refs:` line listing the spec ids closed
- One commit per plan unless the plan says otherwise — if it splits, give each commit its
  own block under a sub-heading

---

## Before handing it over

- Every claim in `Current State` has a `file:line`, or is marked unverifiable with a reason
- Every `Must` requirement has a row in `Requirements` and a step
- Every `AC` has a row in `Acceptance Criteria`
- `Implementation Steps` contains real code
- The estimate **branches** on the open questions: `32h if Q-1 resolves to replace, 45h+ if
  merge`. A single number hides the unknown that decides the cost
- Shared logic appears in exactly one file
- `Commit Message` is complete and pasteable, including the `Refs:` line
