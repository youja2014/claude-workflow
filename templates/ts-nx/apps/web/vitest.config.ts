import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: ['./src/test/setup.ts'],
      css: true,
      include: ['src/**/*.{spec,test}.{ts,tsx}'],
      exclude: ['node_modules/**', 'dist/**', 'test/e2e/**'],
      reporters: ['default'],
      coverage: { provider: 'v8', reportsDirectory: '../../coverage/apps/web' },
    },
  }),
);
