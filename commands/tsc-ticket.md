Handle a TSC ticket end to end across the four-repo workspace.

Invoke the Skill tool with `skill: "tsc-ticket"` before doing anything else, passing `$ARGUMENTS`
through as the args. Follow that skill's instructions exactly — it owns the phases, the
workspace traps and the verification procedure.

Arguments: `<TICKET-ID> <what to do>` — or "implement the plan" if research and docs already exist.

Five phases, each ending somewhere safe to stop:

```
1 INVESTIGATE   grep every name the ticket uses; find every call site
2 DOCUMENT      spec · plan · test-cases · qa-sheet                    ── gate
3 IMPLEMENT     shared helper first, then each call site
4 VERIFY        tests · typecheck · lint · baseline comparison
5 REPORT        what shipped, what is blocked, what could not be verified
```

**Phase 2 is a gate** — no code until the spec and plan are agreed. If they already exist (from
`/ticket-research` + `/feature-docs`), start at phase 3 but *read* them first.

Source code goes in the repo as a normal branch. **Test files go in
`docs/<TICKET-ID>-<slug>/tests/`** — `unit/` and `integration/` jest projects, runnable via
`./run-tests.sh`, never pushed because `~/TSC` is not a git repo.

Phase 4 reports **three numbers**: repo suite before, repo suite after, ticket-local tests. These
repos carry pre-existing failures, so a bare count proves nothing.

For the full validation pass with a recorded report, hand to `/testing` instead of the phase-4
smoke check.
