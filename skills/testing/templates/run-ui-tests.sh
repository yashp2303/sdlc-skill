#!/usr/bin/env bash
# Run the POS UI flows for this ticket. Modifies no repo.
#
#   ./run-ui-tests.sh                 all discoverable flows
#   ./run-ui-tests.sh save-quotation  filter by file
#   ./run-ui-tests.sh --headed        watch it
#   ./run-ui-tests.sh --ui            interactive runner
#
# @playwright/test resolves via NODE_PATH from a shared local install, because the
# specs live in tsc-pos-frontend which has no node_modules/@playwright.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PW_HOME="$HOME/TSC/.testing"

if [ ! -d "$PW_HOME/node_modules/@playwright/test" ]; then
  cat >&2 <<EOF
  @playwright/test is not installed. One-time setup:

      mkdir -p "$PW_HOME" && cd "$PW_HOME"
      npm init -y >/dev/null && npm install -D @playwright/test
      npx playwright install chromium    # usually already cached

EOF
  exit 1
fi

# These are integration tests — they need a running app.
BASE="${POS_BASE_URL:-http://localhost:5173}"
if ! curl -fsS -o /dev/null --max-time 3 "$BASE"; then
  echo "  $BASE is not responding." >&2
  echo "  Start the stack first:  cd ~/TSC && ./run.sh ustage:local" >&2
  echo "  This is an ENVIRONMENT_BLOCKER — mark those TC rows 🔲, not ❌." >&2
  exit 1
fi

echo "  app:    $BASE"
echo "  config: $HERE/playwright.config.ts"
echo

cd "$PW_HOME"
export NODE_PATH="$PW_HOME/node_modules"
export POS_BASE_URL="$BASE"
exec npx playwright test --config "$HERE/playwright.config.ts" "$@"
