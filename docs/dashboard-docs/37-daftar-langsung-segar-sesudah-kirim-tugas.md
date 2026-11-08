# Daftar langsung segar sesudah "Kirim tugas"

**Waktu:** 2026-11-08

**Apa yang diubah**
Laporan: sesudah menekan "Kirim tugas", daftar baru berubah sekitar 10 detik kemudian.

Dasbor sebenarnya sudah memuat ulang data begitu POST /tasks berhasil. Masalahnya ada di polling 10 detik: kalau polling sedang berjalan saat tugas dikirim, jawabannya (masih data lama) bisa tiba sesudah muat ulang dan menimpa data baru. Data yang benar baru muncul di polling berikutnya.

Sekarang `usePolling` memberi nomor urut pada tiap permintaan dan hanya memakai hasil permintaan terbaru. Hasil yang datang terlambat diabaikan.

**File**
| File | Isi |
|---|---|
| `dashboard/src/hooks/usePolling.js` | Nomor urut permintaan di `muatUlang` |

**Cara cek**
Pakai backend asli (VITE_USE_MOCK=0), tugaskan saluran, lalu lihat tab Tugas dan Prioritas. Keduanya harus langsung berubah begitu dialog tertutup.
`npm run build` sukses.
