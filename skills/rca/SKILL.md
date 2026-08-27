---
name: rca
description: "Investigate a reported bug end-to-end across every system in the affected flow and produce an evidence-backed Root Cause Analysis. Strictly read-only — no writes, no retries, no reprocessing, no deploys. Finds the FIRST incorrect state, never guesses. Use when a production or UAT bug is reported. Trigger: /rca"
---

# Bug Investigation and RCA

Investigate a reported bug across every system involved and produce a complete, evidence-backed
RCA.

The investigation is **read-only · evidence-driven · traceable · explicit about uncertainty**, and
its single goal is to identify the **first incorrect state** — not the last visible error.

**Never guess the root cause.**

**This skill produces exactly one thing: an RCA backed by evidence.**

```
✅ produces    docs/<BUG-ID>-<slug>/rca.md   — findings, evidence, root cause,
                                               recommended fix, recommended tests

❌ never       no code changes      no commits      no pushes
               no deploys           no rollbacks    no migrations
               no retries           no reprocessing no data writes
```

It **recommends** a fix. It never implements one. Implementation is a separate decision, taken by
a human, through `/feature-docs` → `/tsc-ticket` after the RCA is accepted.

```
READ → SEARCH → CORRELATE → ANALYZE → VERIFY → PROVE → REPORT
```

Never `READ → MODIFY → RETRY → REPROCESS → DEPLOY`.

---

# 1. STRICT READ-ONLY POLICY

Inspect, search, query, compare, correlate, analyze. Nothing else.

### Allowed

CloudWatch and application logs · database **reads** and schema · OMS and Unicommerce
request/response · POS, backend and integration code · API logs · payment transaction **status** ·
Shopify data · webhook events · queue metadata where reading is non-mutating · SigNoz traces ·
metrics · configuration · `git log` / `show` / `diff` / `blame` · PRs · timestamp and identifier
correlation · findings, RCA, recommended fixes, recommended tests.

### Prohibited

`INSERT · UPDATE · DELETE · TRUNCATE · ALTER · DROP` · migrations · modifying prod/UAT data,
config or env vars · restarting services · deploying · rolling back · creating/updating/deleting
AWS resources · purging queues · **reprocessing or retrying messages** · triggering webhooks ·
any API call that changes state · creating/cancelling orders · creating/refunding/capturing
payments · modifying inventory, fulfillment, OMS, UC or Shopify data · modifying files ·
commits · pushes · PRs · merges.

> **Safety rule.** If an operation *can* modify data, state, configuration, infrastructure or an
> external system — **do not execute it.** Use read-only inspection instead.

### Read-only mode is enforced by a hook, not just by this instruction

In the TSC workspace the policy is a **wall**, not a request. Turn it on at the start of an
investigation and off at the end:

```bash
touch ~/TSC/.claude/.rca-readonly     # enter  — writes now BLOCKED at the tool boundary
rm    ~/TSC/.claude/.rca-readonly     # leave
```

While active, `.claude/bin/rca-readonly-guard.sh` (a `PreToolUse` hook) denies `Write`, `Edit`,
`NotebookEdit`, and any Bash matching a state-changing pattern — `git push/commit`, `sam deploy`,
`kubectl` mutations, `purge-queue`, `receive-message`, mutating `aws` calls, Mongo writes, SQL
writes, anything touching `.env.secrets.prod` or `prod:local`, non-GET `curl`, and shell
redirection outside `/tmp`. Reads pass through untouched: `git log/show/blame`,
`aws logs/describe/get-*/query/scan`, `mongosh find/aggregate`, `sam logs`, `kubectl get`.

Verified: 25/25 cases classified correctly.

**If the guard blocks you, that is the answer.** Record it as an investigation limitation in §20 —
do not work around it. Wanting to "just re-run it and see" is exactly the impulse the guard exists
to stop.

### What that means for the tools available here

| Safe | Never |
|---|---|
| `Read`, `Grep`, `Glob` | `Write`, `Edit`, `NotebookEdit` |
| `git log/show/diff/blame`, `git status` | `git commit/push/checkout/stash/restore` |
| `mongosh --eval 'db.x.find(...)'` | any `insert/update/delete/drop` |
| `aws logs`, `aws ssm get-parameter`, `aws dynamodb get-item/query/scan` | any `put/update/delete/create` AWS call |
| `curl` **GET** against a read endpoint | any POST/PUT/PATCH/DELETE |
| `sam logs`, `aws cloudformation describe-*` | `sam deploy`, `cancel-update-stack` |

**Running the app is a write.** Do not start `run.sh` against prod to "see what happens" — that
executes real code against real data.

---

# 2. INPUT

Take whatever exists. Do not require every field.

Bug ID · title · description · environment · store · order ID · SKU · customer · employee ·
transaction/payment ID · request/correlation ID · webhook/shipment/fulfillment/refund ID ·
timestamp · endpoint · error message · screenshot · logs · expected vs actual behaviour.

If no ticket id is given, ask for one — the folder needs it.

# 3. NORMALIZE IDENTIFIERS

Build the identifier map **before** investigating. One id unlocks the others, and cross-system
search is impossible without it.

| Identifier | Value | Source |
|---|---|---|
| POS order id | | POS |
| OMS order id | | Serverless OMS |
| Shopify order id | | Shopify |
| UC / Unicommerce id | | Unicommerce |
| Payment transaction id | | gateway |
| Request / correlation id | | CloudWatch |
| Webhook / shipment id | | webhook payload |

# 4. UNDERSTAND THE EXPECTED FLOW

Establish how the transaction is *supposed* to work **from the code**, not from memory. The
architecture reference is `docs/end-to-end-architecture.md` — pre-order in Part II, post-order in
Part III, with 8 sequence diagrams.

Do not assume a flow. Discover it.

# 5–6. DISCOVER SYSTEMS, THEN BUILD THE MATRIX

The real systems in this stack, and where to look, are in
`references/investigation-matrix.md`. Fill one row per system:

| System | Investigation | Status | Evidence |
|---|---|---|---|
| … | … | FOUND / NOT FOUND / **NOT CHECKED** | … |

**Do not claim a system was investigated unless you actually looked.** `NOT CHECKED` is an honest
value and it belongs in the report.

# 7–18. INVESTIGATE AND CORRELATE

Per-system procedure — logs, database, API, OMS, Unicommerce, payment, webhook, queue, POS code,
backend code, git history — is in `references/investigation-matrix.md`.

End by building a **timestamp-ordered end-to-end timeline** across every system.

# 19. FIND THE FIRST INCORRECT STATE

**The primary RCA rule.** Find the earliest point where `Expected != Actual`.

```
OMS response = SUCCESS          ✅ correct
Backend receives SUCCESS        ✅ correct
Backend maps SUCCESS → FAILED   ❌ FIRST INCORRECT STATE
DB stores FAILED                   downstream consequence
POS shows error                    the symptom the user reported
```

**The last visible error is almost never the root cause.** Walk backwards until expected and
actual agree, then step forward one.

# 20. CLASSIFY

**Symptom** what the user saw · **Trigger** what initiated it · **Root Cause** the exact technical
defect · **Contributing Factors** what allowed it · **Impact** who and what was affected ·
**Detection Gap** why tests and monitoring missed it.

# 21. EVIDENCE REQUIREMENT

Every claim carries evidence: source · timestamp · identifier · `file:line`.

Never write *"probably caused by…"* without labelling it **unverified**. An unlabelled guess in an
RCA gets quoted as fact in the next meeting.

# 22. CONFIDENCE

| Level | Means |
|---|---|
| **CONFIRMED** | direct evidence proves the root cause |
| **HIGHLY LIKELY** | strong evidence, but one important dependency could not be verified — **name it** |
| **INCONCLUSIVE** | evidence is insufficient. Say what would settle it |

State the level explicitly. `INCONCLUSIVE` is a real, useful outcome — an inflated `CONFIRMED`
sends someone to fix the wrong thing.

# 23–25. RECOMMEND, DO NOT IMPLEMENT

Recommend the fix (file · function · logic · risk · backward compatibility · rollback), the
regression tests (unit · integration · Playwright), and the validation plan.

Heading is **Recommended Fix**, never *Implemented Fix*. Do not create the tests. Do not touch the
repo. Hand over to `/feature-docs` or `/tsc-ticket` once the RCA is accepted.

# 26. THE REPORT

21 sections, all of them, every time. Format in `references/rca-format.md`, fillable template in
`templates/rca.md`.

```
 1 Incident Summary         12 Trigger
 2 Expected Behavior        13 Contributing Factors
 3 Actual Behavior          14 Impact Analysis
 4 Expected Flow            15 Detection Gap
 5 Actual Flow              16 Recommended Fix
 6 Systems Investigated     17 Recommended Regression Tests
 7 Identifier Correlation   18 Recommended Validation
 8 Investigation Evidence   19 RCA Confidence
 9 End-to-End Timeline      20 Investigation Limitations
10 First Incorrect State    21 Final Conclusion
11 Root Cause                  INVESTIGATED / RCA CONFIRMED / RCA INCONCLUSIVE
```

§10 is the section the whole document exists to support.

---

## The trap that will mislead you in this stack

**`order-management-service` runs on EKS with no log shipper.** Its application logs reach **no
CloudWatch log group**.

> **Absence of logs is not absence of execution.**

If you conclude "the OMS never received the request" because CloudWatch is empty, you will be
wrong and the RCA will send someone to fix a working system. Use **SigNoz** for its traces, and
the Mongo **`request_logs`** collection — `LogRequestBodyMiddleware` is applied to `'*'` and
records **every request body** that service received. That collection is the single best RCA
source in this workspace.

Three more, in `references/investigation-matrix.md`: the legacy/OMS dual path means half the
evidence can look absent · `oms-sync-errors` and `orders-oms-log` already record known drift ·
and the two order-create paths derive the same quantities differently.

## Failure handling

| Situation | What to do |
|---|---|
| a system cannot be accessed | mark it **`NOT VERIFIED`** in §6 and list it in §20. Never leave it blank |
| evidence is missing | **do not fabricate it.** Continue with the systems you can reach |
| **evidence conflicts** | **report the conflict** — do not silently pick the source that fits your theory. Two sources disagreeing is itself a finding, and often the root cause |
| one system shows an error | keep going. **Never stop merely because one system shows an error** — that error is usually a downstream symptom, and stopping there produces an RCA that names the last failure instead of the first |

## Stop conditions

Stop only when **either**:

- the root cause is confirmed with sufficient evidence, or
- available evidence is insufficient and the RCA is marked **`INCONCLUSIVE`**, with the one thing
  that would settle it named.

Anything else is stopping early.

## Two failure modes

**An RCA that names the last error.** If §10 and §11 point at the same place the user's screenshot
did, you have not walked backwards yet.

**An RCA with no limitations section.** §20 is never empty in this workspace — the Serverless OMS
source is not here, so something always ends at a boundary you cannot cross. Say so.
