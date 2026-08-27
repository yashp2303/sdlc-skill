# TSC ticket skills — portable copy

Five Claude Code skills that take a ticket from description to shipped, tested code — plus one for
when something breaks in production.

```
/ticket-research   ticket description  →  research.md, 25 sections
       │                                  is this even plannable?
       ▼
/feature-docs      research.md         →  spec.md · plan.md · test-cases.md
       │                                  test-cases.csv · qa-sheet.md
       ▼
/tsc-ticket        implement + write ticket-local test files
       │
       ▼
/testing           execute → test-report.md · mark the CSV · tick the QA sheet
       │                     manual → unit → integration → Playwright → regression
       ▼
             CODE REVIEW → MERGE


/rca               a bug is reported → rca.md, 21 sections, READ-ONLY
                   finds the FIRST incorrect state. Recommends a fix, never applies one.
```

Everything lands in one folder per ticket: `docs/<TICKET-ID>-<slug>/`.

## What is in here

```
skills/
├── ticket-research/    the 25-section research report
├── feature-docs/       the five-file docs pack, exhaustive test derivation
├── tsc-ticket/         implement · verify · report, incl. ticket-local tests
├── testing/            execute all levels, incl. Playwright UI
└── rca/                read-only bug investigation → root cause
commands/
├── ticket-research.md · feature-docs.md · testing.md · rca.md
install.sh              all three registrations for all five skills
```

## Install

A skill needs **three** registrations, not one. A folder copy alone gives you a skill Claude can
find by description but that does **not** autocomplete when you type `/`.

```bash
./install.sh
```

It installs the skill folders, the slash commands, and the `CLAUDE.md` trigger blocks — backing up
anything it would overwrite. Or do it by hand:

```bash
cp -R skills/* ~/.claude/skills/
cp commands/*.md ~/.claude/commands/
# then append a trigger block per skill to ~/.claude/CLAUDE.md — see install.sh for the text
```

**Restart the Claude Code session afterwards.** Skills and commands are enumerated at startup, so
an already-open window keeps reporting "No matching commands" until it restarts.

## Dependency you need to know about

**`qa-cases` is not in this copy** and two skills call it:

- `feature-docs` → `scripts/to-xlsx.py` for the Excel view
- `testing` → `sheet_tool.py` (`list` / `mark` / `verify` / `sync`) to mark CSV rows

Derivation and execution still work without it; the xlsx view and mechanical row-marking do not.
Copy `~/.claude/skills/qa-cases/` across if you want them. `sheet_tool.py` itself lives at
`tsc-pos-backend/.ai/bin/lib/sheet_tool.py`, inside the repo.

## Paths that are machine-specific

Hardcoded to this laptop's layout — change them if you install elsewhere:

| File | What to change |
|---|---|
| `skills/tsc-ticket/templates/jest.config.cjs` | `REPO` |
| `skills/tsc-ticket/templates/run-tests.sh` | `REPO` — must match the config |
| `skills/testing/templates/playwright.config.ts` | `FLOWS` |
| `skills/testing/templates/run-ui-tests.sh` | `PW_HOME` |
| `skills/*/SKILL.md`, `commands/*.md` | default output dir `/Users/devx/TSC/docs/` |

`skills/testing/references/workspace-commands.md`, `ui-playwright.md` and
`skills/rca/references/investigation-matrix.md` are **specific to the TSC stack** — repo names,
log locations, the four investigation traps. Rewrite them for a different codebase.

## The design rules these skills enforce

Opinionated on purpose. Worth reading before using them:

- **Every claim about the code carries a `file:line`.** Anything uncitable becomes a numbered open
  question, never a confident sentence. A doc full of plausible statements is worse than none,
  because it gets believed and then estimated against.
- **Check every name in the ticket first.** If it names a status or field that does not exist,
  that mismatch is the headline finding and usually changes the ticket rather than the code.
- **Every open question gets a default**, chosen so being wrong changes one function rather than
  the design. Without one the estimate stalls.
- **Estimates branch.** "6h, +4h if OQ-1 resolves to replace, impossible if merge."
- **Never renumber an id.** `US FR BR VR DR SC AC EC OQ ASM API INT RISK TC` are cited across the
  spec, plan, commits and review comments.
- **Test coverage is exhaustive, not representative** — every guard in the code is a negative case,
  and negative rows should outnumber positive.
- **Never claim a test passed unless it was executed and the output observed.**
- **Baseline comparison is mandatory** — these repos carry pre-existing failures, so "53 errors" is
  noise and "54 at HEAD, 53 with my change" is evidence.
- **A `✅` with empty `Evidence` is not allowed.**

## Ticket-local tests

`tsc-ticket` writes test files into the ticket's docs folder rather than the repo test tree, so
they never reach git — but they still **run**:

```
docs/<TICKET>/tests/unit/*.spec.ts          jest project "unit"
docs/<TICKET>/tests/integration/*.int.spec.ts   jest project "integration"
docs/<TICKET>/tests/ui/                     Playwright
./run-tests.sh [unit|integration]  ·  ./run-ui-tests.sh
```

Jest has two independent roots: `rootDir` at the repo (for `node_modules`/`ts-jest`), `roots` at
the docs folder (for discovery). Verified: 10 tests across 2 projects, and `git status` in that
folder returns "not a git repository".

**Accept the trade-off knowingly: these tests are not in CI and no reviewer sees them in the PR.**
If a behaviour deserves permanent regression cover, that test belongs in the repo suite instead.

## `/rca` is read-only, by design

It produces an RCA and nothing else — no code changes, no commits, no pushes, no deploys, no
retries, no reprocessing, no data writes. It **recommends** a fix; a human decides whether to
implement it, through `/feature-docs` → `/tsc-ticket`.
# sdlc-skill
