Investigate a reported bug end-to-end and produce an evidence-backed Root Cause Analysis.

Invoke the Skill tool with `skill: "rca"` before doing anything else, passing `$ARGUMENTS` through
as the args. Follow that skill's instructions exactly — it owns the read-only policy, the
investigation matrix and the report format.

Arguments: `<BUG-ID> <whatever you have>` — title, description, environment, order id, transaction
id, request id, timestamp, error message, screenshot text, expected vs actual. Not every field is
required; use whatever identifiers exist.

**STRICTLY READ-ONLY. Produces an RCA and nothing else.**

```
✅ reads logs · databases · code · git history · API request/response · traces
❌ no code changes · no commits · no pushes · no PRs
❌ no deploys · no rollbacks · no migrations
❌ no retries · no reprocessing · no queue purges · no webhook triggers
❌ no INSERT/UPDATE/DELETE · no payment capture/refund · no state-changing API calls
```

If an operation *can* modify data, state, config, infrastructure or an external system — it is not
run. Inspection only.

Produces one file, `docs/<BUG-ID>-<slug>/rca.md`, with 21 sections: incident summary · expected vs
actual behaviour · expected vs actual flow · systems investigated · identifier correlation ·
evidence · end-to-end timeline · **first incorrect state** · root cause · trigger · contributing
factors · impact · detection gap · recommended fix · recommended regression tests · recommended
validation · confidence (CONFIRMED / HIGHLY LIKELY / INCONCLUSIVE) · limitations · conclusion.

The goal is the **first** incorrect state, not the last visible error. Every claim carries
evidence: source, timestamp, identifier, `file:line`. Never guess a root cause — label anything
unverified as unverified.

It **recommends** a fix; it never implements one. Implementation is a separate human decision via
`/feature-docs` → `/tsc-ticket`.
