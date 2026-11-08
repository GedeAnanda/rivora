# Dasbor utama dengan gaya baru

**Waktu:** 2026-11-08 14:15

**Apa yang diubah**
Tampilan dasbor utama diperbarui atas permintaan Wildan, memakai skill `frontend-design` dan `ui-ux-pro-max` seperti halaman login (entri 16). Yang berubah hanya gaya. Tata letak SRS dasbor bagian 5 (peta, panel kanan bertab, panel detail di bawah daftar, kaki batas klaim) dan warna level serta kelas SRS bagian 8 tetap.

**Rencana desain**
- Satu bahasa visual dengan login: Plus Jakarta Sans, kepala berwarna air gelap `#0b2b28` dengan teks putih, teal `#127a6c` untuk aksi.
- Kanvas diganti dari krem hangat `#f6f5f4` (entri 09) ke abu kehijauan dingin `#f3f6f5`. Krem hangat termasuk ciri desain generik menurut `frontend-design`, dan nuansa dingin lebih dekat ke tema air.
- Peta tetap elemen utama. Panel kanan dibuat tenang dan lebih lega.
- Gerak hanya sebagai respons tindakan: panel detail naik saat dibuka, latar tab bergeser saat diganti, tombol sedikit mengecil saat ditekan. Mati untuk `prefers-reduced-motion`.

**File**
| File | Isi |
|---|---|
| `dashboard/src/index.css` | Token: `--air`, `--latar`, teks lebih hijau-gelap, radius 14px, huruf dasar 14,5px Plus Jakarta Sans. Kepala air gelap; angka hujan 22px tebal. Tab jadi kontrol bersegmen (latar `#e3e9e8`, tab aktif putih). Kartu daftar padding 14px, sudut 14px, nomor peringkat warna air. Tombol sudut 10px, tebal 700; tombol kecil tinggi minimal 36px. Panel detail bersudut atas 18px dengan bayangan dan animasi naik 0,28 detik. Meter skor warna air. Dialog sudut 18px |
| `dashboard/src/pages/Dashboard.jsx` | Tombol keluar sekarang berlabel "Keluar" dengan ikon (sebelumnya hanya ikon dan sulit ditemukan) |

**Aturan ui-ux-pro-max yang diterapkan**
- Tombol hanya-ikon tanpa label diganti tombol berlabel (Keluar).
- Target klik lebih besar: tab 40px, tombol keluar 40px, tombol Tugaskan minimal 36px.
- Umpan balik saat ditekan dan transisi 150 sampai 280 ms, bukan perubahan instan.
- Gerak dihormati: semua animasi mati untuk `prefers-reduced-motion: reduce`.

**Cara cek**
Masuk dengan `lurah` di http://localhost:5173, tekan Ctrl+Shift+R.
Sudah dicek lewat tangkapan layar Chrome headless 1440x900: dasbor awal dan detail saluran terbuka. `npm run build` sukses.

**Belum dikerjakan**
- Tab Tugas, tab Cek, dialog Tugaskan, dan banner simulasi belum difoto ulang dengan gaya baru.
- Entri 09 (gaya referensi Notion) kini sebagian besar tergantikan entri ini.
