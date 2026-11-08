import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // .env dibaca dari akar repo (satu file untuk backend dan dasbor). Hanya variabel VITE_ yang sampai ke browser.
  envDir: '..',
})
