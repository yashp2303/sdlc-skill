#!/usr/bin/env bash
# Install the ticket skills into ~/.claude — all three registrations each.
# Backs up anything it would overwrite. Idempotent.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE="$HOME/.claude"
STAMP="$(date +%Y%m%d-%H%M%S)"

SKILLS=(ticket-research feature-docs tsc-ticket testing rca)

mkdir -p "$CLAUDE/skills" "$CLAUDE/commands"

echo "1/3  skill folders"
for s in "${SKILLS[@]}"; do
  if [ -d "$CLAUDE/skills/$s" ]; then
    mv "$CLAUDE/skills/$s" "$CLAUDE/skills/$s.bak-$STAMP"
    echo "       backed up existing $s → $s.bak-$STAMP"
  fi
  cp -R "$HERE/skills/$s" "$CLAUDE/skills/"
  echo "       installed $s"
done

echo "2/3  slash commands"
for c in "$HERE"/commands/*.md; do
  n="$(basename "$c")"
  [ -f "$CLAUDE/commands/$n" ] && cp "$CLAUDE/commands/$n" "$CLAUDE/commands/$n.bak-$STAMP"
  cp "$c" "$CLAUDE/commands/"
  echo "       installed $n"
done

echo "3/3  CLAUDE.md trigger blocks"
CM="$CLAUDE/CLAUDE.md"
touch "$CM"
add_block() {
  local name="$1" desc="$2"
  if grep -q "^# $name\$" "$CM"; then
    echo "       $name already registered — left alone"
    return
  fi
  cp "$CM" "$CM.bak-$STAMP" 2>/dev/null || true
  {
    printf '\n# %s\n' "$name"
    printf -- '- **%s** (`~/.claude/skills/%s/SKILL.md`) - %s Trigger: `/%s`\n' "$name" "$name" "$desc" "$name"
    printf 'When the user types `/%s`, invoke the Skill tool with `skill: "%s"` before doing anything else.\n' "$name" "$name"
  } >> "$CM"
  echo "       appended $name"
}

add_block ticket-research "ticket title + description to one \`research.md\` per ticket: 25 sections, verified facts with file:line, every name checked for existence, open questions with defaults, blockers. Read-only; runs before \`/feature-docs\`."
add_block feature-docs    "feature requirement to the five-file docs pack (spec.md · plan.md · test-cases.md · test-cases.csv · qa-sheet.md) under \`docs/<TICKET-ID>-<slug>/\`, with exhaustive test coverage."
add_block tsc-ticket      "a ticket end to end across the four-repo workspace — investigate with file:line evidence, document, implement, write ticket-local test files, verify, report."
add_block testing         "execute and validate tests for an approved implementation: manual · unit · integration · Playwright UI/E2E · regression. Writes \`test-report.md\`, marks every \`test-cases.csv\` row with evidence, ticks the \`qa-sheet.md\` checkpoints. Evidence-based; baseline comparison mandatory."
add_block rca             "investigate a reported bug across every system in the affected flow and produce \`rca.md\`: 21 sections, identifier correlation, end-to-end timeline, the first incorrect state, root cause, recommended fix. **Strictly read-only** — no writes, commits, pushes, deploys, retries or reprocessing."

echo
echo "  done — ${#SKILLS[@]} skills installed."
echo
if [ ! -d "$CLAUDE/skills/qa-cases" ]; then
  echo "  ⚠  qa-cases is NOT installed. feature-docs calls it for the xlsx view and"
  echo "     testing calls sheet_tool.py. Derivation still works; those two steps will not."
  echo
fi
echo "  ⚠  RESTART your Claude Code session — skills and commands are read at startup,"
echo "     so an open window will keep saying 'No matching commands'."
