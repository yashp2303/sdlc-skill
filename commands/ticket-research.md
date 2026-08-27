Research a ticket against the actual code and write one `research.md` for it.

Invoke the Skill tool with `skill: "ticket-research"` before doing anything else, passing
`$ARGUMENTS` through as the args. Follow that skill's instructions exactly — it owns the method,
the format and the template.

Arguments: `<TICKET-ID> <title + full description, pasted>`

If no ticket id is present in `$ARGUMENTS`, ask for it and stop — the folder needs it. Paste the
whole description including the messy parts; the gaps in a ticket are findings.

Produces exactly one file, `docs/<TICKET-ID>-<slug>/research.md`, with **all 25 sections**:

```
 1  Ticket Summary                    14  Impact Analysis
 2  Business Understanding            15  Risks                    RISK-n
 3  Requirements                      16  Technical Blockers
      US · FR · BR · VR · DR ·        17  Business Blockers
      SC · AC · EC                    18  Environment Blockers
 4  Doubts / Ambiguities              19  Test Impact              TC-n
 5  Open Questions          OQ-n      20  Recommended Implementation
 6  Assumptions             ASM-n     21  Files Likely To Change
 7  Existing Code Analysis            22  Files That Should NOT Be Changed
 8  Similar Existing Implementations  23  Implementation Order
 9  Git History Findings              24  Research Evidence
10  API Analysis            API-n     25  Final Readiness
11  Database Analysis                       READY / NEEDS CLARIFICATION / BLOCKED
12  Integration Analysis    INT-n
13  Dependency Analysis
```

Every section appears every time. An empty one gets `None found.` — never delete a heading.
Never renumber an id: `AC-n` and `EC-n` carry into `spec.md` unchanged, `TC-n` becomes the
`test-cases.csv` rows.

Default location is `/Users/devx/TSC/docs/` unless the work is confined to one repo.

**Read-only.** This writes no code, no spec, no plan. It ends at a decision point — then
`/feature-docs <TICKET-ID>` turns it into the five-file pack.
