# Foto latar halaman login

**Waktu:** 2026-11-08 13:10

**Apa yang diubah**
Latar hero halaman login diganti dari peta risiko RW (entri 12) menjadi foto, sesuai permintaan Wildan: tata letak tetap seperti contoh, cukup latarnya yang diganti foto.

**File**
| File | Isi |
|---|---|
| `dashboard/public/login/hero.jpg` | Foto baru, 1920x1280, 947 KB |
| `dashboard/src/pages/Login.jsx` | Komponen `PetaLatar` dan impor Leaflet di halaman login dihapus. Ditambah tautan kredit foto di pojok kanan bawah hero |
| `dashboard/src/index.css` | `.hero` memakai `url('/login/hero.jpg')` dengan `cover`, warna teal sebagai cadangan. Aturan `.hero-peta` dihapus, ditambah `.hero-kredit` |

**Sumber foto**
- Judul: Gotong Royong Membersihkan Sungai. Relawan dan petugas kebersihan membersihkan Sungai Cikapundung, Kota Bandung (31 Desember 2021).
- Pembuat: Galeri ega.
- Lisensi: CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0).
- Halaman: https://commons.wikimedia.org/wiki/File:Gotong_Royong_Membersihkan_Sungai.jpg
- Lisensi ini mewajibkan kredit, jadi namanya ditampilkan di hero dan tautannya menuju halaman foto. Kredit jangan dihapus.

**Alasan memilih foto ini**
Cerah dan hijau seperti foto referensi. Isinya pas dengan RIVORA: pembersihan sungai di Bandung, dengan papan "Aku, kamu, dan sungai saling menjaga". Kandidat lain (Jalan Braga, banjir di Bandung, Gunung Malabar dari Telkom University) ditolak karena tidak relevan, buram, atau berposisi tegak.

**Cara cek**
Keluar dari dasbor, lalu buka http://localhost:5173. Bila masih tampilan lama, tekan Ctrl+Shift+R.
Sudah dicek lewat tangkapan layar Chrome headless 1440 px: foto tampil di belakang kartu formulir, kredit terbaca di pojok kanan bawah. `npm run build` sukses.

**Belum dikerjakan**
- Tiga kartu fitur di bawah hero masih ikon, belum foto.
- Ukuran foto belum dikompres (947 KB). Cukup untuk demo di jaringan biasa.
