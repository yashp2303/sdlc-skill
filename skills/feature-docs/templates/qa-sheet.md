# QA Sheet — <Feature name>

| | |
|---|---|
| **Ticket** | [<TICKET-ID>](<url>) — <title> |
| **Spec** | [`spec.md`](./spec.md) — the criteria this sheet verifies |
| **Plan** | [`plan.md`](./plan.md) — where each behaviour is implemented |
| **Scenarios** | [`test-cases.md`](./test-cases.md) — grouped index |
| **Cases** | [`test-cases.csv`](./test-cases.csv) — source of truth · `.xlsx` view |
| **Last reviewed** | <YYYY-MM-DD> |
| **Reviewed by** | <name> |
| **Method** | static read + <n> unit + <n> integration + manual walkthrough |
| **Suite at review** | <n> suites / <n> tests passing |
| **Verdict** | Not started |

---

## A. Before any testing can start

| # | Precondition | Ready | Notes |
|---|---|---|---|
| A1 | <config / flag / seed data> | ⬜ | BR-<n> |
| A2 | <account or role available> | ⬜ | |
| A3 | <dependency reachable from the environment> | ⬜ | blocks QA-0nn..0nn |

---

## B. Questions that must be answered

| Q | Question | Blocks | Owner | Answer |
|---|---|---|---|---|
| Q-1 | <from spec §14> | QA-0nn..0nn | <team> | ⬜ |

---

## C. Correctness checks against the code

| # | Check | file:line | OK | Note |
|---|---|---|---|---|
| C1 | <boundary comparison is the right operator> | `<file>:<line>` | ⬜ | BR-<n> |
| C2 | <the same quantity is derived identically on both paths> | `<file>:<line>`, `<file>:<line>` | ⬜ | the known trap |
| C3 | shared logic lives in one place, no second copy | | ⬜ | |
| C4 | no secret or key added to a log, URL, or commit | | ⬜ | |

---

## D. Acceptance criteria — the spec's own list

| AC | Criterion | How verified | Result |
|---|---|---|---|
| AC-1 | <verbatim from spec> | QA-001 unit | ⬜ |
| AC-2 | <verbatim from spec> | QA-0nn manual | 🔲 blocked Q-<n> |

<Every AC appears, including the ones that cannot be checked yet.>

---

## E. Before opening the PR

| # | Check | Done |
|---|---|---|
| E1 | new tests pass | ⬜ |
| E2 | typecheck: baseline <n> → with change <n> | ⬜ |
| E3 | lint: baseline <n> → with change <n> | ⬜ |
| E4 | no unrelated reformatting in the diff | ⬜ |
| E5 | existing typos in schemas/filenames preserved | ⬜ |
| E6 | no secrets added, none logged | ⬜ |
| E7 | CSV statuses match reality; no `✅` without evidence | ⬜ |
| E8 | commit message matches `plan.md` | ⬜ |

---

## Environment

| | |
|---|---|
| Environment | <staging / ustage / prod> |
| Build | <commit sha or version> |
| Date | <YYYY-MM-DD> |
| Data | <which store, account, cart> |
| Tester | <name> |

---

## Defects found

| # | Severity | Description | Case | Status | Ticket |
|---|---|---|---|---|---|
| D1 | <blocker/major/minor/cosmetic> | | QA-0nn | open | |

<Or: `None found.`>

---

## Not covered, and why

| Area | Why not covered | Risk | Accepted by |
|---|---|---|---|
| | | | <a person's name — never blank> |

<Or: `Nothing excluded — all <n> cases executed.`>

---

## Sign-off

| Role | Name | Date | Verdict |
|---|---|---|---|
| Developer | | | |
| QA | | | |
| Owner (from spec §1) | | | |
