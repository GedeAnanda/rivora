# Huruf diganti Public Sans

**Waktu:** 2026-11-08 15:45

**Apa yang diubah**
Permintaan Wildan: huruf diganti supaya tampil lebih profesional. Atkinson Hyperlegible (dari brand kit, entri 21) diganti **Public Sans** untuk halaman login dan dasbor.

**Alasan memilih Public Sans**
- Dibuat untuk sistem desain pemerintah AS (USWDS) khusus antarmuka layanan publik: netral, formal, mudah dibaca. Sesuai dengan dasbor pemerintah kelurahan.
- Angka tidak bergaris miring seperti angka nol di Atkinson Hyperlegible, sehingga skor seperti "0,78" tampak rapi.
- Mendukung angka rata lebar (`tnum`), jadi skor dan jam tersusun lurus dalam daftar.
- Lisensi OFL, tersedia di Google Fonts.

**File**
| File | Isi |
|---|---|
| `dashboard/index.html` | Google Fonts: `Public+Sans:wght@400;500;600;700;800` |
| `dashboard/src/index.css` | `font-family: 'Public Sans', ...`, `font-feature-settings: 'tnum' 1, 'lnum' 1`, komentar kepala file diperbarui |

**Catatan untuk tim**
Brand kit menetapkan Atkinson Hyperlegible untuk aplikasi mobile, dasbor, dan slide. Dasbor sekarang berbeda dari kit. Perlu disepakati dengan tim: tetap begini (dasbor formal, mobile ramah), atau mobile dan slide ikut Public Sans, atau dasbor kembali ke Atkinson.

**Cara cek**
`npm run dev`, tekan Ctrl+Shift+R. Sudah dicek lewat tangkapan layar 1440x900: login dan daftar prioritas. `npm run build` sukses. Tanpa internet, huruf kembali ke huruf sistem (Segoe UI di Windows).
