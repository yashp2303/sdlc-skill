# Running tests in this workspace — real commands

Read this before running anything. **A raw pass/fail count is meaningless in these repos** — they
carry pre-existing failures, so every number needs a baseline beside it.

## Per-repo reality

| Repo | Runner | Spec files | Unit | Integration | API | UI / E2E |
|---|---|---|---|---|---|---|
| `tsc-pos-backend/pos-app` | Jest + ts-jest | **91** | ✅ | ✅ | ✅ | ✅ config exists |
| `order-management-service` | Jest + ts-jest | **6** | ✅ | ✅ | ✅ | ✅ config exists |
| `tsc-pos-frontend` | **Playwright, not installed** | **20** | ❌ | ❌ | ❌ | ⚠️ **revivable** — see below |
| `refund-process` | `react-scripts test` | 1 | ⚠️ boilerplate, **fails** | ❌ | ❌ | ❌ |

### `tsc-pos-frontend` — 20 UI specs, no runner, but revivable

`playwright/flows/` has **20 real Playwright specs** (auth, cart, coupons, quotation, cash /
Razorpay / PayU / bank payments) plus `flows-index.json` mapping features → flows. **13 contain
`test()`; 7 are composable blocks** other flows import.

`@playwright/test` is installed in **no** repo and there is no `playwright.config.*` anywhere —
which is why they have never run. **`NODE_PATH` resolves it without touching any repo**, verified:
**12 tests discovered in 12 files.** Chromium is already cached.

```bash
# one-time
mkdir -p ~/TSC/.testing && cd ~/TSC/.testing
npm init -y >/dev/null && npm install -D @playwright/test

# per ticket — copy both templates into the ticket folder
cp ~/.claude/skills/testing/templates/playwright.config.ts .
cp ~/.claude/skills/testing/templates/run-ui-tests.sh .
chmod +x run-ui-tests.sh
./run-ui-tests.sh
```

Full detail, the two defects in the suite, and the which-level-for-which-case table:
`references/ui-playwright.md`.

**There is still no unit or integration runner for the frontend** — no jest, no vitest. Component
and hook-level cases there remain `NOT_TESTABLE`; say why and what would have to change. **Do not
quietly downgrade them to `manual` and tick them** — a manual walkthrough counts only if someone
walked through it and signed the Environment block.

### `refund-process` has one boilerplate test and it fails

`App.test.js` asserts `/learn react/i`. That failure is **baseline**, not yours. The repo also has
no CI of any kind.

## Commands

```bash
# ── pos-app ────────────────────────────────────────────────────────────
cd ~/TSC/tsc-pos-backend/pos-app
bun run test                      # full suite
bun run test:cov                  # coverage
bun run test:e2e                  # jest --config ./test/jest-e2e.json
npx jest src/orders/lib/premium-order-tag.spec.ts       # one file
npx jest -t 'tags above the threshold'                  # one test by name

# ── order-management-service ───────────────────────────────────────────
cd ~/TSC/order-management-service
bun run test
bun run test:cov
bun run test:e2e

# ── frontend: lint and format are all there is ─────────────────────────
cd ~/TSC/tsc-pos-frontend
bun run lint
bun run prettier

# ── typecheck (any TS repo) ────────────────────────────────────────────
npx tsc --noEmit -p tsconfig.json
```

## Ticket-local tests

Test files written by `/tsc-ticket` live in the **ticket's docs folder**, outside every git repo,
and run through their own config:

```bash
cd ~/TSC/docs/<TICKET-ID>-<slug>
./run-tests.sh                # all specs in ./tests
./run-tests.sh premium        # filter
./run-tests.sh --coverage
```

They are invisible to `npm run test` by design — `pos-app` pins jest `rootDir: "src"`, and
`run-tests.sh` passes `--config` to override it. Verified: 5/5 passing from a docs folder against
`pos-app` source.

**So a full validation pass runs both**: the repo suite *and* the ticket's own tests. Reporting
only one is incomplete.

## The mandatory baseline procedure

These repos have pre-existing failures. `"53 errors"` is noise; `"54 at HEAD, 53 with my change"`
is evidence.

```bash
cd ~/TSC/tsc-pos-backend/pos-app

# 1. baseline — stash only the files you touched
git stash push -q <your changed files>
bun run test 2>&1 | tail -5        > /tmp/base-test.txt
npx eslint <your files> 2>&1 | tail -3 > /tmp/base-lint.txt
npx tsc --noEmit -p tsconfig.json 2>&1 | tail -3 > /tmp/base-tsc.txt

# 2. restore and measure again
git stash pop -q
bun run test 2>&1 | tail -5
npx eslint <your files> 2>&1 | tail -3
npx tsc --noEmit -p tsconfig.json 2>&1 | tail -3

# 3. the ticket's own tests
cd ~/TSC/docs/<TICKET-ID>-<slug> && ./run-tests.sh
```

Record **all three** in the report's Baseline Comparison table. Never report a pre-existing
failure as if you caused it, or your own as if it were pre-existing.

## Environment prerequisites

| Need | Why | Check |
|---|---|---|
| AWS creds, profile `tsc-pos` | `pos-app` resolves ~120 config values from **SSM at runtime**. Integration and API tests cannot boot without it | `aws ssm get-parameter --name /pos-ustage/cognito/userpool_id --with-decryption --profile tsc-pos --region ap-south-1` |
| Redis running | the OMS gates on the client at boot | `redis-cli ping` → `PONG` |
| Mongo **replica set** | `OrderRepository` uses `session.withTransaction`; a standalone `mongod` fails with a transaction-numbers error that never mentions replica sets | use the managed ustage cluster |
| Correct `.env.secrets` symlink | decides which database the OMS reads | `ls -l ~/TSC/order-management-service/.env.secrets` |
| Cognito user in the **right pool** | each environment has its own; a prod account will not log in to ustage | — |

Any of these missing is an **ENVIRONMENT_BLOCKER**, and §18 of `research.md` should already have
predicted it. Name which `TC` rows it blocks.

## Two traps specific to this stack

**The OMS has no log shipper.** `order-management-service` runs on EKS and its application logs
reach **no CloudWatch group**. **Absence of logs is not absence of execution** — do not conclude a
code path did not run because you cannot find a log line. Traces go to **SigNoz**; use that.

**Both the legacy and OMS paths are live.** A test that exercises only one path proves half the
behaviour. When the change touches order-shaped logic, cover both — `easyecom`/`Shopify`/
`marketplace` on the legacy side, `source`/`shipments`/`item_codes` on the OMS side.

## Sheet tooling

```bash
S=~/TSC/tsc-pos-backend/.ai/bin/lib/sheet_tool.py
T=~/TSC/docs/<TICKET-ID>-<slug>

python3 "$S" list   "$T/test-cases.csv"     # rows needing work, by level
python3 "$S" mark   "$T/test-cases.csv" QA-001 --status pass --evidence '<file> › <test>'
python3 "$S" verify "$T/test-cases.csv"     # exit 1 on drift — this is the gate
python3 "$S" sync   "$T/test-cases.csv"     # regenerate the xlsx view
```

`mark` **refuses a pass with no evidence**, which is why marking by hand is not allowed.

Alternative xlsx generator, if `sync` is unavailable:

```bash
python3 ~/.claude/skills/qa-cases/scripts/to-xlsx.py "$T/test-cases.csv"
```

Note this workspace's convention is **CSV only — no `.xlsx` kept**. Generate the view if you want
to read it, do not commit it.

## Do not

- Do not run `prod:local` or point anything at `.env.secrets.prod` to test. **That reads and
  writes the production database.** ⚠️ `.env.secrets.prod` is currently pointed at prod from a
  migration dry-run that was never reverted.
- Do not run the formatter on existing files to make lint pass — it rewrites hundreds of unrelated
  lines. New files only.
- Do not "fix" a pre-existing failure as part of this ticket without saying so.
