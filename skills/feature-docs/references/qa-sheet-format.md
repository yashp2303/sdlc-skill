# `qa-sheet.md` — the format

Reviewer-facing. This is the **sign-off** document: what must be true before this ships,
who checked it, in what environment, and what was knowingly left uncovered.

It is not a second copy of the test cases. `test-cases.csv` holds the rows and their status;
this sheet holds the things a CSV has no column for — the environment a manual run happened
in, the defects found, the blocking questions, and what was accepted as not covered **with a
name against it**.

Rows here mirror the CSV. **When they disagree, the CSV wins.** Re-derive rather than
reconcile by eye.

## The section list

```
Header table
A. Before any testing can start
B. Questions that must be answered
C. Correctness checks against the code
D. Acceptance criteria — the spec's own list
E. Before opening the PR
Environment
Defects found
Not covered, and why
Sign-off
```

Lettered sections are checkpoint groups: things a human ticks. The tail sections are records.

---

## Header table

```markdown
# QA Sheet — <Feature>

| | |
|---|---|
| **Ticket** | [TWP-5704](url) — <title> |
| **Spec** | [`spec.md`](./spec.md) — the criteria this sheet verifies |
| **Plan** | [`plan.md`](./plan.md) — where each behaviour is implemented |
| **Scenarios** | [`test-cases.md`](./test-cases.md) — grouped index |
| **Cases** | [`test-cases.csv`](./test-cases.csv) — source of truth · `.xlsx` view |
| **Last reviewed** | YYYY-MM-DD |
| **Reviewed by** | a person's name |
| **Method** | static read + n unit + n integration + manual walkthrough |
| **Suite at review** | n suites / n tests passing |
| **Verdict** | `Not started` · `In progress` · `Passed with gaps` · `Passed` · `Blocked` |
```

`Verdict` is one word and it is the first thing anyone reads. `Passed with gaps` is an
honest and common answer — use it rather than inflating to `Passed`.

## A. Before any testing can start

The preconditions. Seed data, feature flags, permissions, an account of each role, an
environment that has the dependency deployed.

```markdown
| # | Precondition | Ready | Notes |
|---|---|---|---|
| A1 | staging has the threshold config set to ₹2,00,000 | ⬜ | BR-1 |
| A2 | a test cart can reach ₹2,00,000 post-discount | ⬜ | |
| A3 | external tag endpoint reachable from staging | ⬜ | blocks D7–D9 |
```

Each unmet precondition blocks specific rows — name them. That is what turns "testing is
blocked" into "three rows are blocked, the other forty can run".

## B. Questions that must be answered

The spec's open questions, restated as *what QA cannot verify until they are answered*.

```markdown
| Q | Question | Blocks | Owner | Answer |
|---|---|---|---|---|
| Q-1 | does the external endpoint merge or replace tags? | QA-031..036 | OMS team | ⬜ |
```

`Blocks` cites CSV ids. An unanswered question with nothing blocked does not belong here —
it belongs in the spec only.

## C. Correctness checks against the code

Checks a reviewer performs by **reading** rather than running — cheap, and they catch the
class of bug that tests written from the same misunderstanding will happily pass.

```markdown
| # | Check | file:line | OK | Note |
|---|---|---|---|---|
| C1 | boundary comparison is `>=`, not `>` | `premium-order-tag.ts:24` | ⬜ | BR-2 |
| C2 | the value passed is post-discount on both paths | `create-oms-order.ts:648`, `confirm.ts:214` | ⬜ | the known trap |
| C3 | shared helper called by both paths, no second copy | | ⬜ | |
| C4 | no secret or key added to a log or URL | | ⬜ | |
```

Every row cites `file:line` once the code exists. C2-style rows — *the same quantity derived
on two paths* — are the highest-value checks in this stack and belong in every sheet where
two paths exist.

## D. Acceptance criteria — the spec's own list

Every `AC-n` from the spec, verbatim, each with how it was verified.

```markdown
| AC | Criterion | How verified | Result |
|---|---|---|---|
| AC-1 | order at threshold is marked premium | QA-001 unit | ⬜ |
| AC-7 | tag removed when value drops below | QA-031 manual | 🔲 blocked Q-1 |
```

**Every criterion appears**, including the ones that cannot be checked yet — those get `🔲`
and the blocking id. A missing row reads as passed.

## E. Before opening the PR

The mechanical gate. Same list every time, so nothing is remembered selectively.

```markdown
| # | Check | Done |
|---|---|---|
| E1 | new tests pass | ⬜ |
| E2 | typecheck: baseline n → with change n | ⬜ |
| E3 | lint: baseline n → with change n | ⬜ |
| E4 | no unrelated reformatting in the diff | ⬜ |
| E5 | existing typos in schemas/filenames preserved | ⬜ |
| E6 | no secrets added, none logged | ⬜ |
| E7 | CSV statuses match reality; no `✅` without evidence | ⬜ |
| E8 | commit message matches `plan.md` | ⬜ |
```

**E2 and E3 record both numbers.** These repos have pre-existing failures, so a raw count
proves nothing — `54 at HEAD, 53 with my change` is evidence; `53 errors` is noise.

## Environment

Where the manual rows were actually run. This is the section that makes a result
reproducible six weeks later.

```markdown
| | |
|---|---|
| Environment | staging / ustage |
| Build | commit sha or version |
| Date | YYYY-MM-DD |
| Data | which store, which account, which cart |
| Tester | name |
```

If a result came from a different environment than the rest, say so on that row. Results
silently mixed across environments are the hardest defects to chase.

## Defects found

```markdown
| # | Severity | Description | Case | Status | Ticket |
|---|---|---|---|---|---|
| D1 | major | edit path sends no tag when only quantity changes | QA-018 | open | TWP-xxxx |
```

Severity is `blocker` · `major` · `minor` · `cosmetic`. Every defect gets a ticket id or an
explicit "not raised, accepted" with a name — a defect recorded only here is a defect that
gets lost.

## Not covered, and why

```markdown
| Area | Why not covered | Risk | Accepted by |
|---|---|---|---|
| tag removal end-to-end | external endpoint merges, cannot unset (Q-1) | premium tag persists after value drops | <name> |
```

**`Accepted by` is a person's name, never blank and never a team.** An unaccepted gap is an
untracked risk; the whole point of this table is that someone owned the decision.

Never leave the section empty by default. If nothing was excluded, write `Nothing excluded —
all 43 cases executed.`

## Sign-off

```markdown
| Role | Name | Date | Verdict |
|---|---|---|---|
| Developer | | | |
| QA | | | |
| Owner (from spec §1) | | | |
```

The Owner row is the same person named in `spec.md` §1. If nobody signs, the sheet says so
truthfully — an unsigned sheet is information.

---

## Before handing it over

- `Verdict` in the header is filled and matches the body
- Every `AC` from the spec has a row in D, including blocked ones
- Every `Q` blocking a case has a row in B with the ids it blocks
- E2 and E3 record **both** baseline and post-change numbers
- No `✅` anywhere without evidence
- `Not covered` has a real name in `Accepted by` on every row
- Counts agree with `test-cases.csv` — if not, the CSV is right
