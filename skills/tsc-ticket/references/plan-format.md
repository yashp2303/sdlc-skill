# plan.md — section rules

Worked example: `/Users/devx/TSC/docs/TWP-5704-premium-order-tagging/plan.md`.

The plan answers **where the code goes, in what order, and what it costs**. It does not
restate the spec. It links to it.

## Header

```markdown
# Plan — <Feature>

| | |
|---|---|
| **Ticket** | [TICKET-ID](url) — <title> |
| **Spec** | [`spec.md`](./spec.md) — problem, acceptance criteria, verified facts |
| **Status** | Not started. **Qn must be answered before coding <the gated part>** |
| **Date** | YYYY-MM-DD |
```

The Status line names the blocker. Not "blocked" — *which* question blocks *what*.

## §0 TL;DR — correct the reader's instinct

```markdown
| Scope | Work | State |
|---|---|---|
| **A — the decision** | one pure function | trivial |
| **B — creation** | <the value doesn't exist; must be assembled from n sources> | the real work |
| **C — edit** | <already computed 3 lines above the payload> | cheap |
| **D — removal** | may be impossible from <this side> | ⚠️ **blocked on Qn** |
```

Then one sentence saying where intuition goes wrong:

> The naming is misleading: "add a tag" sounds like B is easy and D is a detail. It is the
> other way round. The tag itself is four lines; the value it depends on is not.

If the ticket's name makes the work sound easier or harder than it is, this sentence is
the most valuable line in the document. If intuition is right, omit it — do not
manufacture a paradox.

## §1 Call sites

Exhaustive, with how you found them:

```markdown
Verified by grep for `<pattern>` across `<dirs>`:

| File | Direction | <does it do X today> |
|---|---|---|
| `path/a.ts` | write | ✅ `<the line>` (line n) |
| `path/b.ts` | write | ❌ none |
| `path/c.ts` | read-only | n/a |
```

Naming the grep lets the next person re-run it. Include read-only sites so the reader
knows they were considered and excluded.

Note anything satisfied for free here — a flag riding the same payload means one fewer
task.

## §2 Implementation — real code

**§2.1 the shared helper.** The actual file, actual signature, actual doc comment. The
comment should encode the constraint that will otherwise be violated:

```ts
/**
 * `value` must be the post-discount payable — see §2.2. Passing a pre-discount
 * total silently over-tags every discounted order near the threshold.
 */
```

**§2.2… one per call site.** Quote what is there now, then what to add:

```markdown
`create-oms-order.ts:636` sends a **pre-discount** total:

```js
total_price: (orderProducts || []).reduce(
  (sum, p) => sum + (p.price || 0) * (p.quantity || 0), 0)
```

<n> discount sources are in scope in that function but never aggregated:
`a`, `b`, `c`, `d[]` (array of `{ x, amount }`), `e`. Add a derived value
**for the tag only**:

```js
const finalPayableValue = totalPrice - (...);
```
```

"For the tag only" matters — it tells the implementer not to change what the downstream
service is told the record is worth.

**Order sections cheapest-last is wrong. Order them by risk**, so the reader hits the
hard one while still paying attention.

**The gated section** states its condition and both outcomes:

> If replace: send `'<base>'`, done. If merge: POS cannot remove it; needs an OMS-side
> clear endpoint; blocked on the OMS team.

## §3 Edge cases — every one, and where it lands

Numbered, so §8 can cite them. Mark the ones that can produce a wrong result in
production, in bold, up front:

> **Cases 4, 6, 7, 14 and 19 can produce a wrong tag in production.**

That sentence is what a reviewer needs. The other nineteen rows are diligence.

## §4 The one specific risk

Not "risks" — *the* risk. The thing most likely to be wrong once shipped, with a concrete
worked example:

> `create: Σ(price × qty)` (pre-discount) vs `edit: Σ(price × qty) − Σ(discounts)`
> (post-discount). A ₹2,10,000 cart with ₹20,000 of discounts would be **premium at
> creation** and **non-premium after any edit** — the tag flips on an edit that changed
> nothing.

Real numbers. A named risk with no arithmetic is a category, not a risk.

## §5 Estimate — with its branch

```markdown
**~32 hours if <condition A>; 45+ if <condition B>.**

| Activity | Hours |
|---|---|
| investigation | 5 |
| helper + tests | 2 |
| <call site 1> | 6 |
| <call site 2> | 2 |
| <gated work> | 8 |
| testing | 6 |
| review | 3 |
```

A single number hides the unknown that will decide the actual cost. Investigation is a
line item — it is real work and it is always done.

## §6 Order of work

What unblocks what. Put the item that is independent of every open question early, so
progress is possible while questions are outstanding:

> send Q1 and Q2 → build the helper → reconcile the two value calculations (highest risk,
> independent of both questions) → wire the call sites → gated work last

Close by mapping steps to ACs: "Steps 2–4 deliver AC-1..AC-5 and AC-7..AC-14; only AC-6
waits on Q1." Now the reader knows exactly what "blocked" costs.

## §7 Out of scope

Short. Anything a reader might assume is included: backfilling existing records,
changes in another team's service, UI surfacing.

## §8 QA

The sheet itself lives in `test-cases.csv` (source of truth) with `qa-sheet.md` as its
readable layer — see `test-cases-format.md`. This section keeps only what bears on the
estimate:

```markdown
## 8. QA

43 scenarios — 18 unit, 14 integration, 11 manual.
Cases: [`test-cases.csv`](./test-cases.csv) · sign-off: [`qa-sheet.md`](./qa-sheet.md).

| Level | Total | ✅ | 🔲 | ❌ | ⬜ |
|---|---|---|---|---|---|
| unit | 18 | 0 | 0 | 0 | 18 |
| ... |

**6 rows cannot be tested until Q1 and Q2 are answered.**
```

The count and the blocked count change what the work costs. The rows do not.
