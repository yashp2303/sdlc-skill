# Ticket-local tests — in `docs/`, runnable, never pushed

Test files for a ticket live **in that ticket's docs folder**, not in the repo's test tree. They
still execute against the real code. Nothing about them reaches GitHub.

```
~/TSC/docs/<TICKET-ID>-<slug>/
├── research.md            /ticket-research
├── spec.md                /feature-docs
├── plan.md
├── test-cases.md
├── test-cases.csv         ← Evidence column cites the spec files below
├── qa-sheet.md
├── tests/
│   ├── <feature>.spec.ts       the real tests, real assertions
│   └── <feature>.int.spec.ts
├── jest.config.cjs        copied from templates/, one line edited
└── run-tests.sh           chmod +x, then ./run-tests.sh
```

## Why this works

`~/TSC` is **not a git repo** — `git rev-parse --is-inside-work-tree` fails there. The four
service repos underneath it are. So anything in `docs/` is structurally unpushable: there is no
index to stage it into and no remote to push it to. No `.gitignore` entry needed, and no risk
that a future `git add -A` in a repo sweeps it up.

The part that is not obvious: **jest has two independent roots.**

| Setting | Points at | Gives you |
|---|---|---|
| `rootDir` | the **repo** | `node_modules`, `ts-jest`, `tsconfig.json` |
| `roots` | the **docs folder** | where jest discovers `.spec.ts` |
| `modulePaths` | the **repo** | lets the test `import 'src/orders/lib/…'` like a repo test |

The repo's own `package.json` jest block pins `rootDir: "src"`, which is why `npm run test` can
never see these files. Passing `--config` overrides that completely — which is the point: the
ticket's tests run **only** when you ask for them, and never in the repo's own suite or in CI.

**Verified.** A spec file outside the repo importing `src/orders/lib/premium-order-tag`:
`Test Suites: 1 passed · Tests: 5 passed`.

## Setup, per ticket

```bash
T=~/TSC/docs/TWP-1234-some-slug
mkdir -p "$T/tests"
cp ~/.claude/skills/tsc-ticket/templates/jest.config.cjs "$T/"
cp ~/.claude/skills/tsc-ticket/templates/run-tests.sh   "$T/"
chmod +x "$T/run-tests.sh"
# edit REPO in BOTH files if the ticket is not in pos-app
```

Then:

```bash
cd ~/TSC/docs/TWP-1234-some-slug
./run-tests.sh                 # all specs
./run-tests.sh premium         # filter by name
./run-tests.sh --coverage      # any jest flag passes through
```

## Per-repo differences

| Repo | `REPO` value | Notes |
|---|---|---|
| `tsc-pos-backend/pos-app` | `/Users/devx/TSC/tsc-pos-backend/pos-app` | **verified.** `modulePaths` gives you `src/…` imports |
| `order-management-service` | `/Users/devx/TSC/order-management-service` | same pattern. Its repo tests use **relative** imports, not `src/…` — drop `modulePaths` or import relatively |
| `tsc-pos-frontend` | — | **no test runner installed.** No `test` script, no jest, no Playwright dependency. Ticket-local tests are not possible here until one is added; keep frontend scenarios in `test-cases.md` and mark the rows `manual` |

## Layout — unit and integration are separate projects

```
docs/<TICKET-ID>-<slug>/
├── tests/
│   ├── unit/         <feature>.spec.ts        pure, no I/O, milliseconds
│   ├── integration/  <feature>.int.spec.ts    several units together, may hit services
│   └── ui/                                    Playwright — NOT jest, see /testing
├── jest.config.cjs   two projects: unit · integration
└── run-tests.sh      ./run-tests.sh [unit|integration] [jest flags]
```

`jest.config.cjs` declares them as **projects**, so one command runs both and either can be
targeted. Verified: `Test Suites: 2 passed · Tests: 10 passed · Ran all test suites in 2 projects`.

`testTimeout` is **not** a valid per-project option in this jest version — an integration test
needing longer calls `jest.setTimeout(30_000)` at the top of its own file.

## Integration tests write real records — read this before writing one

An integration test that touches a service **writes to the real ustage database**. That is what
makes it an integration test, and it is also what makes it dangerous here.

### The rules, in order of how much they cost to break

**1. `ustage` only. Never prod.**

```bash
ls -l ~/TSC/order-management-service/.env.secrets   # check BEFORE every run
```

⚠️ `.env.secrets.prod` is currently pointed at the **production** cluster from a migration-3 dry
run that was never reverted, and both files carry a "revert when done" comment. If your symlink
lands there, an integration test writes production. Check the symlink, not your memory of it.

**2. Some writes cannot be undone.** These leave the workspace and no `afterEach` can reach them:

| Boundary | What it leaves behind |
|---|---|
| Serverless OMS | a real order in `oms.orders` — external service, not in this workspace |
| Freshdesk / Flowcall | a real support ticket a human will triage |
| Fynd | a real pickup/drop batch |
| WebEngage | a real customer event |
| SMS / WhatsApp (Gupshup) | **a real message to a real phone number** |

**Mock these boundaries.** Assert the payload your code *would* send, not the far side of the
call. The `qa-cases` rule applies: mock external and non-deterministic dependencies, keep real
application logic.

**3. `LogRequestBodyMiddleware` is applied to `'*'`** and writes **every request body** to Mongo
`request_logs`. Every integration test you run against `order-management-service` persists its
payload there permanently. Do not put realistic PII or card data in test fixtures.

**4. Clean up what you can, and make it findable.** Tag test data so a human can identify and
purge it:

```ts
const TAG = 'TWP-5704-int-test';

afterEach(async () => {
  await collection.deleteMany({ testTag: TAG });
});
```

Prefer `afterEach` over `afterAll` — a failing test that aborts the run still leaves the database
clean up to that point.

**5. Mongo transactions need a replica set.** `OrderRepository` uses `session.withTransaction`.
The managed ustage cluster is a replica set, so this is a non-issue there — it only bites against
a standalone local `mongod`, and the error talks about transaction numbers without ever
mentioning replica sets.

### Prefer the integration test that writes nothing

The most valuable integration test in this ticket writes **zero** records:

```ts
// tests/integration/premium-tag-path-parity.int.spec.ts
it('an edit that changes nothing does not flip the tag', () => {
  const atCreate = getCreatePathPayableValue(order, [], DELIVERY);
  const atEdit   = getEditPathPayableValue(195_000, DELIVERY);
  expect(buildPremiumOrderNoteAttributes(atEdit))
    .toEqual(buildPremiumOrderNoteAttributes(atCreate));
});
```

It composes several real units and catches the actual defect class — *two paths deriving the same
quantity differently* — with no database, no network and no cleanup. **Reach for this shape
first.** Only go to a live-service test when the thing you need to prove genuinely lives in the
wiring.

## Rules

**Write the same test you would have committed.** Real assertions against real code. This is not
a scenario document in `.ts` clothing — if it would not have earned a place in the repo suite, it
does not belong here either.

**One spec file per unit under test**, named after it: `premium-order-tag.spec.ts`, not
`TWP-1234.spec.ts`. The ticket id is already the folder.

**`test-cases.csv` `Evidence` must name the file and the test.** Same rule as always: a `✅` with
an empty `Evidence` is not allowed. Cite it as `tests/premium-order-tag.spec.ts › tags above the
threshold` — the path is relative to the ticket folder, which is where a reader will look.

**Baseline comparison still applies.** These repos have pre-existing failures, so run the repo's
own suite before and after your source changes as well:

```bash
cd ~/TSC/tsc-pos-backend/pos-app
npx jest 2>&1 | tail -5          # baseline, before your change
# … implement …
npx jest 2>&1 | tail -5          # after
cd ~/TSC/docs/TWP-1234-some-slug && ./run-tests.sh   # the ticket's own tests
```

Report all three numbers. The ticket's tests passing while you broke 4 existing ones is not a
pass.

**Source code still goes in the repo.** Only the *tests* are ticket-local. The implementation is
a normal change on a normal branch, committed and pushed as usual — otherwise nothing ships.

## The one trade-off, stated plainly

These tests **do not run in CI** and **no reviewer sees them in the PR**. That is the direct
consequence of keeping them out of git, and it is the choice being made deliberately here. So:

- Quote the run output in the PR description or the ticket, since the diff cannot show it.
- If a test is valuable enough that CI should protect the behaviour permanently, it belongs in
  the repo suite instead. Ticket-local is for verification during the ticket, not for regression
  cover forever.
- `qa-sheet.md` is where that gets recorded — note in **Not covered** that the ticket's tests are
  local and therefore not enforced by CI, with a name against it.
