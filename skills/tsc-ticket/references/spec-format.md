# spec.md — section rules

Worked example: `/Users/devx/TSC/docs/TWP-5704-premium-order-tagging/spec.md`.

## Header

```markdown
# <Feature name> — <scope>

| | |
|---|---|
| **Ticket** | [TICKET-ID](https://tscjira.atlassian.net/browse/TICKET-ID) — <ticket title verbatim> |
| **Status** | Spec — not started \| In progress \| Blocked on Qn |
| **Date** | YYYY-MM-DD |
| **Author** | drafted from the ticket + code verification against `<env>` |

---
```

Name the environment the facts were checked against. A fact verified against `dev` and a
fact verified against `prod` are different kinds of fact.

## §1 What changes, at a glance

A Before/After table. A reader who stops here should not be wrong about anything.

```markdown
| | Before | After |
|---|---|---|
| **<the field or behaviour>** | `<what it is now>` | `<what it becomes>` |
| **<the rule>** | — | **<the new constraint>** |
```

An ASCII diagram earns its place only when it removes an ambiguity — a boundary
condition, a two-path split. TWP-5704 uses one to make "exactly ₹2,00,000 is NOT premium"
impossible to misread. Do not draw the architecture.

## §2 Why

The decision this enables, in two or three sentences. Not "the ticket asks for it".

The test: could someone reading only §2 argue for a different solution to the same
problem? If not, you have described the solution again, not the problem.

## §3 Verified facts — the section that matters

Open with the check date and a count:

> Checked against `prod` on YYYY-MM-DD. **Three of these change the shape of the work**
> and should be read before estimating.

Then numbered sub-sections, `### 3.1`, `### 3.2`, … Each one:

- **A heading that states the finding**, not the topic. "There is exactly one place tags
  are sent today" — not "Tag sending".
- **file:line, with the line quoted.** Line numbers move; a quoted fragment survives.
- **What the reader should do differently** because of it.

```markdown
### 3.1 There is exactly one place tags are sent today

`orders/lib/create-oms-order.ts:644`:

```js
tags: 'pos_order',
```

A hardcoded **string**, not an array. Whatever OMS does with commas, semicolons or
repeated keys is unverified from this side — see §7 Q1.
```

Facts worth hunting for specifically, because they change estimates:

- **Write sites vs read sites.** "One writer and zero readers" tells you the field is
  provenance for something downstream, and that nothing local will break.
- **The same quantity computed two ways.** If two paths derive one value differently,
  that is the trap. State both formulas side by side and spell out the divergence
  concretely — "a ₹2,10,000 cart with ₹20,000 of discounts would be premium at creation
  and non-premium after any edit".
- **A field that looks relevant and is separate.** `total_shipping_fee` sitting outside
  `total_price` decides a boundary case nobody has ruled on.
- **An existing implementation of the same shape.** If the codebase already updates this
  kind of field somewhere, its semantics are precedent. Say whether it merges or replaces,
  and say plainly that precedent is not proof.
- **What the ticket's own wording reveals.** "must be explicitly cleared; simply not
  sending the field should not leave the old value" means the author already suspected the
  answer. Quote it and name the suspicion.

Order by estimate impact, not by code order.

## §4 Requirement

Numbered, behavioural, no technology.

```markdown
1. **New order** — at send time, if <condition>, include <behaviour>; otherwise do not.
2. **Threshold is strict** — exactly <boundary> is **not** <state>.
```

## §5 Acceptance criteria

Tables, grouped by concern, each row mechanically checkable.

```markdown
| # | Given | When | Then |
|---|---|---|---|
| **AC-1** | <state> | <action> | <observable outcome> |
```

Group by concern — the decision, the transitions, coverage. Where an AC is satisfied by
existing behaviour, say so in the row: "satisfied for free: `is_hold_order` is a flag on
the *same* payload". That is one fewer task in the plan.

Always include an AC that says "everything else behaves exactly as before, apart from
this". It is the one people forget to test.

## §6 Edge cases

```markdown
| Case | Expected | Risk |
|---|---|---|
| <input at the boundary> | <outcome> | low — `>` not `>=`, one unit test |
| <the one nobody decided> | **undecided** | §7 Qn |
```

The Risk column carries the value. "low — one unit test" and "the create path cannot do
this today" are both useful; "medium" is not. Rows with no correct answer yet point at
§7 rather than inventing one.

## §7 Open questions

```markdown
| # | Question | Why it matters | Default if unanswered |
|---|---|---|---|
| **Q1** | <question> | <what breaks either way> | <default that unblocks the work> |
```

**Every question needs a default**, or the work stops waiting for an answer. The default
should be chosen so that being wrong changes one function, not the design.

Mark questions the investigation already settled as struck through, with the answer —
`~~Separator format~~ **Decided: comma-separated**, matching <file:line> house style`.
This shows the reader the question was considered, not overlooked.

## §8 Scope boundaries

In scope in one line. Then **not** in scope as a list, each with a reason. This section
prevents the expensive kind of rework — the kind found after shipping.

Include work that belongs to another team. "Any OMS-side change — if Q1 says merge, that
work belongs to the OMS team" sets the boundary before the argument happens.

## §9 Design note

Only when there is exactly one shape decision worth pre-empting — typically "this must be
one shared function, because two implementations of the same rule will drift".

Close it by naming the real difficulty: "The difficulty is not this function. It is that
its input does not exist in the create path today, and that its output may not be
actionable on removal."
