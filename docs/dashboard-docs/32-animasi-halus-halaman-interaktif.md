# Animasi halus di halaman interaktif

**Waktu:** 2026-11-08 18:10

**Apa yang diubah**
Permintaan Wildan: tambahkan animasi ke semua bagian interaktif, tidak berlebihan, hanya supaya nyaman di mata.

Prinsipnya: gerak hanya muncul sebagai jawaban atas tindakan pengguna (membuka, mengganti, memilih, konfirmasi), durasinya 150 sampai 300 ms, dan tidak ada gerak berulang atau dekoratif. Halaman login sudah punya urutan masuk sejak entri sebelumnya, jadi tidak ditambah.

| Bagian | Gerak |
|---|---|
| Ganti tab (Perlu dibersihkan, Tugas petugas, Cek langsung) dan kembali dari detail | Daftar muncul pelan dari bawah 8px |
| Panel detail | Meluncur dari kanan (sudah ada), sekarang juga terulang saat berpindah RW atau saluran lain |
| Bilah Hujan, Sumbatan, Kerentanan | Tumbuh dari kiri saat panel RW dibuka |
| Dialog "Tugaskan petugas" dan foto diperbesar | Latar memudar masuk, kotak membesar sedikit dari 97% |
| Toast | Naik pelan dari bawah, terulang tiap pesan baru |
| Panel "Simulasi hujan" dan isi legenda | Turun pelan saat dibuka |
| Pesan galat (login dan detail) | Turun pelan saat muncul |
| Kartu daftar | Bayangan tipis saat kursor di atasnya |
| Baris saluran, pilihan petugas, tombol kembali | Warna latar berganti pelan |
| Peta: titik dipilih | Satu riak melebar lalu hilang (0,6 detik, sekali) |
| Peta: warna wilayah dan garis | Berganti pelan saat data berubah atau RW dipilih. Bentuk wilayah sengaja tidak dianimasikan supaya zoom tetap tajam |

Semua gerak mati bila pengguna menyalakan "kurangi gerak" (`prefers-reduced-motion`) di sistem operasi.

**File**
| File | Isi |
|---|---|
| `dashboard/src/index.css` | Blok baru "Gerak halus (entri 32)" di akhir file, beserta versi `prefers-reduced-motion` |
| `dashboard/src/pages/Dashboard.jsx` | `key={tab}` pada daftar dan `key` pilihan pada panel detail supaya animasi masuk terulang |
| `dashboard/src/components/Toast.jsx` | `key={pesan.teks}` supaya tiap pesan baru beranimasi |
| `dashboard/src/components/RiskMap.jsx` | Lingkaran `riak-pilih` yang dipasang hanya saat titik dipilih |

**Cara cek**
Tekan Ctrl+Shift+R. Klik titik di peta (riak), kembali ke daftar, ganti tab, buka "Tugaskan petugas", buka "Simulasi hujan".
Sudah dicek di Chrome headless: animasi `riak`, `detail-naik`, `masuk-naik`, `masuk-skala`, `masuk-pudar` terpasang pada elemen yang benar, riak hilang setelah pilihan dilepas, dialog tampil normal. `npm run build` sukses.
