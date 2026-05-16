import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './test/e2e',
  timeout: 30_000,
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
  },
  webServer: {
    command: 'yarn nx serve web',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
    cwd: '../..',
  },
});
