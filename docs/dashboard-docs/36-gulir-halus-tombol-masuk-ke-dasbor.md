# Gulir halus saat menekan "Masuk ke dasbor"

**Waktu:** 2026-11-08 19:20

**Apa yang diubah**
Permintaan Wildan: tombol "Masuk ke dasbor" di bagian bawah halaman login sebelumnya membuat halaman melompat seketika ke atas. Sekarang halaman bergulir halus ke atas, lalu kursor masuk ke kolom username.

Sebelumnya tombol hanya memanggil `focus()` pada kolom username, dan browser langsung melompat ke kolom itu. Sekarang bagian atas halaman digulir dengan `scrollIntoView({ behavior: 'smooth' })`, dan fokus diberikan dengan `preventScroll` supaya tidak ada lompatan. Bila pengguna menyalakan "kurangi gerak" di sistem operasi, guliran tetap instan.

**File**
| File | Isi |
|---|---|
| `dashboard/src/pages/Login.jsx` | Fungsi `keFormulir` dipakai tombol "Masuk ke dasbor" |

**Cara cek**
Buka halaman login, gulir ke paling bawah, tekan "Masuk ke dasbor".
Sudah diukur di Chrome headless: posisi gulir turun bertahap dari 1112px ke 0 selama sekitar satu detik, dan fokus berakhir di kolom username. `npm run build` sukses.
