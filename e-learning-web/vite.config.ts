import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import fs from 'fs'
import path from 'path'

// https://vite.dev/config/
const certDir = path.resolve(__dirname, 'certs')

export default defineConfig({
  plugins: [react()],
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
