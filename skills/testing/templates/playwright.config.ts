/**
 * Ticket-local Playwright config.
 *
 * Runs the POS UI flows without modifying any repo. @playwright/test resolves via
 * NODE_PATH, set by run-ui-tests.sh — see references/ui-playwright.md.
 *
 * Verified: 12 tests discovered in 12 files.
 */
import { defineConfig, devices } from '@playwright/test';

// The existing suite in the frontend repo. Point at the ticket's own tests/ui
// instead if you are writing new flows for this ticket.
const FLOWS = '/Users/devx/TSC/tsc-pos-frontend/playwright/flows';

export default defineConfig({
  testDir: FLOWS,
  testMatch: '**/*.spec.ts',

  // whole-sanity-checkout.spec.ts imports with an explicit `.ts` extension, which
  // Playwright's loader rejects. Remove this line once those four imports are fixed —
  // it is the whole-journey test and the biggest gap while excluded.
  testIgnore: '**/whole-sanity-checkout.spec.ts',

  fullyParallel: false, // these flows share a logged-in session and a cart
  retries: 0,           // do not paper over flakiness; investigate it (see SKILL.md)
  workers: 1,
  reporter: [['list'], ['html', { open: 'never' }]],

  use: {
    baseURL: process.env.POS_BASE_URL ?? 'http://localhost:5173',
    // evidence for the test report — keep these on
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
  },

  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
