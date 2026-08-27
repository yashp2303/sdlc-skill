# Investigation matrix — the real systems, and where to look

Every command here is **read-only**. Nothing in this file writes, retries, reprocesses, deploys or
pushes.

## The systems that actually exist in this stack

| System | What it is | Where its evidence lives |
|---|---|---|
| `tsc-pos-frontend` | React POS, S3 static | browser console · Clarity · GA · the code |
| `tsc-pos-backend/pos-app` | NestJS GraphQL, ECS Fargate | **CloudWatch** |
| `tsc-pos-backend/sam-backend` | 27 Lambdas · 6 SQS · 2 Step Fns · 71 DynamoDB tables | **CloudWatch** per function |
| `order-management-service` | NestJS REST, **EKS** | ⚠️ **no CloudWatch** — SigNoz + Mongo `request_logs` |
| `refund-process` | public refund form, no auth | browser only · stale repo |
| **Serverless OMS** | authoritative order store | ⚠️ **not in this workspace** — you see requests and responses only |
| Unicommerce | fulfilment | its own console · `sam-deploy` config names the endpoint |
| Shopify | legacy order side | Shopify admin |
| EasyEcom · Fynd · Freshdesk · Flowcall · WebEngage | integrations | `order-management-service` request logs |
| Razorpay/Ezetap · PayU · PineLabs · Mswipe · Snapmint · Gyftr · ePay | payments | gateway dashboards · `payments` module logs |

**There is no PostgreSQL in this stack.** The stores are MongoDB, DynamoDB, OpenSearch and Redis.

---

## ⚠️ The four traps that produce wrong RCAs here

**1. The OMS has no log shipper.** `order-management-service` runs on EKS and its application logs
reach **no CloudWatch group**. An empty CloudWatch search proves nothing about that service.
**Absence of logs is not absence of execution.** Use SigNoz and `request_logs`.

**2. `request_logs` is your best source, and most people forget it exists.**
`LogRequestBodyMiddleware` is applied to `'*'`, so **every request body** that service received is
in Mongo:

```bash
mongosh "$MONGO_DB_URI" --quiet --eval '
  db.request_logs.find({ "body.order_id": "<ORDER_ID>" })
    .sort({ _id: -1 }).limit(5).pretty()'
```

**3. The legacy and OMS paths are both live.** Evidence can be "missing" simply because the
transaction went down the other path. `easyecom` / `Shopify` / `marketplace` fields are
legacy-side; `source` / `source_name` / `shipments` / `item_codes` are OMS-side. Check both before
concluding data is absent.

**4. Known drift is already recorded.** `views/oms-sync-errors` and the `orders-oms-log` module
exist because POS and the OMS drift. **Check those first** — the bug may already be catalogued.

---

## §7 — Logs

```bash
# pos-app (ECS) and the Lambdas
aws logs describe-log-groups --profile tsc-pos --region ap-south-1 \
  --query 'logGroups[].logGroupName'

aws logs filter-log-events --profile tsc-pos --region ap-south-1 \
  --log-group-name <group> \
  --start-time $(( $(date -j -f '%Y-%m-%d %H:%M' '2026-08-26 10:00' +%s) * 1000 )) \
  --filter-pattern '"<ORDER_ID>"'

# one Lambda, tailing
sam logs --stack-name pos-ustage --name HoldOrderHandler --profile tsc-pos
```

Search by order id · transaction id · request id · correlation id · external reference · exact
timestamp · error message.

Capture for each hit: timestamp · service · request · response · HTTP status · error · stack
trace · retry count · correlation id.

## §8 — Database

**MongoDB** (`order-management-service`), read-only:

```bash
mongosh "$MONGO_DB_URI" --quiet --eval '
  db.orders.findOne({ order_id: "<ID>" });
  db.return_replacement.find({ order_id: "<ID>" }).pretty();
  db.replacemt_window.findOne({ sku: "<SKU>" });          // typo is real
  db.request_logs.find({}).sort({_id:-1}).limit(3).pretty();
'
```

**DynamoDB** (`sam-backend`), read-only:

```bash
aws dynamodb get-item  --table-name <table> --key '{"pk":{"S":"<pk>"},"sk":{"S":"<sk>"}}' \
  --profile tsc-pos --region ap-south-1
aws dynamodb query --table-name <table> --key-condition-expression 'pk = :p' \
  --expression-attribute-values '{":p":{"S":"<pk>"}}' --profile tsc-pos --region ap-south-1
```

Compare **expected vs actual** state, and look for: missing record · duplicate · wrong status ·
wrong amount · wrong reference id · broken relationship · partial state · failed update · stale
state · unexpected timestamp.

Two schema facts that mislead: the local `Order` collection is a **thin payment/invoice ledger** —
it has no `metadata`, `source`, `channel`, `order_status` or `order_status_history`, and **no
`updatedAt`**. A document with those fields is `oms.orders`, owned by the external service.

## §9–10 — API and OMS

For each call: request (endpoint · method · timestamp · payload · identifiers) and response
(status · code · error · payload · timestamp).

Then decide: did the request arrive · was it valid · did it succeed · business failure or
technical failure · timeout · retried · **was the response mapped correctly**.

That last one is the most common root cause in this codebase — a correct response interpreted
incorrectly. See §19 in the skill.

For the OMS specifically you can establish **what was sent** and **what came back**. You cannot
establish what it did internally — that is an investigation limitation (§20), never an inference.

## §11 — Unicommerce

Request · response · order state · shipment state · inventory · facility/store mapping · SKU
mapping · channel mapping · sync status · retries.

Determine whether the issue began **before UC · inside the UC integration · inside UC · after the
UC response**. The four are different tickets with different owners.

## §12 — Payment

Nine providers. Inspect request · transaction id · gateway response · response code · status ·
expiry · timeout · retry · callback · webhook · capture · refund.

**Never trigger, retry, capture or refund a payment transaction.** Read status only.

Note split payments are first-class — `paymentDetails[]` is an array, and the refund form forces
bank transfer when more than one mode was used.

## §13 — Webhooks

Real ones: `awb-webhook.service.ts` · `dismantling-completed-webhook.service.ts` ·
`oms-comms-webhook.service.ts` · `POST /order/webhook/payment-details` and
`/order/webhook/shopify-web-engage` — **both unguarded**.

Check: event id · type · sender · payload · received vs processed timestamp · HTTP response ·
retry count · **duplicate delivery**.

## §14 — Queue / async

Six queues: `NotificationQueue` · `OrderShipmentQueue` · `OrderStatusSyncQueue` ·
`ExportDataQueue` · `HoldOrderQueue` · **`HoldOrderDLQ`**.

```bash
aws sqs get-queue-attributes --queue-url <url> --attribute-names All \
  --profile tsc-pos --region ap-south-1     # read-only: depth, in-flight, DLQ counts
```

**Do not purge, retry, reprocess or receive-and-delete messages.** A message sitting in
`HoldOrderDLQ` is evidence; consuming it destroys the evidence.

## §15–16 — POS and backend code

Trace: `Controller/Resolver → Service → lib/<verb-noun>.ts → Integration client → External →
Response mapper → Database → Response`.

Ask: what does POS send · what does it expect · what did the service actually return · is POS
interpreting it correctly · does existing code already handle this · is a condition missing · **is
success treated as failure, or failure as success**.

Stack-specific things to check every time:

- **`createOMSOrder` has three callers** — logic present at one may be missing at the other two.
- **Two order-create paths derive the same quantities differently** — `getCreatePathPayableValue`
  vs `getEditPathPayableValue`. A value that looks wrong may be the other path's definition.
- **`.env.secrets` overrides `.env`** in `order-management-service`. A config value can be correct
  in one file and silently overridden in the other.
- **`pos-app` config comes from SSM at runtime**, keyed by `STACK_NAME` — a "missing config" bug is
  usually a missing SSM parameter, not a missing `.env` line.
- **Duplicate keys in dotenv files** — several exist; the last one wins.
- **Existing typos are load-bearing** — grep `replacemt_window`, not `replacement_window`.

## §17 — Git history

```bash
git log --oneline -20 -- <file>
git log -S'<identifier>' --oneline          # when did this string appear or vanish
git blame -L <start>,<end> <file>
git show <sha>
```

Look for: when the behaviour changed · a prior attempt that was **reverted** · a shared file
modified by another feature · a condition removed · a "temporary" comment now years old · who last
touched it (your reviewer).

Remember the branch mapping is not 1:1 — `oms-stage` deploys to **ustage**, and a `prod` branch
exists in only two of the four repos.

## §18 — Correlate

Build one timestamp-ordered timeline across every system. The timeline is what makes §10 (first
incorrect state) provable rather than asserted — without it you have a pile of findings and an
opinion.
