Write the five-file docs pack for a feature requirement, in the house format.

Invoke the Skill tool with `skill: "feature-docs"` before doing anything else, passing
`$ARGUMENTS` through as the args. Follow that skill's instructions exactly — it owns the
formats, the section lists, and the templates.

Arguments: `<TICKET-ID> <the feature requirement, pasted or described>`

If no ticket id is present in `$ARGUMENTS`, ask for it and stop — the folder name and the
commit message both need it. Everything else can be derived or defaulted.

Produces, in `docs/<TICKET-ID>-<slug>/`:

```
spec.md          1. Document Information · 2. Executive Summary · 3. Business Problem
                 4. Business Goal · 5. Scope · 6. Actors / Users · 7-15
plan.md          Objective · Requirements · Current State · Proposed Approach
                 Implementation Steps · Files to Change · Testing Plan
                 Risks / Considerations · Acceptance Criteria · Commit Message
test-cases.md    every scenario grouped, with its test function name
test-cases.csv   ID · Section · Scenario · Type · Level · Expected · Status · Evidence · Notes
qa-sheet.md      checkpoints A-E · Environment · Defects · Not covered · Sign-off
```

Default location is `/Users/devx/TSC/docs/` unless the work is confined to one repo.

Do not implement anything. This command writes the pack and stops.
