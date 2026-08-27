#!/usr/bin/env bash
# Run this ticket's tests. They live here in the docs folder, never in a git repo,
# so they are never pushed — but they do execute against the real code.
#
#   ./run-tests.sh                              unit + integration
#   ./run-tests.sh unit                         unit only
#   ./run-tests.sh integration                  integration only
#   ./run-tests.sh --coverage                   any jest flag passes through
#   ./run-tests.sh unit -t 'threshold'          project + jest flags
#
# UI/E2E is Playwright, not jest — use ./run-ui-tests.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Must match REPO in jest.config.cjs — jest resolves node_modules from the repo,
# so npx has to run there too.
REPO="/Users/devx/TSC/tsc-pos-backend/pos-app"

if [ ! -d "$HERE/tests" ]; then
  echo "  no tests/ directory in $HERE" >&2
  echo "  expected:  tests/unit/*.spec.ts   tests/integration/*.int.spec.ts" >&2
  exit 1
fi

# first arg may be a project name; anything else passes straight to jest
PROJECT=""
case "${1:-}" in
  unit|integration) PROJECT="--selectProjects $1"; shift ;;
esac

u=$(find "$HERE/tests/unit"        -name '*.spec.ts'     2>/dev/null | wc -l | tr -d ' ')
i=$(find "$HERE/tests/integration" -name '*.int.spec.ts' 2>/dev/null | wc -l | tr -d ' ')
echo "  tests: $HERE/tests   (unit: $u · integration: $i)"
echo "  code:  $REPO"
[ -n "$PROJECT" ] && echo "  only:  ${PROJECT#--selectProjects }"
echo

cd "$REPO"
# shellcheck disable=SC2086
exec npx jest --config "$HERE/jest.config.cjs" $PROJECT "$@"
