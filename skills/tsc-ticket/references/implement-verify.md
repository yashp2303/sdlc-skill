# Phases 3–4 — implementing and verifying in this workspace

Traps specific to these four repos. Each one cost real time at least once.

## Wire inside the shared builder, not at the call sites

Before adding a field to a payload, count the callers:

```bash
grep -rn "createOMSOrder(\|buildOMSOrderPayload" src/ --include="*.ts" | grep -v "\.spec\."
```

`createOMSOrder` has **three** callers — `final-confirm-order.ts`,
`create-central-store-order.ts`, `sync-central-store-order.ts`. Logic added at the one you
happened to open misses the other two, and the central-store paths are the easy ones to
forget because they are in a different module.

Add it where the payload is built. One place, every caller.

## Do not reformat

**These files are not prettier-clean.** `create-oms-order.ts` has ~54 prettier errors at
HEAD. Running `prettier --write` on it produced **186 insertions for a 25-line change** —
unrelated churn that buries the actual diff in review.

```bash
npx prettier --write <new files only>        # fine
npx prettier --write <existing file>         # NO — rewrites the whole file
```

For existing files, write new code **pre-wrapped** to satisfy the linter. The IDE
diagnostics will tell you exactly what wrapping it wants; match that by hand.

If an adjacent line was already over-length and your edit shifts its indentation, wrapping
that one line is acceptable — it is part of your change. Ten lines away is not.

## Preserve existing typos

Schema fields and filenames carry typos that are load-bearing:

```
replacemt_window
transform-and-valiadte-dto.decorator.ts
is_dismentaling_job_need
is_pkg_matterial_need
```

Renaming a schema field breaks stored documents. Renaming a file breaks imports. Leave them
and resist the tidying instinct.

## Never print a secret

Several repos have live credentials in the working tree — `order-management-service/.env`
and `.env.secrets`, `refund-process/.env.stage` and `.env.prod`,
`tsc-pos-backend/EDIT_ORDER_API_FLOW.md`, `sam-backend/samconfig.toml`.

Do not echo, paste, print, or commit those values — including into terminal output, commit
messages, or docs. Do not add new ones.

**Do not copy the existing cURL-logging pattern.** `serverless-oms-connection/service.ts`
builds a cURL string containing `x-api-key: ${this.apiKey}` and `console.log`s it, at two
places. `flowcall.service.ts` does the same with a bearer token. Those are defects; a new
one is not excused by the precedent.

## Verify the plan's assumptions as you implement

Plans are written before the code is open, so a plan can be wrong in ways that look right.
Actual examples from TWP-5704:

| Plan said | Code said |
|---|---|
| `optOutDiscountAmount` is order-level | it is on `OrderProductData` — per-product, needs summing across the cart |
| five discount sources | there is a sixth, `additionalPromotionalCoupons`, itemised into `discount_details` |

**When the code disagrees with the plan, the code wins** — and say so in the report. A plan
silently followed past a wrong assumption produces a bug with documentation vouching for it.

Check every field the plan names:

```bash
grep -rn "<field>" src/<module>/entities/*.ts     # which class owns it?
```

## Baseline before you claim a number

These repos have pre-existing lint and typecheck failures. A raw count proves nothing.

```bash
# lint
git stash push -q <touched files>
npx eslint <file> 2>&1 | grep -oE "✖ [0-9]+ problems"     # baseline
git stash pop -q
npx eslint <file> 2>&1 | grep -oE "✖ [0-9]+ problems"     # with the change

# typecheck — scope to the files you touched
npx tsc --noEmit -p tsconfig.json 2>&1 | grep -i "<file-a>\|<file-b>"
npx tsc --noEmit -p tsconfig.json 2>&1 | grep -c error     # and the total
```

Report both numbers. "54 at HEAD, 53 with my change" is evidence. "53 errors" invites the
reader to assume you caused them.

Known pre-existing at time of writing: 4 typecheck errors in
`easy-ecom.service.spec.ts` and `test/app.e2e-spec.ts`. If your total is 4 and none are in
your files, you are clean.

## Tests

```bash
npx jest <path/to/new.spec.ts>
```

Convention here is `<name>.spec.ts` beside the source, `rootDir: src`, `testRegex
.*\.spec\.ts$`. Many `lib/` directories have no tests at all — a new spec file beside a new
helper is a net addition, not a pattern break.

Name tests after the acceptance criterion or QA row they close (`QA-010/AC-3: exactly
₹2,00,000 is NOT premium`). That is what makes the sheet's Evidence column meaningful.

Cover the negative rows: boundary, one unit inside, `0`, `null`, `NaN`, negative, and the
invariant. A suite of happy paths passes on broken code.

## Marking the sheet

Through the tool, never by hand — it refuses a pass with no evidence:

```bash
sheet_tool.py mark docs/<TICKET-ID>-<slug>/test-cases.csv \
  --id QA-001 --status ✅ --evidence src/orders/lib/premium-order-tag.spec.ts
sheet_tool.py verify docs/<TICKET-ID>-<slug>/test-cases.csv
```

`sheet_tool.py` is at `tsc-pos-backend/.ai/bin/lib/sheet_tool.py`.

## Report honestly

- Pre-existing failures are never reported as yours; yours are never reported as
  pre-existing.
- A step skipped is stated as skipped.
- Anything depending on the Serverless OMS cannot be verified from here. Say what the one
  test would be that settles it, and on which environment.
- If the work is partially blocked, finish everything unblocked and say precisely what was
  left and why.
