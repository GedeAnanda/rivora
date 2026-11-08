# Inisialisasi proyek Vite + React

**Waktu:** 2026-11-08 09:30

**Apa yang diubah**
1. Menghapus `dashboard/.gitkeep` (sesuai `docs/SETUP_JAM0.md` bagian 4: hapus `.gitkeep` di folder yang sudah terisi).
2. Menjalankan `npm create vite@latest . -- --template react --no-interactive` (create-vite 9.3.4).

**File baru**
- `package.json`, `package-lock.json`, `vite.config.js`, `index.html`
- `.gitignore`, `.oxlintrc.json` (linter oxlint bawaan template), `README.md` (bawaan template)
- `public/favicon.svg`, `public/icons.svg`
- `src/main.jsx`, `src/App.jsx`, `src/App.css`, `src/index.css`, `src/assets/*`

Versi yang terpasang: React 19.3, Vite 8.3, @vitejs/plugin-react 6.1.

**Alasan**
Stack dasbor sudah ditetapkan di README dan `docs/RENCANA_FINAL.md` bagian 3: React + Leaflet + OpenStreetMap, dengan Vite.

**Cara cek**
```bash
cd dashboard
npm install
npm run dev
```
Buka alamat yang muncul (biasanya http://localhost:5173).
