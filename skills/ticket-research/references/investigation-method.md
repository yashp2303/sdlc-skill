# How to investigate — method

The output format is in `research-format.md`. This is how to get the facts that fill it.

## The order matters

```
1  names        does everything the ticket mentions actually exist?
2  entry        where does this behaviour enter the system?
3  sites        every write site, every read site
4  numbers      where does each quantity come from, on EACH path?
5  nearest      what already does something similar?
6  edges        what does the existing code refuse to do?
7  reach        what is outside this workspace?
```

Doing 1 first is what makes the rest cheap. A ticket about a status that does not exist does not
need steps 2–7 — it needs a conversation.

## Step 1 — Names

For every entity, status, field, module, route, screen, role, flag and env var the ticket names:

```bash
rg -i '<name>' --type ts -l | head -20          # does it exist at all
rg '<name>' --type ts -n | head -40             # where, exactly
rg -i 'enum.*status|StatusEnum' --type ts       # what are the REAL values
```

For a status or enum, always list the actual members. "The ticket says `completed`; the enum has
`PLACED · CONFIRMED · DISPATCHED · DELIVERED`" is a complete finding in one line.

For a field, check whether it is a real column/property or something else wearing that name — a
`note_attributes` entry, a tag string, a computed getter. The difference changes the work.

## Step 2 — Entry point

Find where the behaviour the ticket describes enters the system:

```bash
rg 'Resolver|@Mutation|@Query' --type ts -l | rg -i '<domain>'
rg '@Controller|@Post|@Get' --type ts -n | rg -i '<domain>'
rg -i '<screen name>' src/views -l
```

Establish it in both directions: the UI that triggers it, and the handler that serves it. A ticket
phrased in UI terms often lands in a service two hops away.

## Step 3 — Write sites and read sites, separately

This is the step that most changes an estimate.

```bash
rg '<field>' --type ts -n              # everything
rg '<field>\s*[:=]' --type ts -n       # likely writes
rg '\.<field>\b' --type ts -n          # likely reads
```

Then **open each hit** and classify it. Do not classify from the grep line alone — a match inside
a comment, a test fixture, or a commented-out legacy block is not a call site, and counting it
inflates the estimate.

Record the counts explicitly. `2 write sites, 0 read sites` and `1 write site, 5 read sites` are
different features with the same description.

**If a builder function has multiple callers, say how many.** Logic added to one caller misses the
others, and that is the most repeated implementation mistake in this codebase.

```bash
rg 'createOMSOrder\(' --type ts -n     # how many callers?
```

## Step 4 — Where each number comes from, on each path

If the ticket turns on a value — an amount, a count, a threshold, a date — find where that value
is computed on **every** path that reaches the change.

**Two paths computing the same quantity differently is the most common trap in this stack, and it
is invisible unless you open both.** One will use a post-discount payable, the other a line-item
subtotal; both are called "order value" in conversation.

Record both `file:line`s side by side, and state the consequence: a shared helper must take the
value as an argument rather than derive it.

## Step 5 — The nearest existing implementation

Most tickets are extensions of something that already exists.

```bash
rg -i 'similar-concept' --type ts -l
git log --oneline -15 -- <the file you expect to change>
```

Name it. If you skip this, the plan will specify a second parallel implementation of a rule that
already lives somewhere — and both copies will drift the moment the rule changes.

Also check whether the rule is **already duplicated**. If it is, saying so is worth more than any
other sentence in the document.

## Step 6 — What the existing code refuses to do

Read the guards. Every `throw`, every early return, every validation branch near the change is a
constraint the ticket has to live with — or has to change deliberately.

```bash
rg 'throw new|BadRequest|Forbidden' --type ts -n <the relevant dir>
```

Boundary conditions specifically: is the comparison `>` or `>=`? Is the range inclusive? Those get
decided by accident in code and argued about in production, so record the operator you actually
saw.

## Step 7 — What is out of reach

Anything outside this workspace. In this stack that is primarily the **Serverless OMS**, which
owns the authoritative order document and whose source is not here.

```bash
rg 'SERVERLESS_OMS|getOmsBaseUrl|serverless-oms' --type ts -l
```

You can establish **what is sent** and **what the response shape is**. You cannot establish what
the service does with it. That boundary is exactly where guesses get made, so name it in §9 and
turn it into a numbered question.

**Never infer an external service's behaviour from its client code.**

## Stack traps worth checking every time

These are cheap to check and expensive to miss.

| Check | Why |
|---|---|
| **Both legacy and OMS paths** | the migration is live on both simultaneously. `easyecom`/`Shopify`/`marketplace` are legacy-side; `source`/`shipments`/`item_codes` are OMS-side. Order-shaped logic usually needs both |
| **Which of the two create paths** | `order-management-service` (REST/Mongo/EKS) and `tsc-pos-backend` (GraphQL/DynamoDB/ECS) are different services with different logs |
| **Where config comes from** | `pos-app` resolves ~120 values from **SSM at runtime**, not `.env`. A "missing config" finding usually means a missing SSM parameter |
| **`.env.secrets` beats `.env`** | in `order-management-service`. A value can be correct in one file and overridden in the other |
| **The OMS has no log shipper** | it runs on EKS and its application logs reach no CloudWatch group. **Absence of logs is not absence of execution** — do not conclude a code path did not run |
| **Duplicate keys in dotenv files** | several exist. The last one wins, so the one you edited may not be the one in effect |
| **Existing typos are load-bearing** | `replacemt_window`, `verify-payment-transction.ts`, `VITE_REACT_APP_S3_BACKET`. Grep for the typo, not the correct spelling |
| **Commented-out legacy blocks** | large ones are kept deliberately "for reference during OMS migration". A grep hit inside one is not a call site |
| **Read the repo's own `CLAUDE.md`** | before concluding anything about a repo you have not worked in |

## What "verified" means

| Claim | Verified by |
|---|---|
| "this field is written here" | opening the file and reading the assignment |
| "nothing reads this" | a grep whose output you paste into the doc |
| "there are three callers" | opening all three |
| "the comparison is inclusive" | reading the operator |
| "the external service merges" | **cannot be verified here.** Becomes a question |
| "this will be slow" | a measurement, or it is a risk not a fact |

If you cannot name how you verified it, it is not a verified fact — move it to §6 or §9.

## When the ticket is vague

Vagueness is a finding, not an obstacle. Record what is missing, put a default against it, and
carry on. Do not fill a gap with a plausible assumption stated as fact, and do not stop the whole
investigation on one unclear sentence — research everything that does not depend on it first, then
list what does.
