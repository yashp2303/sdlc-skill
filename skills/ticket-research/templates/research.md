# Ticket Research Report — <TICKET-ID>

| | |
|---|---|
| **Ticket** | [<TICKET-ID>](<url>) |
| **Title** | <the ticket's own title, verbatim> |
| **Source** | <Jira · Slack · verbal> |
| **Readiness** | <**READY** · **NEEDS CLARIFICATION** · **BLOCKED**> — must match §25 |
| **Author** | <name> |
| **Checked against** | branch `<branch>` at `<sha>`, env `<ustage/prod>`, <YYYY-MM-DD> |

---

## 1. Ticket Summary

<3–5 sentences: what is asked, for whom, and the one thing that makes it harder or easier than it
looks. No analysis yet.>

## 2. Business Understanding

<Why this is being asked — the decision or capability it unlocks. Quantify where a number exists.
If the ticket never says why, that absence is a finding — raise it as an OQ.>

---

## 3. Requirements

### 3.1 User Stories — `US`

| ID | Story |
|---|---|
| US-1 | As a <role>, I want <capability>, so that <outcome>. |

### 3.2 Functional Requirements — `FR`

| ID | Requirement | Priority |
|---|---|---|
| FR-1 | <one observable behaviour, no technology> | Must |

### 3.3 Business Rules — `BR`

| ID | Rule |
|---|---|
| BR-1 | <the constant or threshold, stated exactly> |
| BR-2 | <boundary inclusivity — `>` or `>=`, state it even when obvious> |
| BR-3 | <which value is compared, and what is excluded from it> |

### 3.4 Validation Rules — `VR`

| ID | Input | Accepted / Rejected | Error |
|---|---|---|---|
| VR-1 | <input> | rejected | `<ERROR_CODE>` |

### 3.5 Data Rules — `DR`

| ID | Rule |
|---|---|
| DR-1 | <source of truth · nullability · default · retention> |
| DR-2 | <what happens to records that predate this feature> |

### 3.6 Scenarios — `SC`

| ID | Scenario | Status |
|---|---|---|
| SC-1 | <concrete end-to-end path> | ready |
| SC-2 | <path> | blocked on OQ-<n> |

### 3.7 Acceptance Criteria — `AC`

| ID | Criterion |
|---|---|
| AC-1 | **Given** <state> **When** <action> **Then** <observable result> |
| AC-2 | **Given** <state exactly on the BR boundary> **When** <action> **Then** <result> |

### 3.8 Edge Cases — `EC`

| ID | Case | Expected | Risk if wrong |
|---|---|---|---|
| EC-1 | exact boundary | | |
| EC-2 | one unit either side | | |
| EC-3 | zero / negative / null | | |
| EC-4 | rounding | | |
| EC-5 | concurrent / retried | | |
| EC-6 | records predating the feature | | |

---

## 4. Doubts / Ambiguities

<Every name the ticket uses. **Mismatches first.**>

| Name in the ticket | Exists? | Reality |
|---|---|---|
| `<name>` | ❌ **no such thing** | <what exists instead> — `<file>:<line>` |
| `<name>` | ⚠️ different shape | <what it really is> — `<file>:<line>` |
| `<name>` | ✅ | `<file>:<line>` |

<For each ❌/⚠️, name both words and what to ask:>

> The ticket says "<their word>". <Reality.> If they mean <A>, then <consequence>; if <B>, then
> <other>. **Ask before estimating.**

## 5. Open Questions — `OQ`

<Lead with which block work.>

| ID | Question | Why it matters | Default if unanswered | Owner |
|---|---|---|---|---|
| OQ-1 | | | | |

## 6. Assumptions — `ASM`

| ID | Assumed | If false |
|---|---|---|
| ASM-1 | <believed, not verified> | <what breaks, concretely> |

---

## 7. Existing Code Analysis

<Every claim carries `file:line`.>

```
`<file>:<line>` — <what it does today, and why that constrains the change>
`<file>:<line>` — <guard: throw / early return / validation branch>
```

**Where the numbers come from** — path A: `<file>:<line>` · path B: `<file>:<line>`
<If the two differ, say so — this is the most common trap.>

## 8. Similar Existing Implementations

<The nearest thing that already exists — `file:line`. Follow the pattern or deliberately break
it, and say which. Is the rule already duplicated?>

## 9. Git History Findings

```bash
git log --oneline -20 -- <files>
git log -S'<identifier>' --oneline
```

<When this area last changed and why · prior attempts and reverts · stale "temporary" comments ·
who last touched it · related migration in flight.>

## 10. API Analysis — `API`

| ID | Operation | Where | Auth | Change | Backwards compatible? |
|---|---|---|---|---|---|
| API-1 | | `<file>:<line>` | | | |

## 11. Database Analysis

| Store | Collection / table | Fields | Owner | Change |
|---|---|---|---|---|
| | | | | |

<Indexes · migration or backfill needed · nullability · do existing rows satisfy the new
invariant?>

## 12. Integration Analysis — `INT`

| ID | Integration | Direction | Effect of this ticket |
|---|---|---|---|
| INT-1 | | | |

<Anything external: mark behaviour UNVERIFIABLE and raise an OQ. Never infer from client code.>

## 13. Dependency Analysis

| Dependency | Owner | Blocks |
|---|---|---|
| | | |

<Other tickets this blocks or is blocked by.>

## 14. Impact Analysis

<What else changes as a consequence.>

```bash
rg '<sharedFn>\(' --type ts -n     # <n> callers
```

<Other call sites · reports/dashboards · the legacy path as well as OMS · downstream consumers ·
existing records · hot-path performance · caches.>

## 15. Risks — `RISK`

| ID | Risk | Size | Mitigation |
|---|---|---|---|
| RISK-1 | <what breaks> | <arithmetic> | <what you would do, or the explicit choice not to> |

---

## 16. Technical Blockers

**Hard** — <cannot start / would be thrown away, citing OQ-n or file:line>
**Soft** — <can start on a default; rework cost if wrong>
**None for** — <the parts fully verified>

## 17. Business Blockers

<Missing decisions, approvals, requirement owners. Name who decides.>

## 18. Environment Blockers

| Blocker | Blocks | Owner |
|---|---|---|
| <access · seed data · sandbox · SSM param · deployed dependency> | TC-<n>..<n> | |

---

## 19. Test Impact — `TC`

| ID | Scenario | Type | Level | Covers | Blocked by |
|---|---|---|---|---|---|
| TC-1 | | positive | unit | AC-1 | — |
| TC-2 | | negative | unit | VR-1 | — |
| TC-3 | | edge | unit | EC-1 | — |

<Positive · negative · every EC family. **Negative should outnumber positive** — every guard in §7
is a negative case. Close with the honest count: "N cases, M runnable today, K blocked on OQ-n."
Also: which existing tests touch this code and might break.>

## 20. Recommended Implementation

<The approach in a paragraph or two, plus **the one design decision** and the alternative
rejected. Not code, not steps.>

## 21. Files Likely To Change

| File | Change | New? | Confidence |
|---|---|---|---|
| | | | high / medium / low |

<Include tests and migrations.>

## 22. Files That Should NOT Be Changed

| File | Why not |
|---|---|
| | |

<Also: files a formatter would rewrite if touched.>

## 23. Implementation Order

```
1  <step>   AC-<n>..<n>   ← safe stopping point
2  <step>   AC-<n>
3  <step>   AC-<n>        ← gated on OQ-<n>, do not start
```

## 24. Research Evidence

```bash
rg '<pattern>' --type ts -n        # <n> hits
git log --oneline -20 -- <file>
```

**Files opened:** <list>
**Could not check:** <what, and why>

---

## 25. Final Readiness

**<READY | NEEDS CLARIFICATION | BLOCKED>** — <the one-line reason>

Ready now: <SC-n, SC-n>
Blocked: <SC-n> on OQ-<n>, owner <who>

Next:
1. <action>
2. <action>

Estimate, conditional: **<n>h** for <verified scope>. **+<n>h** if OQ-<n> resolves to <A>;
<different outcome> if <B>.
