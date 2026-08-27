# Integration Testing

## Purpose

Verify that multiple application components work correctly together using realistic test
environments and real persistence where appropriate.

Validates boundaries between:

* API and services
* Services and database
* Services and services
* Workflows
* Queues and workers
* Webhooks and event handlers
* Internal and external integrations

**Integration tests must not use production data or production infrastructure.**

---

## ⚠️ Two ways this workspace differs from the ideal

Read these before applying anything below literally.

### 1. There is no dedicated test database

The reference model is *"a PostgreSQL test database, isolated, wiped between runs."* This stack
has **no such thing**. The stores are:

| Store | Reality |
|---|---|
| MongoDB | shared **ustage** cluster — also used by other developers |
| DynamoDB | 71 tables in the `pos-ustage` stack — shared |
| Redis | local via `brew services start redis` — genuinely isolated |
| OpenSearch | shared |

There is **no PostgreSQL anywhere in this stack.** Adapt the examples below to Mongo collections
and DynamoDB tables.

**Consequence:** cleanup (§18) is not best practice here, it is **mandatory**. Data you leave
behind is in someone else's working environment.

### 2. `ustage` is the test environment, and it is shared

```
✅ ustage   the test environment. Shared — clean up after yourself.
❌ prod     never. Check the symlink before every run:
            ls -l ~/TSC/order-management-service/.env.secrets
```

⚠️ `.env.secrets.prod` is currently pointed at the **production** cluster from a migration-3 dry
run that was never reverted. If your symlink lands there, an integration test writes production.

---

## When to run

Run integration testing when the ticket changes or affects:

APIs · services · workflows · database behaviour · transactions · events · webhooks · queues ·
external integrations · authentication/authorization · cross-module behaviour.

If the change is isolated to a pure function with no system-boundary impact, a unit test may be
sufficient.

## Preconditions

```text
Research ✅   Spec ✅   Plan ✅   Implementation ✅   Unit tests ✅
```

Plus, in this workspace: AWS creds (`tsc-pos` profile) for SSM config resolution, Redis running,
and the `.env.secrets` symlink verified.

---

# 1. Identify integration boundaries

Record each boundary as `INT-n`. These carry over from `research.md` §12 — reuse those ids, do not
mint new ones.

```text
INT-001
Source:    createOrder mutation (pos-app)
Target:    Serverless OMS
Data:      note_attributes · tags · line items · payable
Expected:  order created with premium_order attribute when payable > threshold
```

Real boundary chains in this stack:

```text
tsc-pos-frontend → pos-app (GraphQL) → Serverless OMS
pos-app → SQS → sam-backend Lambda → DynamoDB
pos-app → order-management-service (REST + x-api-key) → Mongo
order-management-service → EasyEcom / Fynd / Freshdesk / Flowcall / Shopify / WebEngage
refund-process → pos-app (GraphQL, NO auth)
```

# 2. Identify dependencies

```text
DEP-001  MongoDB (ustage)              Database   internal
DEP-002  DynamoDB (pos-ustage)         Database   internal
DEP-003  Redis                         Cache      local
DEP-004  Serverless OMS                External   NOT in this workspace
DEP-005  Freshdesk / Flowcall          Third-party
DEP-006  SSM Parameter Store           Config     required to boot
```

Classify each: `Internal · External · Database · Queue · Webhook · Third-party API`.

# 3. Test environment

```text
Application:     ustage (NODE_ENV=ustage, STACK_NAME=pos-ustage)
Mongo:           ustage cluster — SHARED
DynamoDB:        pos-ustage tables — SHARED
Redis:           localhost:6379 — isolated
External APIs:   sandbox where one exists; MOCKED where it does not
```

Never use production database · production credentials · production API · production customer
data.

# 4. Test data

Deterministic and reproducible, and **identifiable so a human can purge it**:

```text
TEST-DATA-001
Tag:        TWP-5704-int-test        ← put this on every record you create
Customer:   +919999900001            ← reserved test number, never a real one
Order:      built via factory, not copied from prod
```

# 5. Database verification

Verify `INSERT / SELECT / UPDATE / DELETE` where applicable, plus constraints, unique indexes,
required fields, transactions, rollbacks, data consistency.

**Mongo specifics for this stack:**

* Transactions (`session.withTransaction` in `OrderRepository`) need a **replica set**. The
  managed ustage cluster is one; a standalone local `mongod` fails with a transaction-numbers
  error that never mentions replica sets.
* `LogRequestBodyMiddleware` is applied to `'*'` and writes **every request body** to
  `request_logs`. Your test payloads persist there permanently — never put realistic PII or card
  data in fixtures.
* The local `Order` schema is a thin payment/invoice ledger. The authoritative order lives in
  `oms.orders`, owned by a service **outside this workspace** — you can assert what was sent, not
  what it stored.

# 6. API integration

```text
Request → Authentication → Authorization → Validation → Service → Database → Response
```

Verify HTTP status · response schema · database state · error handling · auth · **idempotency**.

Note `order-management-service` has **no global guard** — three per-controller mechanisms, and
caller provenance is inferred from *which* API key was presented. Test with the right key for the
caller you are simulating.

# 7. Service-to-service integration

Verify the correct request and response data crosses the boundary, for both authorized and
unauthorized callers.

# 8. Workflow integration

Test the complete backend workflow, success **and** failure paths. In this stack that includes
Step Functions (`EditJourneyTimeoutStateMachine`, `PaymentLinkResendStateMachine`) — test the
timeout path, not only the happy one.

# 9. Event / webhook integration

```text
External Event → Webhook Endpoint → Event Processor → Queue/Worker → Service → Database
```

Test valid · invalid · **duplicate** · retry · delayed · missing data · processing failure.
Verify idempotency when the same event can arrive more than once.

Real webhooks here: `awb-webhook.service.ts` · `dismantling-completed-webhook.service.ts` ·
`oms-comms-webhook.service.ts` · `POST /order/webhook/*` (**unguarded**).

# 10. Queue / worker integration

```text
API → Queue → Worker → Service → Database
```

Verify job created · consumed · completed · failure retried · duplicate handled · final DB state.

Six real queues: `NotificationQueue` · `OrderShipmentQueue` · `OrderStatusSyncQueue` ·
`ExportDataQueue` · `HoldOrderQueue` · **`HoldOrderDLQ`**. The DLQ has its own handler — test the
dead-letter path, it exists because holds fail.

# 11. External integration

Test `200 · 400 · 401 · 403 · 404 · 429 · 500 · Timeout · Malformed response`.

**Use sandbox endpoints where available. Do not call production systems from automated tests.**

### These cannot be rolled back — mock the boundary

| Boundary | What a real call leaves behind |
|---|---|
| Serverless OMS | a real order in `oms.orders`, external, unreachable by cleanup |
| Freshdesk / Flowcall | a real ticket a human will triage |
| Fynd | a real pickup/drop batch |
| WebEngage | a real customer event |
| Gupshup SMS / WhatsApp | **a real message to a real phone** |
| Payment gateways | sandbox only, never live keys |

Assert the payload your code *would* send. Keep real application logic; mock only the far side.

# 12. Authentication and authorization

```text
Request → Authentication → Identity → Permission → Business Operation
```

**Do not mock authorization when the integration itself is what the ticket changes.**

Cognito pools are per-environment — a prod account will not authenticate against ustage.

# 13. Transaction testing

```text
A ✅ B ✅ C ✅ → COMMIT
A ✅ B ❌      → ROLLBACK
```

Verify the database is not left partially updated. Also verify the **compensation** patterns this
codebase relies on — e.g. `cleanupCreatedTicket` deletes a ticket when the DB write fails after
creation. If you add a provider and skip that, you orphan tickets.

# 14. Error and failure testing

Database unavailable · service unavailable · timeout · invalid response · validation failure ·
permission failure · duplicate request · network error · transaction failure.

Verify the correct error response · status · logging · retry · rollback · **final database
state**.

> **The OMS has no log shipper.** `order-management-service` runs on EKS and its application logs
> reach no CloudWatch group. **Absence of logs is not absence of execution** — do not conclude a
> path did not run because you cannot find a log line. Traces go to SigNoz.

# 15. Idempotency

```text
Request #1 with key K → creates record
Request #2 with key K → must NOT create a duplicate
```

# 16. Integration test case format

```text
INT-TC-001

Title:          Create order with premium tag through the real builder
Related:        US-001 · FR-001 · BR-002 · AC-004
Preconditions:  ustage reachable · AWS creds present · symlink verified
Test Data:      TEST-DATA-001 (tag: TWP-5704-int-test)

Steps:
  1. Build an order with post-discount payable 201,000.
  2. Call createOMSOrder with the OMS client mocked.
  3. Capture the outbound payload.
  4. Query the local ledger.

Expected Result:
  payload.note_attributes contains { name: premium_order, value: 'true' }
  ledger row created, tagged TWP-5704-int-test

Database Verification:
  db.orders.findOne({ testTag: 'TWP-5704-int-test' }) → exists

Cleanup:
  db.orders.deleteMany({ testTag: 'TWP-5704-int-test' })

Status:  PASS / FAIL / BLOCKED
```

# 17. Real database rule

Use a real database when database behaviour is part of the test.

```text
Integration Test → Application → ustage Mongo/DynamoDB → verify → CLEANUP
```

Never against prod. And since ustage is **shared**, cleanup is not optional.

**Prefer the integration test that writes nothing.** Composing several real units and asserting
on the result catches the highest-value defect class in this codebase — *two paths deriving the
same quantity differently* — with no database, no network and no cleanup. Reach for that shape
first; go to a live-service test only when the thing you must prove genuinely lives in the wiring.

# 18. Cleanup strategy

```text
Create test data → Execute → Verify → Rollback / Cleanup
```

Preferred, in order: transaction rollback · dedicated test data tagged and deleted · fixtures and
factories · cleanup scripts.

Use `afterEach`, not `afterAll` — a run that aborts mid-suite still leaves the database clean up
to that point. **Never leave unpredictable test data behind on a shared cluster.**

# 19. Test isolation

Each test creates its own data. No test depends on another's leftovers — order-dependent failures
are the hardest kind to diagnose.

# 20. Requirement traceability

```text
FR-001 → INT-TC-001      BR-001 → INT-TC-002
AC-001 → INT-TC-003      EC-001 → INT-TC-004
```

Reuse the ids from `research.md` and `spec.md`. Never renumber.

# 21. Test execution order

```text
1. Prepare environment   2. Prepare test data   3. Run targeted integration tests
4. Verify DB state       5. Verify external interactions
6. Run relevant regression integration tests   7. Cleanup   8. Report
```

Do not run the entire integration suite first unless necessary.

# 22. Integration test report

Folds into `test-report.md` as its own section — do not create a second report file.

```text
## Integration

Environment:  ustage · Mongo ustage cluster · Redis local · externals mocked

Boundaries:
  INT-001  pos-app → Serverless OMS        PASS
  INT-002  service → Mongo                 PASS

Test Cases:
  INT-TC-001 — PASS
  INT-TC-002 — FAIL

Database Verification:
  created 2 · updated 1 · rollback PASS

External Integration:
  Serverless OMS — MOCKED (cannot be rolled back)

Cleanup:  PASS — 3 records removed, verified 0 remaining

Failures:  INT-TC-002 — expected rejection, checkout succeeded
```

# 23. Definition of done

```text
[ ] All relevant integration boundaries identified (INT-n)
[ ] Test environment verified — ustage, NOT prod, symlink checked
[ ] Test data created safely and tagged
[ ] API integrations tested
[ ] Service interactions tested
[ ] Database interactions tested
[ ] Workflow tested (success AND failure)
[ ] Event/webhook tested where applicable
[ ] Queue/DLQ tested where applicable
[ ] External integration tested or explicitly mocked with a reason
[ ] Error paths tested
[ ] Transaction / rollback behaviour tested where applicable
[ ] Idempotency tested where applicable
[ ] Database state verified
[ ] Test data cleaned up — and cleanup VERIFIED, not assumed
[ ] Relevant regression tests passed
[ ] Evidence recorded in test-report.md
```
