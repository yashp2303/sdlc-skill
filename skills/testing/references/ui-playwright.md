# UI testing with Playwright

## The situation, verified

`tsc-pos-frontend/playwright/flows/` contains **20 real Playwright spec files** covering the POS
happy paths — auth, customer login, add-to-cart, coupons, quotation, pre-order summary, and cash /
Razorpay / PayU / bank payment in both split and non-split variants.

**They have never been runnable.** `@playwright/test` is not installed in any repo in this
workspace, there is no `playwright.config.*` anywhere, and `package.json` has no test script. The
suite was written and then stranded.

| Fact | Value |
|---|---|
| spec files | **20** |
| files containing `test(...)` | **13** |
| pure building blocks (export a function, no `test()`) | **7** |
| discoverable once wired up | **12 tests in 12 files** — verified |
| `@playwright/test` installed | **nowhere** |
| `playwright.config.*` in any repo | **none** |
| Chromium browsers | **already cached** — `~/Library/Caches/ms-playwright/chromium-1234` |

## The composable-function pattern

These flows are building blocks, not independent tests. Each exports a function taking `page`:

```ts
// add-to-cart.spec.ts  — a block, not a test
export async function addToCart(page) {
  await page.getByRole('link', { name: 'Products' }).click();
  await page.getByTestId('plp-add-to-cart-btn').first().click();
  await page.getByTestId('cart-popup-okay-btn').click();
}
```

Journeys then compose them:

```ts
import { login }         from './auth-stage';
import { customerLogin } from './customer-login';
import { addToCart }     from './add-to-cart';
```

The seven blocks are `add-to-cart` · `auth-stage` · `cart-checkout` ·
`cash-payment--step-3--non-split` · `customer-details-page` · `customer-login` ·
`preordersummary|website-delivery|step-2`.

**`flows-index.json` is the map** — `features → { flows, keywords }`. Use it to find the block you
need instead of grepping. Keep it updated when you add a flow; nothing enforces that.

## Making them run — no repo modification

`@playwright/test` resolves from the **spec file's** directory upward, not from the config's. Since
the specs live in the frontend repo and it has no `node_modules/@playwright`, a config alone fails
with `Cannot find module '@playwright/test'`.

**`NODE_PATH` fixes it** — verified, 12 tests discovered, nothing in the repo touched:

```bash
# one-time: a local Playwright install outside every repo
mkdir -p ~/TSC/.testing && cd ~/TSC/.testing
npm init -y >/dev/null && npm install -D @playwright/test
# browsers are already cached; if not: npx playwright install chromium
```

Then run with `NODE_PATH` pointing at it. The templates
`templates/playwright.config.ts` and `templates/run-ui-tests.sh` do this — copy both into the
ticket folder, same pattern as the jest ones.

**Why not just install it in the frontend?** That is the cleaner long-term fix and you should
propose it — but it edits `package.json` and the lockfile in a git repo, which is a change that
belongs in its own PR, not smuggled in with a ticket. Until then, `NODE_PATH` keeps UI testing
possible without touching the repo.

## Two defects in the existing suite

**1. `whole-sanity-checkout.spec.ts` cannot load.** It imports with an explicit `.ts` extension:

```ts
import { login } from './auth-stage.spec.ts';   // ← Playwright's loader rejects this
```

Every other flow imports extensionless. Drop `.spec.ts` from those four import lines and it loads.
Until then it must be excluded — `testIgnore` in the template does that — and it is the
**whole-journey sanity test**, so its absence is the biggest coverage hole.

**2. Twelve of thirteen tests are named `test`.** `test('test', async ({ page }) => {…})`, twelve
times. The report then reads:

```
save-quotation.spec.ts:3:5 › test
razorpay-upi-manualverify-payment--step-3--splitted.spec.ts:3:5 › test
```

Filename carries all the meaning; the test name carries none. `--grep` is useless, and a failure
line does not say what broke. **Rename as you touch them** — `test('saves a quotation from the
cart', …)`. Do not add new ones called `test`.

## Prerequisites — these are integration tests, not unit tests

They drive a real browser against a real app. Before any run:

| Need | Why |
|---|---|
| frontend on `localhost:5173` | `./run.sh ustage:local` |
| backend reachable | same command, or `ustage:ustage` for the deployed backend |
| a **Cognito user in the ustage pool** | `auth-stage` logs in for real; each env has its own pool |
| real test data | a product that is in stock and addable to cart |

Any of these missing is an **ENVIRONMENT_BLOCKER**, not a test failure. Say which `TC` rows it
blocks and mark them `🔲`, never `❌`.

**Payment flows touch real gateways.** `razorpay-*`, `payu-*`, `bank-payment` and the `epay` paths
hit provider sandboxes. Never run them against a prod-pointing stack, and never against
`.env.secrets.prod`.

## What belongs in Playwright, and what does not

| Case | Level | Why |
|---|---|---|
| threshold arithmetic, rounding, boundaries | **unit** | deterministic; `EC` boundary families belong here |
| a guard's error code | **unit** | open the guard, assert the code |
| resolver → service → OMS payload shape | **integration** (jest) | no browser needed |
| the four data states — loading, empty, error, populated | **integration** or Playwright | Playwright if the state is only reachable through the UI |
| a complete operator journey — cart → payment → order | **Playwright** | crosses UI → API → workflow → DB |
| keyboard-only completion | **Playwright** | |
| "is the error message comprehensible", "does the layout survive a real screen" | **manual** | cannot be automated; say so rather than omitting |

**Do not push a case up to Playwright because it is easier to write there.** A boundary rule
tested through a browser is slow, flaky, and tells you less than three lines of jest.

## Running it

```bash
cd ~/TSC/docs/<TICKET-ID>-<slug>
./run-ui-tests.sh                 # all discoverable flows
./run-ui-tests.sh save-quotation  # filter by file
./run-ui-tests.sh --headed        # watch it
./run-ui-tests.sh --ui            # Playwright's interactive runner
npx playwright show-report        # after a run
```

## Reporting UI results

- **Evidence** for a Playwright row is the spec path plus the test title, and — when it failed —
  the trace or screenshot path Playwright wrote. `traces` and `screenshots` are on in the template
  config for exactly this reason.
- A flow that could not run because the stack was down is **`🔲` needs live confirmation**, not
  `❌`. Record the missing prerequisite in `qa-sheet.md` §A.
- A flow excluded because of the `.ts` import defect is `⚠️` with the reason, and it needs a name
  in `qa-sheet.md` Not covered.
- Playwright results are **not in CI** — there is no workflow running them. Treat a green run as
  evidence for this ticket, not as ongoing regression cover.
