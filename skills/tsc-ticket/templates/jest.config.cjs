/**
 * Ticket-local test runner config — unit + integration as separate projects.
 *
 * Runs `.spec.ts` files that live in this ticket's docs folder against the code
 * inside the repo. The tests stay outside every git repo, so they are never
 * staged, committed or pushed — but they still execute, so `test-cases.csv`
 * `Evidence` is real and the baseline comparison works.
 *
 * The whole trick is that jest has two separate roots:
 *   rootDir → the REPO   — resolves node_modules, ts-jest, tsconfig
 *   roots   → this folder — where jest looks for tests
 *
 *   tests/unit/*.spec.ts            fast, pure, no I/O
 *   tests/integration/*.int.spec.ts several units together, may need services
 *   tests/ui/                       Playwright — NOT jest, see run-ui-tests.sh
 *
 *   ./run-tests.sh                  both projects
 *   ./run-tests.sh unit
 *   ./run-tests.sh integration
 *
 * `testTimeout` is not a valid per-project option in this jest version — an
 * integration test that needs longer calls `jest.setTimeout(30_000)` at the top
 * of its own file instead.
 *
 * Change REPO for the repo this ticket touches:
 *   /Users/devx/TSC/tsc-pos-backend/pos-app        NestJS GraphQL API
 *   /Users/devx/TSC/order-management-service       NestJS REST (relative imports, drop modulePaths)
 *   /Users/devx/TSC/tsc-pos-frontend               no jest installed — UI only, via Playwright
 */
const REPO = '/Users/devx/TSC/tsc-pos-backend/pos-app';
const HERE = __dirname;

/** shared by both projects */
const base = {
  rootDir: REPO,
  moduleFileExtensions: ['js', 'json', 'ts'],
  transform: {
    '^.+\\.(t|j)s$': ['ts-jest', { tsconfig: REPO + '/tsconfig.json' }],
  },
  // lets a ticket-local test import 'src/orders/lib/…' exactly as a repo test does
  modulePaths: [REPO],
  testEnvironment: 'node',
};

module.exports = {
  projects: [
    {
      ...base,
      displayName: 'unit',
      roots: [HERE + '/tests/unit'],
      testRegex: '.*\\.spec\\.ts$',
    },
    {
      ...base,
      displayName: 'integration',
      roots: [HERE + '/tests/integration'],
      testRegex: '.*\\.int\\.spec\\.ts$',
      // uncomment if the ticket's integration tests need env/DI bootstrapping:
      // setupFilesAfterEnv: [HERE + '/tests/integration/setup.ts'],
    },
  ],
};
