# `research.md` — the 25-section format

One file per ticket, at `docs/<TICKET-ID>-<slug>/research.md`.

**All 25 sections, always, in this order.** An empty section says "checked, nothing found",
which is information — write `None found.` and move on. Never delete a heading.

```
 1  Ticket Summary                    14  Impact Analysis
 2  Business Understanding            15  Risks                    RISK-n
 3  Requirements                      16  Technical Blockers
      US · FR · BR · VR · DR ·        17  Business Blockers
      SC · AC · EC                    18  Environment Blockers
 4  Doubts / Ambiguities              19  Test Impact              TC-n
 5  Open Questions          OQ-n      20  Recommended Implementation
 6  Assumptions             ASM-n     21  Files Likely To Change
 7  Existing Code Analysis            22  Files That Should NOT Be Changed
 8  Similar Existing Implementations  23  Implementation Order
 9  Git History Findings              24  Research Evidence
10  API Analysis            API-n     25  Final Readiness
11  Database Analysis                       READY / NEEDS CLARIFICATION / BLOCKED
12  Integration Analysis    INT-n
13  Dependency Analysis
```

## ID prefixes

Every numbered item is citable. **Never renumber** — these ids get quoted in the spec, the plan,
commits and Jira comments, and a renumber silently invalidates every citation.

| Prefix | Means | Section |
|---|---|---|
| `US-n` | User Story — "As a *role*, I want *capability*, so that *outcome*" | 3 |
| `FR-n` | Functional Requirement — one observable behaviour | 3 |
| `BR-n` | Business Rule — a constant, threshold or invariant | 3 |
| `VR-n` | Validation Rule — what is accepted and rejected, with the error | 3 |
| `DR-n` | Data Rule — shape, source of truth, retention, defaults, nullability | 3 |
| `SC-n` | Scenario — a concrete end-to-end path through the feature | 3 |
| `AC-n` | Acceptance Criterion — Given / When / Then, mechanically checkable | 3 |
| `EC-n` | Edge Case — boundary, empty, null, concurrent, pre-existing data | 3 |
| `OQ-n` | Open Question — needs an answer from a named owner | 5 |
| `ASM-n` | Assumption — believed, not verified, with what breaks if false | 6 |
| `API-n` | An endpoint or operation this touches | 10 |
| `INT-n` | An integration point, internal or third-party | 12 |
| `RISK-n` | A risk, with arithmetic | 15 |
| `TC-n` | A test case this ticket makes necessary | 19 |

`AC-n` and `EC-n` minted here carry forward into `spec.md` unchanged, and `TC-n` becomes the
`test-cases.csv` rows. That continuity is the whole point of doing research first.

---

## Header

```markdown
# Ticket Research Report — <TICKET-ID>

| | |
|---|---|
| **Ticket** | [<TICKET-ID>](url) |
| **Title** | <the ticket's own title, verbatim> |
| **Source** | Jira · Slack · verbal |
| **Readiness** | **READY** · **NEEDS CLARIFICATION** · **BLOCKED** — matches §25 |
| **Author** | <who researched it> |
| **Checked against** | branch `<branch>` at `<sha>`, env `ustage`, YYYY-MM-DD |
```

`Checked against` is not decoration — a finding is only true for a commit.

## 1. Ticket Summary

Three to five sentences: what is being asked, for whom, and the one thing that makes it harder or
easier than it looks. No analysis, no opinion yet.

A reader who stops here should be able to repeat the ticket back correctly.

## 2. Business Understanding

*Why* this is being asked — the decision or capability it unlocks, in business terms. Quantify
where a number exists ("~40 orders a month handled manually").

If the ticket does not say why, that absence is a finding: note it and raise it as an `OQ`. A
ticket with no stated business reason cannot be prioritised or descoped safely.

## 3. Requirements

The longest section. Eight subsections, each with its own prefix. Derive them from the ticket
**and** from what the code shows — a requirement the ticket implies but never states still gets
an id.

### 3.1 User Stories — `US-n`

```
US-1  As a store operator, I want high-value orders flagged automatically,
      so that I do not have to check each order manually before dispatch.
```

One role, one capability, one outcome. If it needs "and", it is two stories.

### 3.2 Functional Requirements — `FR-n`

One observable behaviour each, stated as something the system does. **No technology** — no field
names, no endpoints. Mark each `Must` / `Should` / `Could`; a list where everything is `Must` has
not been prioritised.

### 3.3 Business Rules — `BR-n`

The constants and invariants the requirements assume. **Always state boundary inclusivity,
rounding, and which value is compared** — these get decided by accident in code and argued about
in production.

```
BR-1  The premium threshold is ₹2,00,000.
BR-2  Comparison is strictly greater — exactly ₹2,00,000 does NOT qualify.
BR-3  The compared value is the post-discount payable, excluding tax and shipping.
```

### 3.4 Validation Rules — `VR-n`

What is accepted, what is rejected, and **the specific error** for each rejection. Not "invalid
input is rejected" but the code or message.

```
VR-2  A null or non-numeric order value is rejected with INVALID_ORDER_VALUE.
```

### 3.5 Data Rules — `DR-n`

Shape and ownership: which store is the source of truth, what is nullable, what the default is,
what happens to records that predate the feature, retention.

```
DR-3  Records created before this feature carry no flag — absence means "not evaluated",
      not "not premium". Reports must filter on date as well.
```

### 3.6 Scenarios — `SC-n`

Concrete end-to-end paths, named. These are the spine that §19's test cases hang off.

```
SC-1  New order placed above threshold → flagged at creation
SC-2  Existing order edited from below to above threshold → flagged at confirm
SC-3  Existing order edited from above to below → flag must clear (see OQ-1)
```

### 3.7 Acceptance Criteria — `AC-n`

Given / When / Then, **mechanically checkable** — a QA engineer runs it without asking a
question. One per behaviour, plus one sitting exactly on each `BR` boundary. Still no technology.

### 3.8 Edge Cases — `EC-n`

Work the standard families every time and write `n/a` with a reason rather than omitting:

```
empty · exactly one · many · exact boundary · one unit either side · zero · negative
null · rounding · concurrent · retried · partial completion · records predating the feature
```

The last one is the most-missed and the most expensive.

## 4. Doubts / Ambiguities

Where the ticket is unclear, self-contradictory, or uses a word the system does not have.
**This is where the name check lands**, and it is the highest-value section in the file.

For every entity, status, field, route, screen, role or flag the ticket names:

```markdown
| Name in the ticket | Exists? | Reality |
|---|---|---|
| `completed` status | ❌ **no such status** | enum is `PLACED`/`CONFIRMED`/`DISPATCHED`/`DELIVERED` — `order-status.enum.ts:12` |
| `premium_order` field | ⚠️ not a field | a `note_attributes` entry — `create-oms-order.ts:648` |
| "Edit Order" screen | ✅ | `views/edit-order/` |
```

Mismatches first. For each, name **both** words and what to ask:

> The ticket says "completed". No such status exists. If they mean `DELIVERED` the window logic
> applies; if `CONFIRMED`, it does not. **Ask before estimating.**

**Never silently substitute the nearest real name.** A doubt resolved by guessing becomes a
defect later.

## 5. Open Questions — `OQ-n`

```markdown
| ID | Question | Why it matters | Default if unanswered | Owner |
|---|---|---|---|---|
| OQ-1 | Does the OMS merge or replace `note_attributes`? | decides whether a flag can ever clear | assume merge; gate SC-3 behind OQ-1 | OMS team |
```

**Every question gets a default**, chosen so being wrong changes one function, not the design.
Order by impact on the estimate. Lead with which block work.

A question with no default is not a question — it is a decision you declined to make, and it
stops the estimate.

## 6. Assumptions — `ASM-n`

Things believed true and **not** verified, each with the consequence if false. Distinct from `OQ`:
an assumption is something you are proceeding on; a question is something you are waiting for.

```
ASM-2  Assumed the external system accepts extra attributes without a schema change.
       If false: FR-1 and FR-3 both need a coordinated release with that team.
```

An assumption with no stated consequence is decoration. **If you can verify it, verify it** and
move it to §7 with its `file:line`.

## 7. Existing Code Analysis

What the code does **today**, every claim with `file:line`. This section and §24 are what make
the report trustworthy.

```markdown
`create-oms-order.ts:644` — `tags` is a hardcoded string `"pos_order"`, not an array.
                            Adding a second value means changing the type, not the value.
`order-edit/confirm.ts:212` — sends no tags at all; the edit path is a separate builder.
```

Cover: the entry point, the current behaviour, the guards (`throw`, early return, validation
branch) near the change, and **where each relevant number is computed on each path**. Two paths
computing the same quantity differently is the most common trap in this stack and is invisible
unless you open both.

## 8. Similar Existing Implementations

Most tickets are extensions. Name the nearest thing that already exists, and say whether the
pattern should be followed or deliberately broken.

Also record whether the rule is **already duplicated**. If it is, saying so here is worth more
than any other sentence in the report.

## 9. Git History Findings

```bash
git log --oneline -20 -- <the files you expect to change>
git log -S'<the identifier>' --oneline
```

What to look for: when this area last changed and why · whether this has been attempted and
reverted · whether a comment says "temporary" and is now two years old · who last touched it
(your reviewer) · whether a related migration is mid-flight.

**A prior reverted attempt is the single most valuable thing this section can find.**

## 10. API Analysis — `API-n`

Every endpoint or operation the ticket touches.

```markdown
| ID | Operation | Where | Auth | Change |
|---|---|---|---|---|
| API-1 | `createOrder` mutation | `orders.resolver.ts:88` | Cognito JWT | payload gains one attribute |
| API-2 | `POST /request-return-replacement/place` | `oms` — `return-replacement.controller.ts:64` | `x-api-key` | none, read only |
```

Note request/response shape changes, whether the change is **backwards compatible**, and any
unguarded endpoint you touch.

## 11. Database Analysis

Which store, which collection or table, which fields, and **who owns them**. In this stack that
last part matters more than usual: the authoritative order document lives in a service outside
this workspace.

Cover: new or changed fields · indexes needed · migration or backfill needed · nullability ·
whether existing rows satisfy the new invariant (they usually do not).

## 12. Integration Analysis — `INT-n`

Every internal service and third party in the path.

```markdown
| ID | Integration | Direction | Effect of this ticket |
|---|---|---|---|
| INT-1 | Serverless OMS | outbound | receives one extra attribute; behaviour on receipt UNVERIFIABLE — see OQ-1 |
| INT-2 | Freshdesk / Flowcall | outbound | none |
```

**Never infer an external system's behaviour from its client code.** Mark it unverifiable and
raise an `OQ`.

## 13. Dependency Analysis

What must exist or happen elsewhere before this can ship — another team's release, a config
value, an SSM parameter, a package upgrade, a feature flag. Name the **owner** for each.

Also: does this ticket block or get blocked by another ticket in flight?

## 14. Impact Analysis

What else changes as a consequence. The section that catches the thing nobody thought of.

Cover: other call sites of anything you touch (**count the callers**) · reports and dashboards
reading this data · the legacy path as well as the OMS path · downstream consumers · existing
records · performance on the hot path · anything cached.

```markdown
`createOMSOrder` has **3 callers** — logic added at one misses two:
  `create-order.ts:120` · `cash-and-carry.ts:88` · `edit-order-oms-confirm.ts:210`
```

## 15. Risks — `RISK-n`

Each risk gets **arithmetic or a mechanism**, plus a mitigation or an explicit decision not to
mitigate.

```
RISK-1  Back catalogue. ~2,400 pre-existing orders carry no flag, so any report filtering on
        it under-counts by the full history.
        Mitigation: filter on date too, or backfill once. Not mitigating is valid — but it
        has to be a choice.
```

"There is a risk of inconsistency" is not a risk, it is a word.

## 16. Technical Blockers

Code or architecture reasons work cannot start or would be thrown away. Each cites an `OQ` or a
`file:line`. Split **hard** (cannot start) from **soft** (can start on a default, may need
rework, with the rework cost).

## 17. Business Blockers

Missing decisions, approvals, or requirements owners. A threshold nobody has signed off, a policy
question, a legal or finance sign-off. Name who decides.

## 18. Environment Blockers

Access, data, config or infrastructure needed to build **or verify** this: an account of a
certain role, seed data, a third-party sandbox, a deployed dependency, an SSM parameter, a
permission.

**This is the section that decides whether QA can actually run**, so be specific about which
`TC-n` each blocker blocks.

## 19. Test Impact — `TC-n`

Not the full suite — that is `/feature-docs`'s job. This is **what this ticket makes necessary**,
enumerated well enough to size the QA effort.

```markdown
| ID | Scenario | Type | Level | Covers | Blocked by |
|---|---|---|---|---|---|
| TC-1 | value exactly at threshold | edge | unit | AC-2, BR-2 | — |
| TC-2 | value one unit above | positive | unit | AC-1 | — |
| TC-3 | null value | negative | unit | VR-2 | — |
| TC-9 | flag clears when value drops | positive | manual | AC-7, SC-3 | OQ-1 |
```

Cover **positive, negative and every edge family** from `EC-n`. Negative rows should outnumber
positive ones — every guard found in §7 is a negative case. Close with the honest count:
*"31 cases, 26 runnable today, 5 blocked on OQ-1."*

Also note regression surface: what existing tests touch this code and might break.

## 20. Recommended Implementation

The approach you would take, in a paragraph or two, plus **the one design decision** with the
alternative you rejected and why.

Shared logic goes in one place. If the same rule would land in two files, say so here — that is
the finding.

Not code. Not step-by-step. That is `plan.md`.

## 21. Files Likely To Change

```markdown
| File | Change | New? | Confidence |
|---|---|---|---|
| `src/orders/lib/premium-order-tag.ts` | the shared rule | new | high |
| `src/orders/lib/create-oms-order.ts` | call the helper | edit | high |
| `src/orders/lib/edit-order-oms-confirm.ts` | call the helper | edit | medium — depends on OQ-1 |
```

Include tests and migrations. A list with three source files and no test files has
under-estimated itself. `Confidence` is honest, not aspirational.

## 22. Files That Should NOT Be Changed

The section that prevents scope creep and accidental breakage. For each, **why**.

```markdown
| File | Why not |
|---|---|
| `serverless-oms-connection/service.ts` | wraps new-OMS responses in legacy-compatible shapes; every legacy caller depends on it |
| `order.schema.ts` | order state belongs to the external OMS — do not add state fields here |
| anything matching `replacemt_window` | typo is load-bearing; renaming is breaking |
| `pos-app/schema.gql` | generated, code-first — never hand-edit |
```

Also list files a formatter would rewrite if touched — these repos are not formatter-clean.

## 23. Implementation Order

What unblocks what, ordered by **risk and dependency** — not file order. Map each step to the
`AC-n` it satisfies, and mark the first step that is safe to stop after.

```
1  shared rule + unit tests          AC-1..AC-4   ← safe stopping point
2  creation call site                AC-1, AC-5
3  edit-confirm call site            AC-6
4  removal path                      AC-7         ← gated on OQ-1, do not start
```

## 24. Research Evidence

The audit trail: what you actually ran and read, so the next person can re-run it.

```bash
rg 'premium_order' --type ts -n        # 1 hit — the write site only, 0 readers
rg 'createOMSOrder\(' --type ts -n     # 3 callers
git log --oneline -20 -- src/orders/lib/create-oms-order.ts
```

List the files you opened, the greps and their result counts, and **what you could not check and
why**. Silence here reads as thoroughness that did not happen.

## 25. Final Readiness

One of exactly three verdicts, expanded into an action:

```markdown
**NEEDS CLARIFICATION** — OQ-1 blocks SC-3 / AC-7 / TC-9 only.

Ready now: SC-1, SC-2 — creation and edit-confirm, fully verified.
Blocked: SC-3 (flag removal) on OQ-1, owner OMS team, one answer unblocks it.

Next:
1. Ask the OMS team OQ-1 — one message.
2. Ask the requester about the `completed` mismatch in §4.
3. Run `/feature-docs <TICKET-ID>` for SC-1 and SC-2, scoping SC-3 out and citing OQ-1.

Estimate, conditional: **6h** for SC-1 + SC-2. **+4h** if OQ-1 resolves to replace;
SC-3 is **not possible** if it resolves to merge, and the ticket needs rescoping.
```

| Verdict | Means |
|---|---|
| **READY** | no unanswered `OQ` blocks anything. Run `/feature-docs`. |
| **NEEDS CLARIFICATION** | some scope is ready, some needs an answer. Say exactly which, and proceed on the ready part. |
| **BLOCKED** | nothing can safely start. Name the one answer that changes that. |

Estimates here are **always conditional**. A single number hides the unknown that decides the
cost.

---

## Before handing it over

- All 25 sections present, in order, none deleted
- Every claim in §7 and §14 has a `file:line`
- §4 lists **every** name the ticket used, mismatches first
- Every `OQ` has a default **and** an owner
- Every `ASM` has a consequence if false
- Blockers are split across §16/§17/§18 and each cites an `OQ` or a `file:line`
- §19 has more negative than positive cases, or says why not
- §22 is not empty
- §24 shows real commands with real result counts
- §1 header `Readiness` and §25 verdict agree
- The estimate branches on the open questions
- Nothing in the file is code — §20 is an approach, not an implementation
