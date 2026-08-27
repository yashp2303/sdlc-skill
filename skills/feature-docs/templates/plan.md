# Plan — <Feature name>

| | |
|---|---|
| **Ticket** | [<TICKET-ID>](<url>) |
| **Spec** | [`spec.md`](./spec.md) |
| **Status** | Draft · <or: Blocked on Q-1> |
| **Date** | <YYYY-MM-DD> |
| **Estimate** | <n>h if <Q-1 resolves one way>, <n>h+ if <the other> |

---

## Objective

<What this plan delivers, in two or three sentences — then the one thing that makes it
harder or easier than it looks. Only include that second part if the reader's instinct is
actually wrong.>

---

## Requirements

| Spec | Behaviour | Where it lands |
|---|---|---|
| FR-1 | <short> | Step <n> — `<file>` |
| FR-2 | <short> | Step <n> — `<file>` |
| BR-2 | <short> | Step <n> — the shared helper |

<Every `Must` from the spec appears. Cite ids; do not re-explain them.>

---

## Current State

<Every claim carries `file:line`.>

```
`<file>:<line>` — <what it does today, and why that constrains the change>
`<file>:<line>` — <write site>
`<file>:<line>` — <read site>
```

**Write sites** — <n found, or none>
**Read sites** — <n found, or none>
**Nearest existing implementation** — `<file>`
**Where the numbers come from** — <path A>: `<file>:<line>` · <path B>: `<file>:<line>`
**Out of reach** — <external service>, see Q-<n>. Behaviour not inferred.

```bash
# the grep that found the call sites
rg '<pattern>' --type ts
```

---

## Proposed Approach

<The shape of the solution in a paragraph or two.>

**Design decision.** <The one decision, the alternative rejected, and why.>

---

## Implementation Steps

### Step 1 — <name>                                            (FR-<n>, AC-<n>..<n>)

**File:** `<path>` <(new)>

<What changes, in one line.>

```ts
// real code, not pseudocode
```

**Done when:** <checkable without judgement>

### Step 2 — <name>                                            (FR-<n>, AC-<n>)

**File:** `<path>:<line>`

```ts
// real code
```

**Done when:** <checkable>

---

## Files to Change

| File | Change | Lines | New? |
|---|---|---|---|
| `<path>` | <the shared helper> | ~<n> | new |
| `<path>` | <edit at line n> | ~<n> | edit |
| `<path>` | unit tests | ~<n> | new |

**Traps:** <files that are not formatter-clean — new files only> · <typos to preserve>

---

## Testing Plan

| Level | What it covers | Where |
|---|---|---|
| unit | <the decision, every boundary in BR> | `<spec file>` |
| integration | <the behaviour reaching the boundary> | `<spec file>` |
| manual | <what cannot be automated> | <environment> |

Enumeration: [`test-cases.md`](./test-cases.md) · [`test-cases.csv`](./test-cases.csv)

<n> cases · <n> testable today · <n> blocked on Q-<n>

---

## Risks / Considerations

**<Risk name>.** <What breaks, with arithmetic or a mechanism — how big, how often.>
*Mitigation:* <what you would do, or the explicit choice not to.>

**Could not verify:** <what, and the one test that would settle it.>

---

## Acceptance Criteria

| AC | Satisfied by | Proven by |
|---|---|---|
| AC-1 | Step <n> | `<test file>` — <case> |
| AC-2 | Step <n> | <manual, environment> — blocked on Q-<n> |

<Every AC from the spec appears.>

---

## Commit Message

```
<type>(<scope>): <imperative summary> [<TICKET-ID>]

<Why this change exists, wrapped at 72. The diff shows what; this says why.>

<The one non-obvious decision, and the reason it went that way.>

<What is deliberately not in this commit, with its question id.>

Refs: FR-<n>, BR-<n>..<n>, AC-<n>..<n>
```
