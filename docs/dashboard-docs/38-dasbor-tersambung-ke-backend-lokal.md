# Dasbor tersambung ke backend lewat .env akar

**Waktu:** 2026-11-08

**Apa yang diubah**
Sebelumnya `.env` di akar repo hanya berisi variabel backend, sedangkan Vite hanya membaca `.env` di folder `dashboard`. Akibatnya dasbor tetap memakai data contoh (VITE_USE_MOCK bernilai 1 secara bawaan).

Permintaan Wildan: cukup satu `.env` di akar untuk backend dan dasbor. Sekarang:
- `vite.config.js` memakai `envDir: '..'`, jadi Vite membaca `.env` akar.
- `.env` akar (lokal, tidak di-commit) diberi tiga baris dasbor: `VITE_API_URL=http://localhost:3000`, `VITE_USE_MOCK=0`, `VITE_KELURAHAN_ID=1`.
- `dashboard/.env` dihapus. `dashboard/.env.example` sekarang menjelaskan bahwa variabelnya ditaruh di `.env` akar.

Aman: Vite hanya mengirim variabel berawalan `VITE_` ke browser. DATABASE_URL, JWT_SECRET, dan AI_API_KEY tidak ikut ke dasbor.

**Perlu dikabarkan ke tim**
`.env.example` akar (milik bersama) baru berisi `VITE_API_URL` di bagian dashboard. Sebaiknya ditambah `VITE_USE_MOCK=0` dan `VITE_KELURAHAN_ID=1`, dan judul bagian `dashboard/.env` diganti karena sekarang semuanya di `.env` akar.

**File**
| File | Isi |
|---|---|
| `dashboard/vite.config.js` | `envDir: '..'` |
| `dashboard/.env.example` | Petunjuk baru: variabel ditaruh di `.env` akar |
| `.env` akar (lokal) | Tiga variabel VITE_ |

**Cara cek**
`loadEnv('development', '..', 'VITE_')` sudah mengembalikan ketiga variabel. Jalankan backend, restart `npm run dev`. Tulisan "Mode data contoh" di halaman login harus hilang, dan password salah ditolak.
