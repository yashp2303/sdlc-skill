# Test Cases — <Feature name>

| | |
|---|---|
| **Ticket** | [<TICKET-ID>](<url>) |
| **Spec** | [`spec.md`](./spec.md) |
| **Plan** | [`plan.md`](./plan.md) |
| **Source of truth** | [`test-cases.csv`](./test-cases.csv) — status and evidence live there |

```
<n> scenarios · positive <n> · negative <n> · edge <n> · rule <n> · ui <n>
unit <n> · integration <n> · e2e <n> · manual <n>
<n> testable today · <n> blocked on Q-<n>
```

<One sentence on the largest group and why — e.g. "Negative is the largest group (18):
one per guard in `<file>`.">

---

## 1. Positive

| ID | Scenario | Expected | Level | Test function | Covers |
|---|---|---|---|---|---|
| QA-001 | <concrete situation> | <observable result> | unit | `<file> › <it name>` | AC-1 |
| QA-002 | | | | | |

---

## 2. Negative

<More rows than Positive, or a stated reason why not. Each asserts the refusal, naming the
error — not the absence of a crash.>

| ID | Scenario | Expected | Level | Test function | Covers |
|---|---|---|---|---|---|
| QA-0nn | <invalid input> | rejects with `<ERROR_CODE>` | unit | `<file> › <it name>` | BR-1 |
| QA-0nn | <missing precondition> | rejects with `<ERROR_CODE>` | unit | | |

---

## 3. Edge

| ID | Scenario | Expected | Level | Test function | Covers |
|---|---|---|---|---|---|
| QA-0nn | exactly at the boundary | | unit | | BR-2 |
| QA-0nn | one unit below the boundary | | unit | | BR-2 |
| QA-0nn | one unit above the boundary | | unit | | |
| QA-0nn | zero | | unit | | |
| QA-0nn | negative | | unit | | |
| QA-0nn | null | | unit | | |
| QA-0nn | rounding | | unit | | |
| QA-0nn | concurrent | | integration | | |
| QA-0nn | retried delivery | | integration | | |
| QA-0nn | record created before this feature existed | | integration | | |

---

## 4. Business Rules

<Each rule that prohibits something gets a case that CONSTRUCTS the prohibited state and
asserts the refusal.>

| ID | Scenario | Expected | Level | Test function | Covers |
|---|---|---|---|---|---|
| QA-0nn | <prohibited state constructed> | <the refusal> | unit | | BR-<n> |

---

## 5. UI

| ID | Scenario | Expected | Level | Test function | Covers |
|---|---|---|---|---|---|
| QA-0nn | primary flow | | e2e | | AC-<n> |
| QA-0nn | loading state | | integration | | |
| QA-0nn | empty state | | integration | | |
| QA-0nn | error state | | integration | | |
| QA-0nn | keyboard-only completion | | e2e | | |
| QA-0nn | error message is comprehensible | | manual | <walkthrough> | |

---

## 6. Not Covered

| ID | Scenario | Why not covered | Blocked by |
|---|---|---|---|
| QA-0nn | | | Q-<n> |

<Or: `Nothing excluded.`>
