# Skrip cek modul AI di server

**Waktu:** 2026-11-08 17:45

**Apa yang diubah**
Server tim melaporkan `POST /reports` dan verifikasi masih menghasilkan `ai_sumber: "demo"`, padahal `AI_API_KEY` dan `AI_MODEL` sudah ada di `.env` server. Ditambahkan skrip kecil untuk mencari penyebabnya langsung di server.

**File**
| File | Isi |
|---|---|
| `backend/src/ai/cek-ai.js` | Memuat `.env` (bila `dotenv` ada), menampilkan apakah `AI_API_KEY`, `AI_MODEL`, `DEMO_MODE` terbaca, lalu memanggil `analyzeReport` sekali dengan `DEMO_MODE` dimatikan. Hasil akhirnya "BERHASIL" atau "GAGAL" beserta alasannya |

**Cara pakai (di folder backend server)**
```
git pull origin feat/dashboard
npm i @anthropic-ai/sdk
node src/ai/cek-ai.js ../dashboard/public/contoh-saluran/berat.jpg
```

**Membaca hasil**
| Hasil | Penyebab | Perbaikan |
|---|---|---|
| `Cannot find module '@anthropic-ai/sdk'` | SDK belum terpasang | `npm i @anthropic-ai/sdk` |
| `AI_API_KEY terbaca: TIDAK` | `.env` tidak dimuat proses | Panggil `require('dotenv').config()` paling awal di file utama server, atau teruskan env lewat Docker/PM2 |
| `GAGAL: API 401` | Kunci salah atau tidak aktif | Periksa kunci di console Anthropic |
| `GAGAL: API 404` | Nama model salah | Kosongkan `AI_MODEL` atau isi `claude-opus-5-5` |
| `GAGAL: API 400` | Format permintaan ditolak | Pastikan versi SDK terbaru (`npm i @anthropic-ai/sdk@latest`) |
| `BERHASIL` tapi server tetap "demo" | Server masih menjalankan modul lama (stub) | Pastikan server memakai `src/ai/index.js` versi `e904c48`, lalu restart server |
