---
name: tsc-ticket
description: "End-to-end handling of a TSC ticket across the four-repo workspace — investigate with file:line evidence, write spec/plan/QA in the TWP-5704 house format, implement, test, and report. Use when a TSC or TWP ticket arrives, or when asked to spec, plan, estimate, implement, or write test cases for one. Trigger: /tsc-ticket"
---

# TSC ticket, end to end

One ticket, five phases, in order. Each ends at a point where stopping is safe.

```
1 INVESTIGATE   grep every name the ticket uses; find every call site
2 DOCUMENT      spec.md · plan.md · test-cases.csv · qa-sheet.md      ── gate
3 IMPLEMENT     shared helper first, then each call site
4 VERIFY        tests · typecheck · lint · baseline comparison
5 REPORT        what shipped, what is blocked, what you could not verify
```

**Phase 2 is a gate.** Do not write code until the spec and plan are approved. If the user
says "implement this plan", phases 1–2 are already done — start at 3, but *read* the spec
and plan first: they encode findings you will otherwise re-derive wrongly.

## When to use this instead of the repo workflows

Each repo has its own `/feature` and `/spec` under `.ai/workflows/`, driven by
`.ai/bin/wf.sh`, with run state and human gates. Those are better when the work is
**genuinely inside one repo** — they track state and enforce a definition of done.

Use this skill when:

- the work **spans repos** — `tsc-pos-frontend` · `tsc-pos-backend` ·
  `order-management-service` · `refund-process`, or reaches the Serverless OMS
- the docs belong at the **workspace root** (`/Users/devx/TSC/docs/`), outside any repo,
  which is where cross-service tickets land
- you want the **TWP-5704 shape** specifically

Reference example: `/Users/devx/TSC/docs/TWP-5704-premium-order-tagging/`. Read it before
writing — it is the worked example, not a description of one.

---

## Phase 1 — Investigate

**The rule the whole skill rests on: every claim about the codebase is verified by reading
the codebase, and says where.** Not "tags are sent when the order is created" but
``create-oms-order.ts:644`` — a hardcoded **string**, not an array``. A document full of
plausible statements is worse than none, because it gets believed.

### Check the names first

Grep for every entity, status, field, module, route or role the ticket names. **If one does
not exist in this codebase, that mismatch is the real finding** and it goes at the top of
the spec. A ticket saying "update the completed order" when no such status exists has told
you its actual problem.

### Then establish, with file:line

- **Every write site.** Grep the field the ticket names. There may be one, three, or none.
- **Every read site.** "One writer, zero readers" means something different from five
  consumers. Put that grep result in the spec verbatim.
- **The nearest existing implementation.** New features are usually extensions. Name the
  file or you will specify a second parallel one.
- **Where the numbers come from.** If the ticket turns on a value, find where it is
  computed on *each* path. **Two paths computing the same quantity differently is the most
  common trap in this stack, and it is invisible unless you look at both.**
- **What is out of reach.** The Serverless OMS is not in this workspace. Say so explicitly
  and turn it into an open question — never guess its behaviour.

### Stack facts that change the answer

- **Legacy → OMS migration is live on both paths.** `easyecom`/`Shopify`/`marketplace` are
  legacy-side; `source`/`shipments`/`item_codes` are OMS-side. Ask whether both paths need
  the change.
- **Two create paths.** `order-management-service` (REST/Mongo, EKS) and `tsc-pos-backend`
  (GraphQL/DynamoDB, ECS+Lambda). Different services, different logs.
- **`order-management-service` runs on EKS with no log shipper** — its application logs
  reach no CloudWatch group. Absence of logs is not absence of execution.
- Read the repo's own `CLAUDE.md` before touching it.

---

## Phase 2 — Document

Four artifacts in `docs/<TICKET-ID>-<slug>/` at the workspace root:

| File | Answers | Contains no |
|---|---|---|
| `spec.md` | what changes, why, what must be true | file paths as instructions, signatures, estimates |
| `plan.md` | where the code goes, in what order, what it costs | restated requirements |
| `test-cases.csv` | every scenario — **source of truth**, tool-driven | prose |
| `qa-sheet.md` | sign-off: environment, defects, not-covered | implementation detail |

`test-cases.xlsx` is generated from the CSV, never hand-edited.

### spec.md

Full rules in `references/spec-format.md`.

```
# <Feature> — <scope>
  header: Ticket · Status · Date · Author (with the env facts were checked against)
1. What changes, at a glance   — Before/After table. A reader stops here and is correct.
2. Why                          — the decision this enables, not "the ticket asks for it"
3. Verified facts               — §3.1…3.n, each with file:line. THE SECTION.
4. Requirement                  — numbered, behavioural, no technology
5. Acceptance criteria          — AC-n, Given/When/Then, mechanically checkable
6. Edge cases                   — Case | Expected | Risk
7. Open questions               — Q-n | Why it matters | Default if unanswered
8. Scope boundaries             — in scope, and explicitly not
9. Design note                  — the one shape decision, if there is one
```

§3 carries the document. Lead it with how many of these facts change the shape of the work.
Order by estimate impact, not code order. **No technology in §4–5** — the plan decides how.
**Every open question needs a default**, chosen so being wrong changes one function, not
the design.

### plan.md

Full rules in `references/plan-format.md`.

```
# Plan — <Feature>
  header: Ticket · Spec (link) · Status (naming the blocker) · Date
0. TL;DR              — scope table + which part is actually hard
1. Call sites         — exhaustive, with the grep that found them
2. Implementation     — real code, ordered by risk
3. Edge cases         — every numbered case, and where it lands
4. The one risk       — with arithmetic, not a category
5. Estimate           — hours by activity, with its branch condition
6. Order of work      — what unblocks what; map steps to ACs
7. Out of scope
8. QA                 — coverage table + blocked count + links
```

§0's job is to **correct the reader's instinct about difficulty** — one sentence, only when
intuition is actually wrong. Write **real code** in §2, not pseudocode. Estimates branch:
"32 hours if OMS replaces, 45+ if it merges" — a single number hides the unknown that
decides the cost.

### QA

Full rules in `references/test-cases-format.md`.

**Invoke the `qa-cases` skill** for the enumeration and the CSV — it owns the schema
(`ID · Section · Scenario · Type · Level · Expected · Status · Evidence · Notes`) and
`scripts/to-xlsx.py`. `tsc-pos-backend/.ai/bin/lib/sheet_tool.py` does `list`/`mark`/
`verify`/`sync` and refuses a pass with no evidence. **Never hand-roll a markdown variant**
— a table no tool can read lets statuses drift silently.

Then write `qa-sheet.md`: the sectioned view plus what a CSV cannot carry — the environment
block for manual runs, defects found, and not-covered with an `Accepted by` name.

**Negative rows are mandatory.** Boundary, one unit inside it, `0`, `null`, `NaN`, negative,
and the invariant that must always hold. A negative row asserts the **refusal**, not the
absence of a crash. Close with the honest count — "37 of 43 testable today".

### → Stop here unless told to implement

---

## Phase 3 — Implement

Workspace-specific traps in `references/implement-verify.md` — read it before editing an
existing file.

**Source code goes in the repo. Tests go in the ticket's docs folder.** Full setup in
`references/ticket-local-tests.md`:

```
~/TSC/docs/<TICKET-ID>-<slug>/
├── tests/<feature>.spec.ts     real tests, real assertions
├── jest.config.cjs             rootDir → repo · roots → here
└── run-tests.sh                ./run-tests.sh
```

`~/TSC` is not a git repo, so these are structurally unpushable — but they **do** run, because
`--config` overrides the repo's `rootDir: "src"`. Verified: 5/5 passing from `docs/`.

Write the same test you would have committed. If it would not have earned a place in the repo
suite, it does not belong here either.

**Shared logic first, in one place.** Two implementations of one rule drift the moment the
rule changes. Put the decision in a helper with a doc comment encoding the constraint that
would otherwise be violated ("`value` must be the post-discount payable — passing a
pre-discount total silently over-tags every discounted order").

**Then each call site, ordered by risk.** Quote what is there, add the minimum.

Rules that matter in this workspace:

- **Wire inside the shared builder, not at the call sites.** `createOMSOrder` has three
  callers; logic added at one misses two.
- **Do not reformat.** These files are not prettier-clean. Run prettier on **new files
  only** — on an existing file it rewrites hundreds of unrelated lines. Write new code
  pre-wrapped to satisfy the linter instead.
- **Preserve existing typos** in schemas and filenames (`replacemt_window`,
  `transform-and-valiadte-dto.decorator.ts`). Renaming them is breaking.
- **Never echo, print, or commit secrets.** Several repos have live credentials in the
  working tree. Do not add new ones, and do not log an API key into a cURL string — that
  bug already exists in `serverless-oms-connection/service.ts` and should not be copied.
- **Verify the plan's assumptions as you go.** Plans are written before the code is open.
  A field the plan reads as order-level may be per-product. When the code disagrees with
  the plan, the code wins — say so in the report.

---

## Phase 4 — Verify

Full procedure in `references/implement-verify.md`.

```bash
cd ~/TSC/docs/<TICKET-ID>-<slug> && ./run-tests.sh    # the ticket's own tests
npx tsc --noEmit -p tsconfig.json                     # typecheck
npx eslint <touched files>                            # lint
```

**Three numbers, not one.** The repo suite before your change, the repo suite after, and the
ticket's own tests. The ticket's tests passing while you broke four existing ones is not a pass.

**Compare against baseline, always.** These repos have pre-existing failures. A raw error
count proves nothing:

```bash
git stash push -q <touched files>
npx eslint <file>          # baseline
git stash pop -q
npx eslint <file>          # with your change
```

Report both numbers. "54 at HEAD, 53 with my change" is evidence; "53 errors" is noise.

Mark QA rows through `sheet_tool.py mark` with evidence, not by hand.

---

## Phase 5 — Report

- **What shipped** — file:line links for each change
- **What the code contradicted** in the plan or spec, and which won
- **What is blocked**, on which numbered question
- **What you could not verify** — anything depending on the Serverless OMS, anything
  needing a live environment. State the one test that would settle it.
- **Baseline comparison** for lint and typecheck

Never report a pre-existing failure as if you caused it, or your own as if it were
pre-existing.

## Two failure modes

**A spec that reads like the ticket.** If §3 has no file:line, you reformatted the ticket
rather than specified the work. Go back to the code.

**An estimate with no branch.** Real estimates are conditional. A single number hides the
unknown that will actually decide the cost.
