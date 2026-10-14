import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import fs from 'fs'
import path from 'path'

// https://vite.dev/config/
const certDir = path.resolve(__dirname, 'certs')

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-redux': ['@reduxjs/toolkit', 'react-redux'],
          'vendor-signalr': ['@microsoft/signalr'],
          'vendor-i18n': ['i18next', 'react-i18next'],
        },
      },
    },
    chunkSizeWarningLimit: 600,
  },
  server: {
    https: {
      key: fs.readFileSync(path.join(certDir, 'localhost+2-key.pem')),
      cert: fs.readFileSync(path.join(certDir, 'localhost+2.pem')),
    },
    port: 5173,
    host: true,
    hmr: {
      protocol: 'wss',
      host: 'localhost',
      port: 5173,
    },
  },
  css: {
    postcss: './postcss.config.js',
  },
})
