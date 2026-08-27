Execute and validate the tests for an approved implementation, then record the evidence.

Invoke the Skill tool with `skill: "testing"` before doing anything else, passing `$ARGUMENTS`
through as the args. Follow that skill's instructions exactly — it owns the strategy, the
traceability rules and the report format.

Arguments: `<TICKET-ID>` (optional — inferred from the ticket folder if only one is in flight)

Runs after implementation, before code review. **Evidence-based: never claim a test passed unless
it was executed and the output observed.**

Updates **three** files in `docs/<TICKET-ID>-<slug>/`:

```
test-report.md    NEW — summary · baseline comparison · requirement coverage ·
                  test cases · failures · flaky · blockers · risks · evidence ·
                  final status (PASS / FAIL / BLOCKED / PARTIAL)

test-cases.csv    every row gets a status + evidence, marked through
                  sheet_tool.py (it refuses a pass with no evidence).
                  `sheet_tool.py verify` must exit 0.

qa-sheet.md       checkpoints A–E ticked, Environment / Defects / Not covered
                  filled, Verdict set to match the report's Final Status
```

Before running anything, read `references/workspace-commands.md` — it has the real per-repo
commands, the ticket-local test runner, the **mandatory baseline procedure** (these repos carry
pre-existing failures, so a bare count proves nothing), and the repos where a whole test category
is impossible.

Does not change implementation. If the implementation is wrong it says so and hands back to
IMPLEMENT; if the spec is wrong, back to SPEC.
