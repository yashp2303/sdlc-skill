---
name: ticket-research
description: Take a ticket title and description, research the actual code, and write one research.md per ticket — verified facts with file:line, every name checked for existence, open questions with defaults, and the blockers. Read-only; it writes no code and no spec. Use when a ticket arrives and you need to know what it really touches before estimating or planning. Trigger: /ticket-research
---

# ticket-research

You paste the ticket. This reads the codebase and writes **one file**:

```
docs/<TICKET-ID>-<slug>/research.md
```

It answers exactly one question: **can this ticket be estimated and planned yet, and if not,
what is missing?**

It writes no code, no spec, no plan. It ends at a decision point.

## Run it

```
/ticket-research <TICKET-ID> <title + full description, pasted>
```

Paste the whole description, including the messy parts. Screenshots-as-text, Jira comments,
half-finished acceptance criteria — all of it. The gaps in the ticket are findings, and you
cannot see a gap you were not shown.

If no ticket id is given, ask for one — the folder needs it.

## Where it fits

```
/ticket-research   ticket → research.md          ← you are here. Is this even plannable?
      │
      ▼
/feature-docs      research.md → spec · plan · test-cases · qa-sheet
      │
      ▼
/tsc-ticket        implement · verify · report
```

`research.md` is the input to `/feature-docs`. The spec's Business Problem and Open Questions
sections come almost verbatim from it — which is the point. Investigate once, cite forever.

## The one rule

**Every claim about the code is verified by reading the code, and says where.**

Not "orders are created without tags" but ``create-oms-order.ts:644 — `tags` is a hardcoded
string, not an array``.

A research doc full of plausible statements is worse than no research doc, because it gets
believed and then estimated against. If you could not verify something, it becomes a numbered
open question — never a confident sentence.

## Step 1 — Check every name the ticket uses

**Do this before anything else.** Grep for every entity, status, field, module, route, screen,
role and flag the ticket names.

| Result | What it means |
|---|---|
| exists, one place | note the `file:line` |
| exists, several places | list them all — this is usually where the estimate goes wrong |
| **does not exist** | **stop. This is the headline finding.** |

A ticket saying "when the order is *completed*" when no `completed` status exists anywhere has
already told you its real problem: the requester and the system disagree about the domain. That
mismatch goes at the very top of `research.md`, above everything else, and it usually changes
the ticket rather than the code.

Never quietly translate a non-existent name into the nearest real one. Say both, and ask which
was meant.

## Step 2 — Establish the shape of the work

For each thing the ticket touches, find and record with `file:line`:

- **Every write site.** There may be one, three, or none. "None" changes the ticket completely.
- **Every read site.** One writer and zero readers is a different feature from one writer and
  five consumers. Put the grep result in verbatim.
- **The nearest existing implementation.** Most tickets are extensions. Name the file, or the
  plan will specify a second parallel version of something that already exists.
- **Where the numbers come from**, on *each* path. Two paths computing the same quantity
  differently is the single most common trap — and it is invisible unless you open both.
- **Shared vs duplicated logic.** If the rule already lives in two places, saying so now is
  worth more than any other sentence in the document.
- **What is out of reach.** Anything outside this workspace. Say so explicitly and turn it into
  an open question. Never infer an external service's behaviour.

Put the actual greps in the document. It lets the next person re-run them and see whether the
answer has changed.

## Step 3 — Turn what you could not verify into numbered questions

Every open question gets a **default**, chosen so that being wrong changes one function rather
than the design:

```
Q-2 | Does the external system merge or replace the attribute list on update?
    | Why it matters: decides whether a value can ever be cleared
    | Default: assume merge; gate the removal path behind Q-2
    | Owner: OMS team
```

A question with no default blocks the estimate. A document full of undefaulted questions is a
list of decisions you declined to make.

Order questions by **impact on the estimate**, not by discovery order, and lead the section with
which ones actually block work.

## Step 4 — Separate blockers from risks

| Kind | Test | Goes in |
|---|---|---|
| **Hard blocker** | work cannot start, or would be thrown away | Blockers, with the question id |
| **Soft blocker** | work can start on a default, may need rework | Blockers, marked soft |
| **Risk** | work proceeds; something might go wrong later | Risks, with arithmetic |

"There is a risk of inconsistency" is not a risk, it is a word. Name what breaks, how big it is,
and what you would do about it.

## Step 5 — Enumerate the test impact (§19)

Every guard you found in §7 is a **negative** test case. Every family in `EC-n` is an edge case.
Every `AC-n` is at least one positive case. Enumerate them as `TC-n` with type and level, and
mark which are blocked by an `OQ`.

This is not the full suite — `/feature-docs` writes that. This is enough to **size the QA effort**
and to hand `/feature-docs` a starting list it must expand rather than invent.

**Negative cases should outnumber positive ones.** If they do not, you have not read the guards.

## Step 6 — End with a verdict (§25)

Exactly one of three, expanded into an action:

| Verdict | Means |
|---|---|
| **READY** | no unanswered `OQ` blocks anything. Run `/feature-docs`. |
| **NEEDS CLARIFICATION** | part of the scope is ready, part needs an answer. Say **which** `SC-n` are ready and proceed on those. |
| **BLOCKED** | nothing can safely start. Name the one answer that changes that. |

Plus a **conditional** estimate — "6h, +4h if OQ-1 resolves to replace, impossible if merge". A
single number hides the unknown that decides the cost.

A report that ends without a verdict has described the problem and made no decision.

## The output format — 25 sections, always

Full section-by-section rules in `references/research-format.md`. Template in
`templates/research.md`. **Every section appears in every report**, in this order. An empty one
says "checked, nothing found" — write `None found.`, never delete the heading.

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

### The ID prefixes, and why they matter

| Prefix | Means | Prefix | Means |
|---|---|---|---|
| `US-n` | User Story | `EC-n` | Edge Case |
| `FR-n` | Functional Requirement | `OQ-n` | Open Question |
| `BR-n` | Business Rule | `ASM-n` | Assumption |
| `VR-n` | Validation Rule | `API-n` | Endpoint / operation |
| `DR-n` | Data Rule | `INT-n` | Integration point |
| `SC-n` | Scenario | `RISK-n` | Risk |
| `AC-n` | Acceptance Criterion | `TC-n` | Test case |

**Never renumber.** These ids are cited by `spec.md`, `plan.md`, commits and Jira comments.
`AC-n` and `EC-n` carry into the spec unchanged; `TC-n` becomes the `test-cases.csv` rows. That
continuity is why research runs first.

### The three sections that carry the report

- **§4 Doubts / Ambiguities** — where the name check lands. Highest value per line in the file.
- **§7 Existing Code Analysis** — every claim with `file:line`. Nothing else is a fact.
- **§25 Final Readiness** — the verdict. A report that ends without one has made no decision.

## Method reference

`references/investigation-method.md` has the grep strategy, the stack-specific traps worth
checking every time, and what "verified" means for each kind of claim.

## Two failure modes

**A research doc that reads like the ticket.** If §4 has no `file:line`, you reformatted the
ticket instead of researching it. Go back to the code.

**A doc with no mismatches and no questions.** Occasionally true. Usually it means the name check
was skipped and the unverifiable parts were written as confident prose. Re-read §2 and §9 and ask
what you actually opened.
