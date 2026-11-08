# Logo RIVORA (daun dan mata)

**Waktu:** 2026-11-08 09:55 sampai 10:00

**Apa yang diubah**
Membuat logo baru di folder `public/brand/`. Belum dipasang ke kepala dasbor maupun favicon (`public/favicon.svg` masih bawaan Vite).

**File baru**
| File | Isi |
|---|---|
| `public/brand/rivora-logo.svg`, `rivora-logo-putih.svg` | Logo lengkap (simbol + tulisan) untuk latar terang dan gelap |
| `public/brand/rivora-mark.svg`, `rivora-mark-putih.svg`, `rivora-mark-mono.svg` | Simbol saja: berwarna, putih, satu warna |
| `public/brand/rivora-ikon-app.svg` | Ikon persegi membulat untuk favicon dan aplikasi |
| `public/brand/*-1024.png`, `*-2100.png` | Ekspor PNG transparan untuk PPT, Canva, ikon launcher Flutter |
| `public/brand/logo-rivora.html` | Lembar merek: filosofi, warna, aturan pakai, penjelasan empat referensi |

**Konsep**
Daun yang sekaligus berbentuk mata. Tetes hujan di dalam iris = hujan yang terlihat di prakiraan sebelum turun; garis aliran di bawahnya = saluran drainase yang lancar sekaligus tulang daun. Mewakili slogan "See The Flood Before You See The Water", AI vision, dan subtema Sustainable Development.

Warna: Hijau Saluran `#0d5e53` (= `--teal-gelap`), Biru Hujan `#2fb3c6` / `#4cc9d9` (latar gelap), Navy `#17324d` (= `--navy`). Merah, kuning, dan hijau terang tidak dipakai karena itu warna level risiko RW. Tulisan RIVORA digambar sebagai garis SVG, tidak bergantung font.

**Alasan**
Dasbor dan aplikasi belum punya identitas visual; favicon masih logo Vite.

**Cara cek**
- Buka `public/brand/logo-rivora.html` di peramban, atau saat `npm run dev` buka http://localhost:5173/brand/logo-rivora.html
- Sudah dicek dengan tangkapan layar Chrome headless di 16, 24, 48 px dan di latar navy: simbol tetap terbaca.

**Belum dikerjakan**
- Memasang simbol putih di `.logo` kepala dasbor (`src/App.jsx`) dan mengganti `public/favicon.svg`.
- Ikon launcher aplikasi Flutter (bagian Bli) bisa memakai `rivora-ikon-app-1024.png`.
