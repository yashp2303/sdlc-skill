# Production Bug RCA — <BUG-ID>

> **Investigation only.** No code was changed, no data was written, nothing was deployed,
> retried, reprocessed or pushed. Every fix below is a **recommendation**.

## 1. Incident Summary

| | |
|---|---|
| **Bug** | <title> |
| **Environment** | <Production / ustage> |
| **Date/Time** | <YYYY-MM-DD HH:MM IST> |
| **Severity** | <blocker / major / minor> |
| **Reported by** | <who> |
| **Investigated by** | <who> · <date> |
| **Confidence** | **CONFIRMED / HIGHLY LIKELY / INCONCLUSIVE** — matches §19 |
| **Status** | INVESTIGATED / RCA CONFIRMED / RCA INCONCLUSIVE |

**Impact:** <one paragraph>

## 2. Expected Behavior

<what should have happened>

## 3. Actual Behavior

<what did happen — the symptom the user saw>

## 4. Expected Flow

```
<the flow as the code says it should run — discovered, not assumed>
```

## 5. Actual Flow

```
<what actually ran, from the evidence. Mark where it diverged.>
```

---

## 6. Systems Investigated

| System | Result | Evidence |
|---|---|---|
| tsc-pos-frontend | FOUND / NOT FOUND / **NOT CHECKED** | |
| pos-app (ECS) | | CloudWatch |
| sam-backend (Lambda/SQS) | | CloudWatch |
| order-management-service | | ⚠️ SigNoz + `request_logs` — no CloudWatch |
| Serverless OMS | | request/response only — external |
| Unicommerce | | |
| Shopify | | |
| Payment gateway | | |
| MongoDB | | |
| DynamoDB | | |
| Queue / DLQ | | |
| Webhook | | |
| Git history | | |

**`NOT CHECKED` is an honest value.** Do not write FOUND for a system you did not open.

## 7. Identifier Correlation

| Identifier | Value | Source |
|---|---|---|
| POS order id | | |
| OMS order id | | |
| Shopify order id | | |
| UC id | | |
| Payment transaction id | | |
| Request / correlation id | | |
| Webhook / shipment id | | |

---

## 8. Investigation Evidence

### AWS / Logs
```
<command run, and its actual output>
```

### Database
```
<read-only query, and its actual result>
```

### POS
<`file:line` + what the code does>

### Backend
<`file:line` + what the code does>

### OMS
<request sent · response received · timestamps>

### Unicommerce
<evidence>

### Payment
<transaction status — read only>

### Webhook / Queue
<event id · received vs processed · retry count · DLQ depth>

### Git history
```
git log --oneline -20 -- <file>
<output>
```

---

## 9. End-to-End Timeline

```
HH:MM:SS.mmm   <system>   <what happened>                 <evidence ref>
HH:MM:SS.mmm   <system>   <what happened>
HH:MM:SS.mmm   <system>   ❌ DIVERGENCE — see §10
HH:MM:SS.mmm   <system>   <downstream consequence>
HH:MM:SS.mmm   POS        <the symptom the user reported>
```

## 10. First Incorrect State

> The section this whole document exists to support.

| | |
|---|---|
| **Location** | <system · `file:line`> |
| **Time** | <timestamp> |
| **Expected** | <state> |
| **Actual** | <state> |
| **Evidence** | <the specific log line / record / code> |

<Why everything before this point was correct — that is what makes it the FIRST incorrect state
rather than the most visible one.>

## 11. Root Cause

<One precise technical statement. Not the symptom, not the category.>

## 12. Trigger

<What initiated it — the input, the timing, the deploy, the data shape.>

## 13. Contributing Factors

- <condition that allowed it>
- <condition that increased its impact>

## 14. Impact Analysis

| Area | Impact |
|---|---|
| Users | |
| Orders | |
| Payments | |
| Inventory | |
| Fulfillment | |
| Data | |
| Other integrations | |

<Quantify where a number exists: how many orders, over what window.>

## 15. Detection Gap

<Why existing tests and monitoring did not catch this. Be specific — "no test covered the
mapping", "the OMS has no log shipper so nothing alerted", "no assertion on the boundary value".>

---

## 16. Recommended Fix

> **Recommended — not implemented.**

| | |
|---|---|
| File / module | `<path>` |
| Function | `<name>` |
| Logic change | <what should change> |
| Database change | <or none> |
| Integration change | <or none> |
| Configuration change | <or none> |
| Risk | <what could break> |
| Backward compatibility | <yes / no + why> |
| Rollback consideration | <how to undo> |

## 17. Recommended Regression Tests

**Unit** — <the assertion that would have caught this>
**Integration** — <the boundary test>
**Playwright / E2E** — <the journey>

Cover: the original failure case · happy path · edge cases · timeout · invalid response ·
unexpected response · retry · duplicate event · partial failure.

## 18. Recommended Validation

- [ ] Unit tests
- [ ] Integration tests
- [ ] Playwright / E2E
- [ ] TypeScript
- [ ] Lint
- [ ] Build
- [ ] End-to-end business flow

## 19. RCA Confidence

**<CONFIRMED / HIGHLY LIKELY / INCONCLUSIVE>**

**Reason:** <evidence-based. If HIGHLY LIKELY, name the one dependency you could not verify. If
INCONCLUSIVE, name the one thing that would settle it.>

## 20. Investigation Limitations

<What could not be accessed or verified. In this workspace this is never empty — the Serverless
OMS source is not here, so its internal behaviour is always inferred from request/response only.>

| Limitation | Why | What would resolve it |
|---|---|---|
| | | |

## 21. Final Conclusion

| | |
|---|---|
| **Root Cause** | <one precise statement> |
| **Recommended Fix** | <one precise statement> |
| **Prevention** | <one precise statement> |
| **Status** | INVESTIGATED / RCA CONFIRMED / RCA INCONCLUSIVE |

**Next step:** <hand to `/feature-docs <TICKET>` for the fix pack, or name the open question and
its owner.>
