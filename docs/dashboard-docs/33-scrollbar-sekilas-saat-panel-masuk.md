# Scrollbar sekilas saat panel detail masuk dihilangkan

**Waktu:** 2026-11-08 18:30

**Apa yang diubah**
Laporan Wildan: setiap kali wilayah RW diklik, scrollbar jendela muncul sebentar di bawah dan di kanan lalu hilang. Ini mengganggu mata.

Penyebabnya adalah animasi panel detail yang meluncur dari kanan (`translateX(24px)`). Selama animasi, panel melewati tepi jendela sejauh 24px, sehingga browser memunculkan scrollbar bawah. Scrollbar itu memakan tinggi jendela, lalu scrollbar kanan ikut muncul. Sejak entri 32, animasi terulang di setiap pilihan baru, jadi kejadiannya lebih sering.

Perbaikannya: panel samping dan wadah aplikasi memotong isi yang keluar batas (`overflow: hidden`). Gerakan panel tetap ada, hanya tidak lagi menembus tepi jendela.

**File**
| File | Isi |
|---|---|
| `dashboard/src/index.css` | `overflow: hidden` pada `.sisi` dan `.aplikasi` |

**Cara cek**
Tekan Ctrl+Shift+R, lalu klik beberapa wilayah RW dan titik bergantian. Tidak boleh ada scrollbar jendela yang muncul.
Sudah diukur di Chrome headless (1903×937) per frame selama 0,7 detik setelah tiap aksi. Sebelum perbaikan, halaman melebar 24px saat RW diklik. Sesudah perbaikan, lebar dan tinggi halaman tidak bertambah sama sekali saat klik RW, klik RW lain, klik titik, kembali ke daftar, dan ganti tab. `npm run build` sukses.

**Catatan**
Dialog, toast, dan foto diperbesar memakai `position: fixed`, jadi tidak ikut terpotong.
