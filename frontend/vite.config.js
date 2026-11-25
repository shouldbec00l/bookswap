import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    // лише для локальної розробки без Docker; у контейнері /api проксує nginx
    proxy: { '/api': process.env.DEV_API_URL || 'http://localhost:3000' },
  },
});
