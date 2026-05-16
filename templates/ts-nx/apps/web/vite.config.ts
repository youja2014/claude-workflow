import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  root: __dirname,
  cacheDir: '../../node_modules/.vite/web',
  server: { port: 5173, host: 'localhost' },
  preview: { port: 4173, host: 'localhost' },
  plugins: [react()],
  build: {
    outDir: '../../dist/apps/web',
    emptyOutDir: true,
    reportCompressedSize: true,
  },
});
