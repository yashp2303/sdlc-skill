# `spec.md` — the format

Business-facing. The reader owns the requirement, not the codebase. They must be able to
approve or reject this document without opening a single source file.

**Therefore: no file paths, no function names, no signatures, no technology choices, no
estimates.** Those live in `plan.md`. If a sentence here cannot be evaluated by someone
who has never seen the repo, it is in the wrong document.

## The section list

Edit this list to change the house format. The skill follows whatever is written here.

```
1.  Document Information          Title · Version · Date · Status · Owner
2.  Executive Summary
3.  Business Problem
4.  Business Goal
5.  Scope
    5.1 In Scope
    5.2 Out of Scope
    5.3 Future Scope
6.  Actors / Users
7.  Functional Requirements       FR-n
8.  Business Rules                BR-n
9.  User Flows
10. Acceptance Criteria           AC-n, Given / When / Then
11. Edge Cases
12. Non-Functional Requirements
13. Dependencies & Assumptions
14. Open Questions                Q-n, each with a default
15. Revision History
```

Sections 1–6 are fixed. Sections 7–15 are the working default. Every document gets every
section — an empty one says "considered, nothing found", which is information. Write
`None.` and move on; do not delete the heading.

---

## 1. Document Information

A two-column table, five rows, no prose.

| Field | Rule |
|---|---|
| Title | the feature, not the ticket summary. `Premium Order Tagging — POS to OMS` |
| Version | `0.1` draft · `1.0` approved · `1.1`+ post-approval change. Bump with Revision History |
| Date | `YYYY-MM-DD`, the date of **this** version |
| Status | `Draft` · `In Review` · `Approved` · `Superseded`. Never leave blank |
| Owner | a person's name. Not a team, not "TBD" — an unowned spec does not get decided |

Add `Ticket` as a linked row above Title. It is what everyone searches by.

## 2. Executive Summary

Three to five sentences. What changes, for whom, and what becomes possible. A reader who
stops here should be able to repeat the feature back correctly.

No background, no justification, no "this document describes". State the change.

## 3. Business Problem

What is wrong today, in business terms, with evidence.

**Every "today the system…" claim is verified against the code and says where.** Not
"orders are not currently tagged" but "orders carry no value-based tag today — verified
`create-oms-order.ts:644`, where the tag field is a hardcoded string". The business reader
skips the citation; the engineer needs it to trust the paragraph.

**If the requirement names something that does not exist** — a status, a field, a role, a
screen — that mismatch goes here, first, before anything else. It is the most valuable
sentence in the document. Do not demote it to an assumption or an open question.

Quantify the cost where a number exists. "Roughly 40 orders a month are handled manually"
is a business problem. "The process is inefficient" is a placeholder.

## 4. Business Goal

The decision or capability this unlocks — one or two sentences, measurable where possible.

Not "to tag premium orders" (that is the feature restated). "So the fulfilment team can
route high-value orders to insured shipping without reading each order manually" is a
goal: you can tell afterwards whether it was met.

## 5. Scope

### 5.1 In Scope
Bulleted. Each item is a capability, not a task. Concrete enough that its absence would be
noticed at review.

### 5.2 Out of Scope
The valuable half. Everything a reasonable reader might assume is included and is not —
each with a half-line reason.

`Removing a tag once applied — the external system merges tags and cannot unset (see Q-1)`

### 5.3 Future Scope
Deliberately deferred, with the condition that would bring it forward. Distinct from Out of
Scope: out means not this feature ever, future means not this release.

## 6. Actors / Users

A table: `Actor | Description | What they do in this feature`.

Include non-human actors — scheduled jobs, external systems, webhooks. They have
requirements too, and they are the ones nobody writes acceptance criteria for.

## 7. Functional Requirements

Numbered `FR-1`, `FR-2`, … Each is one behaviour, observable from outside, stated as
something the system does.

```
FR-3  When an order's payable value is at or above the premium threshold, the system
      marks that order as premium at the time of creation.
```

Rules:

- **One behaviour per requirement.** If it needs "and", it is two.
- **No technology.** No field names, no endpoints, no services.
- **Testable.** If you cannot imagine the check, it is a goal, not a requirement.
- **Never renumber.** `FR-3` is cited by the plan, the test cases and the commit.

Mark each `Must` · `Should` · `Could` in a trailing column. A spec where everything is
`Must` has not been prioritised.

## 8. Business Rules

Numbered `BR-1`, … The constants and invariants the requirements assume.

```
BR-1  The premium threshold is ₹2,00,000 on the post-discount payable value.
BR-2  Threshold comparison is inclusive — exactly ₹2,00,000 qualifies.
BR-3  Tax and shipping are excluded from the comparison value.
```

`BR-2` is the kind of rule that gets decided by accident in code and then argued about in
production. **Boundary inclusivity, rounding, and which value is compared are always
written here explicitly**, even when they feel obvious.

## 9. User Flows

Numbered steps per actor, happy path only. Alternatives belong in Edge Cases.

Keep it to the steps where the actor does or sees something. Internal hops are the plan's
business. A short fenced flow diagram is fine if it earns its space.

## 10. Acceptance Criteria

Numbered `AC-1`, … Given / When / Then. **Mechanically checkable** — a QA engineer must be
able to run it without asking a question.

```
AC-4  Given a cart with a post-discount payable of exactly ₹2,00,000
      When the order is placed
      Then the order is marked premium
```

- One criterion per behaviour, plus one per boundary in the business rules.
- Every `Must` requirement has at least one criterion. Cover the map both ways.
- **Still no technology.** "Then the order is marked premium", not "then
  `note_attributes.premium_order` is `true`". The plan binds it to a mechanism.
- If a criterion has variants — three payment methods — that is three criteria.

## 11. Edge Cases

A table: `Case | Expected behaviour | Risk if wrong`.

Work the standard families every time, and say `n/a` with a reason rather than omitting:

```
empty · exactly one · many · exact boundary · one unit either side of it
zero · negative · null · rounding · concurrency · retry · partial completion
records created before this feature existed
```

The last one is the most-missed and the most expensive. Existing data does not satisfy new
invariants.

`Risk if wrong` is what makes this table get read. "Under-tags every discounted order" is
a risk; "incorrect behaviour" is filler.

## 12. Non-Functional Requirements

Only what actually constrains this feature. Performance budget, volume, availability,
auditability, permissions, data retention, localisation.

Each must have a number or a rule. "Must be fast" is not an NFR; "must not add more than
50ms to order placement" is. If nothing genuinely applies, write `None beyond existing
platform standards.`

## 13. Dependencies & Assumptions

Two short lists, kept apart because they fail differently.

**Dependencies** — things that must exist or happen elsewhere. Name the owner.
**Assumptions** — things believed true and not verified, each with what breaks if false.

```
A-2  Assumed: the external system accepts additional attributes without a schema change.
     If false: FR-3 and FR-5 both need a coordinated release with that team.
```

An assumption with no consequence stated is decoration. If you can verify it, verify it
instead and move it to the Business Problem with its citation.

## 14. Open Questions

A table: `Q-n | Question | Why it matters | Default if unanswered | Owner`.

**Every question has a default**, chosen so that being wrong changes one function, not the
design. Order by impact on the estimate, not by discovery order.

Lead the section with the count that blocks work: "Q-1 gates the removal path entirely;
the other three can be defaulted."

A question with no default is not a question, it is an unmade decision — and it stops the
plan from producing an estimate.

## 15. Revision History

`Version | Date | Author | Change`. One row per version, newest last. `0.1 | initial
draft` is a legitimate first row.

Once Status is `Approved`, every edit adds a row and bumps the version. A spec that changed
silently after approval is worse than no spec, because decisions were made against the old
text.

---

## Before handing it over

- Every `today the system…` sentence carries a `file:line`, or is marked unverified with a
  reason
- Every `Must` requirement maps to at least one `AC-n`
- Every boundary in `BR` has an `AC` sitting exactly on it
- Every open question has a default
- No file path, signature, or estimate anywhere in the document
- Nothing named in the requirement is missing from the codebase without that being said in
  §3
