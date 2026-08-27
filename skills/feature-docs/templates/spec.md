# <Feature name> — <scope>

| | |
|---|---|
| **Ticket** | [<TICKET-ID>](<url>) — <ticket title> |
| **Title** | <the feature, not the ticket summary> |
| **Version** | 0.1 |
| **Date** | <YYYY-MM-DD> |
| **Status** | Draft |
| **Owner** | <person's name> |

---

## 2. Executive Summary

<Three to five sentences. What changes, for whom, what becomes possible. A reader who stops
here can repeat the feature back correctly. No background, no "this document describes".>

---

## 3. Business Problem

<What is wrong today, in business terms. Every "today the system…" claim carries a
`file:line`. Quantify the cost where a number exists.>

<If the requirement names something that does not exist in the codebase — a status, field,
role, screen — that mismatch goes here, FIRST, before anything else.>

---

## 4. Business Goal

<The decision or capability this unlocks. One or two sentences, measurable — you must be
able to tell afterwards whether it was met. Not the feature restated.>

---

## 5. Scope

### 5.1 In Scope

- <capability, not task>
- <capability, not task>

### 5.2 Out of Scope

- <thing a reader might assume is included> — <half-line reason>
- <thing a reader might assume is included> — <half-line reason>

### 5.3 Future Scope

- <deferred item> — <the condition that would bring it forward>

---

## 6. Actors / Users

| Actor | Description | What they do in this feature |
|---|---|---|
| <role> | <who they are> | <their part> |
| <external system / job> | <what it is> | <its part> |

---

## 7. Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-1 | <one observable behaviour, no technology, testable> | Must |
| FR-2 | <one observable behaviour> | Should |

---

## 8. Business Rules

| ID | Rule |
|---|---|
| BR-1 | <the constant or invariant, stated exactly> |
| BR-2 | <boundary inclusivity — state it explicitly even when obvious> |
| BR-3 | <which value is compared, and what is excluded from it> |

---

## 9. User Flows

### <Flow name> — <actor>

1. <step where the actor does or sees something>
2. <step>
3. <step>

<Happy path only. Alternatives go in §11.>

---

## 10. Acceptance Criteria

| ID | Criterion |
|---|---|
| AC-1 | **Given** <state> **When** <action> **Then** <observable result> |
| AC-2 | **Given** <state at the exact boundary> **When** <action> **Then** <result> |

<No technology. Mechanically checkable without asking a question.>

---

## 11. Edge Cases

| Case | Expected behaviour | Risk if wrong |
|---|---|---|
| <exact boundary> | | |
| <one unit either side> | | |
| <zero / negative / null> | | |
| <rounding> | | |
| <concurrent / retried> | | |
| <records created before this feature existed> | | |

---

## 12. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Performance | <a number, not "fast"> |
| Volume | |
| Auditability | |
| Permissions | |

<Or: `None beyond existing platform standards.`>

---

## 13. Dependencies & Assumptions

**Dependencies**

| ID | Dependency | Owner |
|---|---|---|
| D-1 | <must exist or happen elsewhere> | <team/person> |

**Assumptions**

| ID | Assumed | If false |
|---|---|---|
| A-1 | <believed true, not verified> | <what breaks, concretely> |

---

## 14. Open Questions

<Lead with the count that blocks work: which question gates what.>

| ID | Question | Why it matters | Default if unanswered | Owner |
|---|---|---|---|---|
| Q-1 | | | | |
| Q-2 | | | | |

---

## 15. Revision History

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | <YYYY-MM-DD> | <name> | initial draft |
